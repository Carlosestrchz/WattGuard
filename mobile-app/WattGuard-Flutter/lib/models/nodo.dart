class Nodo {
  final int id;
  final String nombre;
  final String tipo;
  final String? macAddress;
  final bool activo;
  final int createdAt;

  const Nodo({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.macAddress,
    required this.activo,
    required this.createdAt,
  });

  factory Nodo.fromJson(Map<String, dynamic> json) => Nodo(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        tipo: json['tipo'] as String,
        macAddress: json['mac_address'] as String?,
        activo: json['activo'] == 1 || json['activo'] == true,
        createdAt: json['created_at'] as int? ?? 0,
      );

  /// Retorna true si el nodo tiene canal B (tipo twin outlet)
  bool get esTwinOutlet => tipo == 'twin outlet';

  @override
  String toString() => 'Nodo($id, $nombre, $tipo)';
}
