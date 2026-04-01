import { Component, OnInit } from '@angular/core';
import { IonTabs, IonTabBar, IonIcon, IonTabButton } from '@ionic/angular/standalone';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { exitOutline,personCircleOutline,homeOutline, notificationsOutline } from 'ionicons/icons';
import { addIcons } from 'ionicons';

@Component({
  selector: 'bottom-nav',
  templateUrl: './bottom-nav.component.html',
  styleUrls: ['./bottom-nav.component.scss'],
  imports: [IonIcon, IonTabBar, IonTabButton, IonTabs, RouterLink, RouterLinkActive,]
})
export class BottomNavComponent  implements OnInit {

 
   constructor() { 
    addIcons({ exitOutline,personCircleOutline,homeOutline,notificationsOutline});
  }

  ngOnInit() {}

}
