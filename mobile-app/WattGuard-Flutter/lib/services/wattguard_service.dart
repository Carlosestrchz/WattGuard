import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/api_client.dart';
import '../models/alerta.dart';
import '../models/config_item.dart';
import '../models/lectura.dart';
import '../models/nodo.dart';

class WattGuardService {
  String get _base => ApiClient.baseUrl;

  // ─── /health ─────────────────────────────────────────────────────────────

  /// Retorna true si el servidor responde correctamente
  Future<bool> health() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── /api/nodos ──────────────────────────────────────────────────────────

  Future<List<Nodo>> getNodos() async {
    final res = await http
        .get(Uri.parse('$_base/api/nodos'))
        .timeout(const Duration(seconds: 8));
    _check(res);
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => Nodo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> createNodo({
    required String nombre,
    required String tipo,
    String? macAddress,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/api/nodos'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombre': nombre,
            'tipo': tipo,
            if (macAddress != null && macAddress.isNotEmpty)
              'mac_address': macAddress,
          }),
        )
        .timeout(const Duration(seconds: 8));
    _check(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['id'] as int;
  }

  // ─── /api/estado ─────────────────────────────────────────────────────────

  Future<List<Lectura>> getEstado() async {
    final res = await http
        .get(Uri.parse('$_base/api/estado'))
        .timeout(const Duration(seconds: 5));
    _check(res);
    final List data = jsonDecode(res.body) as List;
    return data
        .map((e) => Lectura.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── /api/lecturas ───────────────────────────────────────────────────────

  Future<List<Lectura>> getLecturas({
    int? nodoId,
    int? desde,
    int? hasta,
    int limit = 100,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      if (nodoId != null) 'nodo_id': nodoId.toString(),
      if (desde != null) 'desde': desde.toString(),
      if (hasta != null) 'hasta': hasta.toString(),
    };
    final uri = Uri.parse('$_base/api/lecturas').replace(queryParameters: params);
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    _check(res);
    final List data = jsonDecode(res.body) as List;
    return data
        .map((e) => Lectura.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── /api/alertas ────────────────────────────────────────────────────────

  Future<List<Alerta>> getAlertas({bool resuelta = false}) async {
    final uri = Uri.parse('$_base/api/alertas')
        .replace(queryParameters: {'resuelta': resuelta ? '1' : '0'});
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    _check(res);
    final List data = jsonDecode(res.body) as List;
    return data
        .map((e) => Alerta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> resolverAlerta(int id) async {
    final res = await http
        .post(Uri.parse('$_base/api/alertas/$id/resolver'))
        .timeout(const Duration(seconds: 8));
    _check(res);
  }

  // ─── /api/relay ──────────────────────────────────────────────────────────

  Future<void> setRelay({
    required int nodoId,
    required String canal,
    required bool estado,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/api/relay/$nodoId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'canal': canal, 'estado': estado}),
        )
        .timeout(const Duration(seconds: 8));
    _check(res);
  }

  // ─── /api/config ─────────────────────────────────────────────────────────

  Future<List<ConfigItem>> getConfig() async {
    final res = await http
        .get(Uri.parse('$_base/api/config'))
        .timeout(const Duration(seconds: 8));
    _check(res);
    final List data = jsonDecode(res.body) as List;
    return data
        .map((e) => ConfigItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setConfig(String clave, String valor) async {
    final res = await http
        .put(
          Uri.parse('$_base/api/config'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'clave': clave, 'valor': valor}),
        )
        .timeout(const Duration(seconds: 8));
    _check(res);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Error ${res.statusCode}: ${_tryMessage(res.body)}',
      );
    }
  }

  String _tryMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['error'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }
}
