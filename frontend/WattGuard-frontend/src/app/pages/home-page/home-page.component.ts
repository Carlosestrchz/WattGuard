import { Component, inject, OnInit, ViewChild} from '@angular/core';
import { NgApexchartsModule } from "ng-apexcharts";
import { Datagrafic, Nodo, newNodo } from '../../shared/interfaces/data';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';

import {
  ChartComponent,
  ApexAxisChartSeries,
  ApexChart,
  ApexXAxis,
  ApexDataLabels,
  ApexTitleSubtitle,
  ApexStroke,
  ApexGrid
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
  
  private listnode:Nodo[]=[]; //lista de los nodos que ya estan en la base de datos
  
  private dataPorNodo: { [key: number]: Datagrafic[] } = {};//tabla dinamica tipo lista indexada por nodo id, para almacenar los daros de cada nodo, con el nodo id como indice
  public last_data_por_nodo: { [key: number]: Datagrafic } = {};//ultimo registro de cada nodo

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
        // DATO DE PRUEBA: Para que veas algo en pantalla ahora mismo
          const datoFake: Datagrafic = {
          nodo_id: nodo.id,
          watts_a: 0,
          temperatura: 25,
          id: 0,
          timestamp: Date.now(),
          watts_b: null,
          corriente_a: null,
          corriente_b: null
      };
      this.dataPorNodo[nodo.id].push(datoFake);
        }
      }
      this.last_data_nodo();
      console.log(this.dataPorNodo);
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
}
