import { Component, inject, ViewChild} from '@angular/core';
import { NgApexchartsModule } from "ng-apexcharts";
import { Datagrafic } from '../../shared/interfaces/data';

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
  imports: [NgApexchartsModule],
  templateUrl: './home-page.component.html',
  styleUrl: './home-page.component.css'
})
export class HomePageComponent {
  public chartOptions: Partial<ChartOptions>;
  //private dataGrafic=inject(DataGraphicServiceService);
  //private data:Datagrafic[]=[];

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
  }
}
