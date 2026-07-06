import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // 10.0.2.2 es la IP del PC host vista desde el emulador Android.
  // En dispositivo físico cambiar a la IP local del nodo central (ej. 192.168.x.x:3000).
  static const String _defaultBaseUrl = 'http://10.0.2.2:3000';
  static const String _prefKey = 'wg_base_url';

  static String _baseUrl = _defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  /// Carga la URL guardada en preferencias (llamar en main antes de runApp)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_prefKey) ?? _defaultBaseUrl;
  }

  /// Actualiza y persiste la URL base del servidor
  static Future<void> setBaseUrl(String url) async {
    // Quitar trailing slash para consistencia
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _baseUrl);
  }

  static String get defaultUrl => _defaultBaseUrl;
}
