import { Routes } from '@angular/router';
import { LoginPageComponent } from './pages/login-page/login-page.component';

export const routes: Routes = [

    {
        path:'login',
        loadComponent: () => import('./pages/login-page/login-page.component').then(m => m.LoginPageComponent),
    },
    {
        path:'register',
        loadComponent: () => import('./pages/register-page/register-page.component').then(m => m.RegisterPageComponent),
    },
    {
        path:'',
        loadComponent: () => import('./app.component').then(m => m.AppComponent),
        children:[
            {
                path:'home',
                loadComponent: () => import('./pages/home-page/home-page.component').then(m => m.HomePageComponent),
            },
            {
                path:'settings',
                loadComponent: () => import('./pages/setting-page/setting-page.component').then(m => m.SettingPageComponent),
            },
            {
                path:'Profile',
                loadComponent: () => import('./pages/profile-page/profile-page.component').then(m => m.ProfilePageComponent),
            },
            {
                path:'**',
                redirectTo: 'login'
            }

        ]
    },
    {
        path:'**',
        redirectTo: 'login'
    }
];
