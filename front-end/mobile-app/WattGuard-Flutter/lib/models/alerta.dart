class Alerta {
  final int id;
  final int? nodoId;
  final String tipo;
  final String? descripcion;
  final bool resuelta;
  final int timestamp;
  final String? nodoNombre;

  const Alerta({
    required this.id,
    this.nodoId,
    required this.tipo,
    this.descripcion,
    required this.resuelta,
    required this.timestamp,
    this.nodoNombre,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) => Alerta(
        id: json['id'] as int,
        nodoId: json['nodo_id'] as int?,
        tipo: json['tipo'] as String,
        descripcion: json['descripcion'] as String?,
        resuelta: json['resuelta'] == 1 || json['resuelta'] == true,
        timestamp: json['timestamp'] as int? ?? 0,
        nodoNombre: json['nodo_nombre'] as String?,
      );

  DateTime get fechaHora =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}
