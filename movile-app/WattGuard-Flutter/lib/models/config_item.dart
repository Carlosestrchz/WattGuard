class ConfigItem {
  final String clave;
  final String valor;

  const ConfigItem({required this.clave, required this.valor});

  factory ConfigItem.fromJson(Map<String, dynamic> json) => ConfigItem(
        clave: json['clave'] as String,
        valor: json['valor'] as String,
      );
}
