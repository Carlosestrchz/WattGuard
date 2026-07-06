import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/lectura.dart';
import '../services/wattguard_service.dart';

class EstadoProvider extends ChangeNotifier {
  final _service = WattGuardService();

  List<Lectura> lecturas = [];
  bool conectado = false;
  bool cargando = false;
  String? error;

  Timer? _timer;

  /// Inicia el polling de /api/estado cada 2 segundos
  void startPolling() {
    _fetchEstado();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchEstado());
  }

  Future<void> _fetchEstado() async {
    // Evita solapamiento de requests
    if (cargando) return;
    cargando = true;

    try {
      final result = await _service.getEstado();
      final ok = await _service.health();
      lecturas = result;
      conectado = ok;
      error = null;
    } catch (e) {
      conectado = false;
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Fuerza una actualización inmediata
  Future<void> refresh() => _fetchEstado();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
