import 'package:flutter/foundation.dart';

import '../models/config_item.dart';
import '../services/wattguard_service.dart';

class ConfigProvider extends ChangeNotifier {
  final _service = WattGuardService();

  List<ConfigItem> items = [];
  bool cargando = false;
  String? error;

  String? valueOf(String clave) {
    try {
      return items.firstWhere((c) => c.clave == clave).valor;
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      items = await _service.getConfig();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<bool> set(String clave, String valor) async {
    try {
      await _service.setConfig(clave, valor);
      await load();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
