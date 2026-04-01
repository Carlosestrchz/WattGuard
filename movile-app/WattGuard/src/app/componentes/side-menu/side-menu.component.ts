import { Component, OnInit } from '@angular/core';
import { IonIcon, IonHeader, IonTitle, IonToolbar, IonContent, IonMenu, IonButton, IonCard,IonMenuToggle,IonGrid,
    IonRow,
    IonCol,IonToggle } from '@ionic/angular/standalone';

import { addIcons } from 'ionicons';
import { closeOutline, chevronForwardOutline, logoApple } from 'ionicons/icons'; // Updated imports for better icon usage

@Component({
  selector: 'side-menu',
  templateUrl: './side-menu.component.html',
  styleUrls: ['./side-menu.component.scss'],
  imports: [IonIcon, IonHeader, IonTitle, IonToolbar, IonContent, IonMenu, IonButton, IonCard,IonMenuToggle,
    IonGrid,
    IonRow,
    IonCol,IonToggle
  ],
})
export class SideMenuComponent  implements OnInit {

  constructor() {
    addIcons({ logoApple ,closeOutline, chevronForwardOutline }); // Registering new icons
  }

  ngOnInit() {}

}
