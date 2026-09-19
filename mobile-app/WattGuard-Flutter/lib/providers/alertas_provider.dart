import 'package:flutter/foundation.dart';

import '../models/alerta.dart';
import '../services/wattguard_service.dart';

class AlertasProvider extends ChangeNotifier {
  final _service = WattGuardService();

  List<Alerta> activas = [];
  List<Alerta> resueltas = [];
  bool cargando = false;
  String? error;

  int get countActivas => activas.length;

  Future<void> load() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getAlertas(resuelta: false),
        _service.getAlertas(resuelta: true),
      ]);
      activas = results[0];
      resueltas = results[1];
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<bool> resolver(int id) async {
    try {
      await _service.resolverAlerta(id);
      await load();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
