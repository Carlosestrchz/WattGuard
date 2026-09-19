class Lectura {
  final int id;
  final int nodoId;
  final double? corrienteA;
  final double? wattsA;
  final double? corrienteB;
  final double? wattsB;
  final double? temperatura;
  final bool relayA;
  final bool relayB;
  final int timestamp;
  // Campos extras que incluye /api/estado (JOIN con nodos)
  final String? nombre;
  final String? tipo;

  const Lectura({
    required this.id,
    required this.nodoId,
    this.corrienteA,
    this.wattsA,
    this.corrienteB,
    this.wattsB,
    this.temperatura,
    required this.relayA,
    required this.relayB,
    required this.timestamp,
    this.nombre,
    this.tipo,
  });

  factory Lectura.fromJson(Map<String, dynamic> json) => Lectura(
        id: json['id'] as int,
        nodoId: json['nodo_id'] as int,
        corrienteA: (json['corriente_a'] as num?)?.toDouble(),
        wattsA: (json['watts_a'] as num?)?.toDouble(),
        corrienteB: (json['corriente_b'] as num?)?.toDouble(),
        wattsB: (json['watts_b'] as num?)?.toDouble(),
        temperatura: (json['temperatura'] as num?)?.toDouble(),
        relayA: json['relay_a'] == 1 || json['relay_a'] == true,
        relayB: json['relay_b'] == 1 || json['relay_b'] == true,
        timestamp: json['timestamp'] as int? ?? 0,
        nombre: json['nombre'] as String?,
        tipo: json['tipo'] as String?,
      );

  DateTime get fechaHora =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}
