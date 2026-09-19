import 'package:flutter/foundation.dart';

import '../models/nodo.dart';
import '../services/wattguard_service.dart';

class NodosProvider extends ChangeNotifier {
  final _service = WattGuardService();

  List<Nodo> nodos = [];
  bool cargando = false;
  String? error;

  Future<void> load() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      nodos = await _service.getNodos();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<bool> createNodo({
    required String nombre,
    required String tipo,
    String? macAddress,
  }) async {
    try {
      await _service.createNodo(
        nombre: nombre,
        tipo: tipo,
        macAddress: macAddress,
      );
      await load();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
