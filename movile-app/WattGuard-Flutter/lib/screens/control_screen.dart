import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/nodo.dart';
import '../providers/estado_provider.dart';
import '../providers/nodos_provider.dart';
import '../services/wattguard_service.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nodos = context.watch<NodosProvider>().nodos;
    final cargandoNodos = context.watch<NodosProvider>().cargando;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.power_settings_new, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Control de relays'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<NodosProvider>().load();
              context.read<EstadoProvider>().refresh();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: cargandoNodos
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : nodos.isEmpty
              ? const Center(
                  child: Text('No hay nodos registrados',
                      style: TextStyle(color: AppTheme.inactive)))
              : ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  children: nodos
                      .map((nodo) => _NodoControlCard(nodo: nodo))
                      .toList(),
                ),
    );
  }
}

// ─── Widgets internos ────────────────────────────────────────────────────────

class _NodoControlCard extends StatefulWidget {
  final Nodo nodo;
  const _NodoControlCard({required this.nodo});

  @override
  State<_NodoControlCard> createState() => _NodoControlCardState();
}

class _NodoControlCardState extends State<_NodoControlCard> {
  final _service = WattGuardService();

  bool _relayA = false;
  bool _relayB = false;
  bool _enviandoA = false;
  bool _enviandoB = false;
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      _sincronizarDesdeEstado();
      _inicializado = true;
    }
  }

  void _sincronizarDesdeEstado() {
    final lecturas = context.read<EstadoProvider>().lecturas;
    final lectura =
        lecturas.where((l) => l.nodoId == widget.nodo.id).firstOrNull;
    if (lectura != null) {
      setState(() {
        _relayA = lectura.relayA;
        _relayB = lectura.relayB;
      });
    }
  }

  Future<void> _toggleRelay(String canal) async {
    final isA = canal == 'a';
    final estadoActual = isA ? _relayA : _relayB;
    final nuevoEstado = !estadoActual;

    setState(() {
      if (isA) {
        _enviandoA = true;
        _relayA = nuevoEstado;
      } else {
        _enviandoB = true;
        _relayB = nuevoEstado;
      }
    });

    try {
      await _service.setRelay(
        nodoId: widget.nodo.id,
        canal: canal,
        estado: nuevoEstado,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Relay ${canal.toUpperCase()} → ${nuevoEstado ? "ON" : "OFF"}',
          ),
          backgroundColor: nuevoEstado ? AppTheme.success : AppTheme.inactive,
        ));
      }
    } catch (e) {
      // Revertir en caso de error
      if (mounted) {
        setState(() {
          if (isA) _relayA = estadoActual;
          else _relayB = estadoActual;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isA) _enviandoA = false;
          else _enviandoB = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sincronizar estado con el polling en cada rebuild
    final lecturas = context.watch<EstadoProvider>().lecturas;
    final lectura =
        lecturas.where((l) => l.nodoId == widget.nodo.id).firstOrNull;
    if (lectura != null && !_enviandoA && !_enviandoB) {
      _relayA = lectura.relayA;
      _relayB = lectura.relayB;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del nodo
            Row(
              children: [
                Icon(
                  widget.nodo.esTwinOutlet
                      ? Icons.electrical_services
                      : Icons.power,
                  color: AppTheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nodo.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        widget.nodo.tipo,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.inactive),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Canal A
            _RelayRow(
              label: widget.nodo.esTwinOutlet ? 'Canal A' : 'Relay',
              estado: _relayA,
              enviando: _enviandoA,
              onToggle: () => _toggleRelay('a'),
            ),

            // Canal B (solo twin outlet)
            if (widget.nodo.esTwinOutlet) ...[
              const SizedBox(height: 12),
              _RelayRow(
                label: 'Canal B',
                estado: _relayB,
                enviando: _enviandoB,
                onToggle: () => _toggleRelay('b'),
              ),
            ],

            // Watts actuales (de /api/estado)
            if (lectura != null) ...[
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.flash_on,
                      size: 14, color: AppTheme.inactive),
                  const SizedBox(width: 4),
                  Text(
                    'Canal A: ${(lectura.wattsA ?? 0).toStringAsFixed(1)} W',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.inactive),
                  ),
                  if (widget.nodo.esTwinOutlet) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Canal B: ${(lectura.wattsB ?? 0).toStringAsFixed(1)} W',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.inactive),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RelayRow extends StatelessWidget {
  final String label;
  final bool estado;
  final bool enviando;
  final VoidCallback onToggle;

  const _RelayRow({
    required this.label,
    required this.estado,
    required this.enviando,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textPrimary)),
              Text(
                estado ? 'Encendido' : 'Apagado',
                style: TextStyle(
                  fontSize: 12,
                  color: estado ? AppTheme.success : AppTheme.inactive,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (enviando)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.primary),
          )
        else
          Switch(
            value: estado,
            onChanged: (_) => onToggle(),
          ),
      ],
    );
  }
}
