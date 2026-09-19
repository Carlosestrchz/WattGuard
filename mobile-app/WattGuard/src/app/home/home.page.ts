import { Component } from '@angular/core';
import { IonContent, IonCard,IonCardHeader, IonCardSubtitle, IonCardTitle,IonCardContent,     IonGrid,
    IonRow,
    IonCol,IonToggle} from '@ionic/angular/standalone';
import { SideMenuComponent } from '../componentes/side-menu/side-menu.component';
import { DinamicHeaderComponent } from '../componentes/dinamic-header/dinamic-header.component';
import { BottomNavComponent } from '../componentes/bottom-nav/bottom-nav.component';
import { addIcons } from 'ionicons';
import { powerOutline, settingsSharp} from 'ionicons/icons';
import { IonTitle, IonButton, IonIcon, IonMenuToggle } from '@ionic/angular/standalone';

@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss'],
  imports: [  IonContent, SideMenuComponent,DinamicHeaderComponent,BottomNavComponent, IonCard,IonCardHeader, IonCardSubtitle, IonCardTitle,IonCardContent,IonGrid,
    IonRow,
    IonCol,IonTitle,IonButton,IonIcon,IonToggle],
})
export class HomePage {
  constructor() {
    addIcons({ settingsSharp, powerOutline});
  }
}
