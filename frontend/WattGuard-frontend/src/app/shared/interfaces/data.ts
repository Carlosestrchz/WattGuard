export interface Datagrafic{
  id: number;
  nodo_id: number;
  watts_a: number | null;
  watts_b: number | null;
  corriente_a: number | null;
  corriente_b: number | null;
  temperatura: number | null;
  timestamp: number;
}

export interface Nodo {
  id: number;
  nombre: string;
  tipo: string;
  mac_address: string;
  activo: number;
  created_at: number;
}

export interface newNodo    {
  nombre: string;
  tipo: string;
  mac_address: string;
}
