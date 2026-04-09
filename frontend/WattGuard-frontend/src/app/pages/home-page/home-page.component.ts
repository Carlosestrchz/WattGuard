import { Component, DestroyRef, inject, OnInit } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { NgApexchartsModule } from "ng-apexcharts";
import { Datagrafic, Nodo, newNodo } from '../../shared/interfaces/data';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { interval, switchMap } from 'rxjs';

import {
  ApexAxisChartSeries,
  ApexChart,
  ApexXAxis,
  ApexDataLabels,
  ApexTitleSubtitle,
  ApexStroke,
  ApexGrid,
  ApexTooltip
} from "ng-apexcharts";
import { DataGraphicServiceService } from '../../shared/services/data-graphic-service.service';
import { KeyValuePipe } from '@angular/common';

export type ChartOptions = {
  series: ApexAxisChartSeries;
  chart: ApexChart;
  xaxis: ApexXAxis;
  dataLabels: ApexDataLabels;
  grid: ApexGrid;
  stroke: ApexStroke;
  title: ApexTitleSubtitle;
  tooltip: ApexTooltip;
};

@Component({
  selector: 'app-home-page',
  imports: [NgApexchartsModule, KeyValuePipe, ReactiveFormsModule],
  templateUrl: './home-page.component.html',
  styleUrl: './home-page.component.css'
})
export class HomePageComponent implements OnInit{
  public chartOptions: Partial<ChartOptions>;//graficos
  
  private dataGrafic=inject(DataGraphicServiceService);//puente para las peticiones (lista de nodos, poblacion y ultimos registros)  
  private destroyRef = inject(DestroyRef);
  
  private listnode:Nodo[]=[]; //lista de los nodos que ya estan en la base de datos
  
  private dataPorNodo: { [key: number]: Datagrafic[] } = {};//tabla dinamica tipo lista indexada por nodo id, para almacenar los daros de cada nodo, con el nodo id como indice
  public last_data_por_nodo: { [key: number]: Datagrafic } = {};//ultimo registro de cada nodo
  private pollingStarted = false;

  public newNodo: newNodo = {nombre: '',tipo: '',mac_address: ''}

  private fb = inject(FormBuilder);
  myForm: FormGroup;
  showForm: boolean = false;

  //traer la informacion de la base de datos atraves de la API
    
  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.dataGrafic.getListaNodos().subscribe(data => { 
      this.listnode = data; //recepcion de datos
      
      //initialize key
      for (const nodo of this.listnode) { //se recorre lista por nodo para poder llenar las llaves de la tabla dinamica dataPorNodo
        if (!this.dataPorNodo[nodo.id]) {//"Si el ID del nodo NO existe se inserta como llave"
          this.dataPorNodo[nodo.id] = []; // "se inserta el id y se agrega un arreglo vacío listo para recibir lecturas"
        }
      }

      // Ahora obtener las lecturas reales del backend
      this.dataGrafic.getGraphicData().subscribe(lecturas => {
        // Limpiar los datos anteriores
        for (const nodo of this.listnode) {
          this.dataPorNodo[nodo.id] = [];
        }

        // Agrupar las lecturas por nodo_id
        for (const lectura of lecturas) {
          if (this.dataPorNodo[lectura.nodo_id]) {
            this.dataPorNodo[lectura.nodo_id].push(lectura);
          }
        }
        console.log('Lecturas agrupadas por nodo:', this.dataPorNodo);

        // Si algún nodo no tiene lecturas, agregar un dato fake para mostrar algo
        for (const nodo of this.listnode) {
          if (this.dataPorNodo[nodo.id].length === 0) {
            const datoFake: Datagrafic = {
              nodo_id: nodo.id,
              watts_a: 0,
              temperatura: 25,
              id: 0,
              timestamp: Date.now(),
              watts_b: null,
              corriente_a: null,
              corriente_b: null,
              relay_a: null,
              relay_b: null
            };
            this.dataPorNodo[nodo.id].push(datoFake);
          }
        }

        this.updateChartFromData();
        this.last_data_nodo();
        this.startLatestReadingsPolling();
        console.log(this.dataPorNodo);
      });
    });
  }

  constructor() {
    /*
    this.dataGrafic.getGraphicData().subscribe(data => {
      console.log('Usuarios recibidos:', data);
      this.data = data;
    });
    */
    this.chartOptions = {
      series: [
        {
          name: "Nodo - 1",
          data: [10, 41, 35, 51, 49, 62, 69, 91, 148] // Consumo en kW/h
        },
        {
          name: "Nodo - 2",
          data: [20, 30, 45, 32, 55, 40, 75, 80, 120]
        },
        // Aquí puedes meter N nodos dinámicamente
      ],
      chart: {
        height: 500,
        type: "line", // O 'area' para que se vea más moderno con degradados
        zoom: { enabled: false },
        animations: { enabled: true }
      },
      dataLabels: { enabled: false },
      stroke: {
        curve: "smooth", // Líneas suaves, no picudas
        width: 3
      },
      title: {
        text: "Comparativa de Consumo Eléctrico por Nodo",
        align: "left"
      },
      grid: {
        row: {
          colors: ["#f3f3f3", "transparent"], 
          opacity: 0.5
        }
      },
      tooltip: {
        enabled: true,
        y: {
          formatter: (value) => `${value} W`,
          title: {
            formatter: () => 'Consumo:'
          }
        }
      },
      xaxis: {
        categories: ["08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00"],
        title: { text: "Tiempo (Horas)" }
      }
    };

    this.myForm = this.fb.group({
      nombre: ['', Validators.required],
      tipo: ['', Validators.required],
      mac_address: ['', Validators.required]
    });
  }

  toggleForm(): void {
    this.showForm = !this.showForm;
  }

  onSubmit(): void {
    if (this.myForm.valid) {
      this.dataGrafic.crearNuevoNodo(this.myForm.value).subscribe({
        next: () => {
          this.showForm = false;
          this.myForm.reset();
          this.loadData();
        },
        error: (err) => console.error('Error creando nodo:', err)
      });
    }
  }

  private formatTimestamp(timestamp: number): string {
    const date = new Date(timestamp);
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  }

  private updateChartFromData(): void {
    const timestamps = new Set<number>();

    for (const nodoId of Object.keys(this.dataPorNodo)) {
      for (const lectura of this.dataPorNodo[Number(nodoId)]) {
        timestamps.add(lectura.timestamp);
      }
    }

    const sortedTimestamps = Array.from(timestamps).sort((a, b) => a - b);
    const categories = sortedTimestamps.map(ts => this.formatTimestamp(ts));

    const series = this.listnode.map(nodo => {
      const valuesByTimestamp = new Map<number, number | null>();
      for (const lectura of this.dataPorNodo[nodo.id]) {
        valuesByTimestamp.set(lectura.timestamp, lectura.watts_a ?? 0);
      }

      const data = sortedTimestamps.map(ts => valuesByTimestamp.has(ts) ? valuesByTimestamp.get(ts) ?? null : null);
      return {
        name: nodo.nombre || `Nodo ${nodo.id}`,
        data
      };
    });

    this.chartOptions = {
      ...this.chartOptions,
      series,
      xaxis: {
        ...this.chartOptions.xaxis,
        categories
      }
    };
  }

  private startLatestReadingsPolling(): void {
    if (this.pollingStarted) {
      return;
    }

    this.pollingStarted = true;

    interval(5000)
      .pipe(
        switchMap(() => this.dataGrafic.getUltimaLectura()),
        takeUntilDestroyed(this.destroyRef)
      )
      .subscribe({
        next: (ultimasLecturas) => {
          this.mergeLatestReadings(ultimasLecturas);
          this.updateChartFromData();
          this.last_data_nodo();
        },
        error: (err) => console.error('Error obteniendo ultimas lecturas:', err)
      });
  }

  private mergeLatestReadings(ultimasLecturas: Datagrafic[]): void {
    for (const lectura of ultimasLecturas) {
      if (!this.dataPorNodo[lectura.nodo_id]) {
        this.dataPorNodo[lectura.nodo_id] = [];
      }

      const lecturasNodo = this.dataPorNodo[lectura.nodo_id];
      const existingIndex = lecturasNodo.findIndex(item => item.id === lectura.id);

      if (existingIndex >= 0) {
        lecturasNodo[existingIndex] = lectura;
      } else {
        lecturasNodo.push(lectura);
        lecturasNodo.sort((a, b) => a.timestamp - b.timestamp);
      }
    }
  }

  last_data_nodo(){    
    // Sacamos los IDs de los nodos que ya tenemos (1, 2, etc.)
  const ids = Object.keys(this.dataPorNodo);

  for (const id of ids) {
    const numerid = Number(id); // Object.keys siempre devuelve strings
    const lecturas = this.dataPorNodo[numerid];

    // Verificamos que el arreglo no esté vacío
    if (lecturas && lecturas.length > 0) {
      // Tomamos el último elemento con .at(-1) o [length - 1]
      this.last_data_por_nodo[numerid] = lecturas[lecturas.length - 1];
    }
  }

  return this.last_data_por_nodo;
  }
  
  getname(id:number):string{
  const nodo = this.listnode.find(n => n.id === id);
  return nodo ? nodo.nombre : 'No found';  
  }

  getstatus(id:number):number{
  const nodo = this.listnode.find(n => n.id === id);
  return nodo ? nodo.activo : 0;
  }

  //cambiar el estado del nodo de activo/inactivo mediante el uso del id frl nodo y atraves del servicio mandarcelo al backend
  changestatus(nodo_id: number) {
    const nodo = this.listnode.find(n => n.id === nodo_id);

    if (!nodo) {
      console.error('No se encontró el nodo');
      return;
    }

    const nuevoEstado = nodo.activo === 1 ? 0 : 1;

    this.dataGrafic.cambiarEstadoNodo(nodo.id, nuevoEstado).subscribe({
      next: (response) => {
        console.log('Estado actualizado:', response);
        nodo.activo = nuevoEstado;
      },
      error: (err) => {
        console.error('Error al cambiar estado:', err);
        alert('Error al cambiar estado del nodo');
      },
    });
  }
}
