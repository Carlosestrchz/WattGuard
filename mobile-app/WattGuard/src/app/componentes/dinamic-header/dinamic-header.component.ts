import { Component, OnInit } from '@angular/core';
import { IonToolbar, IonTitle, IonHeader, IonMenuToggle, IonButton, IonIcon, IonCard,IonCardHeader, IonCardSubtitle, IonCardTitle,IonCardContent } from '@ionic/angular/standalone';

@Component({
  selector: 'dinamic-header',
  templateUrl: './dinamic-header.component.html',
  styleUrls: ['./dinamic-header.component.scss'],
  imports: [IonHeader,
    IonTitle,
    IonToolbar,
    IonMenuToggle, IonButton, IonIcon]
})
export class DinamicHeaderComponent  implements OnInit {


  //titulo=input.required<string>();
  //bandera=input.required<boolean>();
  titulo:string="";
  bandera:boolean=false;
  subtitle:string="";

  constructor() { }

  ngOnInit() {this.selectitle();}

  selectitle(){
    if (this.bandera==true){
      this.titulo="WattGuard";
      this.subtitle="Modo offline";
    }else{
      this.titulo="WattGuard";
      this.subtitle="Modo offline";
    }
  }

  

  

}
