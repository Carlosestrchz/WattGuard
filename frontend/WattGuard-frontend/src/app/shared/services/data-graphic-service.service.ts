import { inject } from '@angular/core';
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Data } from '@angular/router';
import { Datagrafic, Nodo, newNodo } from '../interfaces/data';


@Injectable({
  providedIn: 'root'
})
export class DataGraphicServiceService {
  private http = inject(HttpClient);
  private apiUrl = 'http://localhost:3000/api';

  constructor() { }

  getListaNodos(): Observable<Nodo[]> {
    return this.http.get<Nodo[]>(`${this.apiUrl}/nodos`);
  }

  crearNuevoNodo(nodo: newNodo): Observable<any> {
    return this.http.post(`${this.apiUrl}/nodos`, nodo);
  }
  
  getGraphicData(): Observable<Datagrafic[]> {
    return this.http.get<Datagrafic[]>(`${this.apiUrl}/lecturas`);
  }

  getUltimosRegistros(): Observable<Datagrafic[]> {
    return this.http.get<Datagrafic[]>(`${this.apiUrl}/lecturas`);
  }

  cambiarEstadoNodo(id: number, activo: number): Observable<any> {
    return this.http.post(`${this.apiUrl}/nodos/${id}/estado`, { activo });
  }

  getUltimaLectura(): Observable<Datagrafic[]> {
    return this.http.get<Datagrafic[]>(`${this.apiUrl}/estado`);
  }
}
