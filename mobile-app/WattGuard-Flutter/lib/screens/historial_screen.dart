import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/lectura.dart';
import '../models/nodo.dart';
import '../providers/nodos_provider.dart';
import '../services/wattguard_service.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _service = WattGuardService();

  Nodo? _nodoSeleccionado;
  DateTime? _desde;
  DateTime? _hasta;

  List<Lectura> _lecturas = [];
  bool _cargando = false;
  String? _error;

  Future<void> _cargar() async {
    if (_nodoSeleccionado == null) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await _service.getLecturas(
        nodoId: _nodoSeleccionado!.id,
        desde: _desde != null
            ? (_desde!.millisecondsSinceEpoch ~/ 1000)
            : null,
        hasta: _hasta != null
            ? (_hasta!.millisecondsSinceEpoch ~/ 1000)
            : null,
        limit: 200,
      );
      setState(() => _lecturas = data.reversed.toList());
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _pickDesde() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _desde ?? DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => _darkDatePicker(ctx, child),
    );
    if (picked != null) {
      setState(() => _desde = picked);
    }
  }

  Future<void> _pickHasta() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hasta ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => _darkDatePicker(ctx, child),
    );
    if (picked != null) {
      setState(() => _hasta = picked.add(const Duration(hours: 23, minutes: 59)));
    }
  }

  Widget _darkDatePicker(BuildContext ctx, Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
      ),
      child: child!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nodos = context.watch<NodosProvider>().nodos;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.show_chart, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Historial de consumo'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Filtros ──
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                // Selector de nodo
                // ignore: deprecated_member_use
                DropdownButtonFormField<Nodo>(
                  value: _nodoSeleccionado, // ignore: deprecated_member_use
                  decoration: const InputDecoration(
                    labelText: 'Nodo',
                    prefixIcon: Icon(Icons.device_hub, color: AppTheme.primary),
                  ),
                  dropdownColor: AppTheme.surface,
                  items: nodos
                      .map((n) => DropdownMenuItem(
                            value: n,
                            child: Text(n.nombre),
                          ))
                      .toList(),
                  onChanged: (n) => setState(() => _nodoSeleccionado = n),
                ),
                const SizedBox(height: 8),
                // Fecha desde/hasta
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: 'Desde',
                        date: _desde,
                        onTap: _pickDesde,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DateButton(
                        label: 'Hasta',
                        date: _hasta,
                        onTap: _pickHasta,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _nodoSeleccionado != null ? _cargar : null,
                    icon: const Icon(Icons.search),
                    label: const Text('Consultar'),
                  ),
                ),
              ],
            ),
          ),

          // ── Contenido ──
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.error)),
            ],
          ),
        ),
      );
    }
    if (_lecturas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, color: AppTheme.inactive, size: 56),
            SizedBox(height: 12),
            Text('Selecciona un nodo y consulta',
                style: TextStyle(color: AppTheme.inactive)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _GraficaWatts(lecturas: _lecturas, nodo: _nodoSeleccionado!),
        const SizedBox(height: 16),
        _ResumenCard(lecturas: _lecturas),
        const SizedBox(height: 16),
        _TablaLecturas(lecturas: _lecturas),
      ],
    );
  }
}

// ─── Widgets internos ────────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 14, color: AppTheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd/MM/yy').format(date!)
                    : label,
                style: TextStyle(
                  color: date != null
                      ? AppTheme.textPrimary
                      : AppTheme.inactive,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraficaWatts extends StatelessWidget {
  final List<Lectura> lecturas;
  final Nodo nodo;

  const _GraficaWatts({required this.lecturas, required this.nodo});

  @override
  Widget build(BuildContext context) {
    final spots = lecturas
        .asMap()
        .entries
        .map((e) => FlSpot(
              e.key.toDouble(),
              e.value.wattsA ?? 0,
            ))
        .toList();

    final spotsB = nodo.esTwinOutlet
        ? lecturas
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.wattsB ?? 0))
            .toList()
        : <FlSpot>[];

    final maxY = [
      ...spots.map((s) => s.y),
      ...spotsB.map((s) => s.y),
    ].fold<double>(0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text('Potencia (W)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
            ),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: (maxY * 1.2).clamp(10, double.infinity),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppTheme.inactive.withAlpha(40),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (_) => FlLine(
                      color: AppTheme.inactive.withAlpha(20),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(0),
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.inactive),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (lecturas.length / 4).ceilToDouble(),
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= lecturas.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            DateFormat('HH:mm')
                                .format(lecturas[idx].fechaHora),
                            style: const TextStyle(
                                fontSize: 9, color: AppTheme.inactive),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primary.withAlpha(30),
                      ),
                    ),
                    if (spotsB.isNotEmpty)
                      LineChartBarData(
                        spots: spotsB,
                        isCurved: true,
                        color: AppTheme.warning,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.warning.withAlpha(30),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (nodo.esTwinOutlet)
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 8),
                child: Row(
                  children: [
                    _LegendDot(color: AppTheme.primary, label: 'Canal A'),
                    SizedBox(width: 16),
                    _LegendDot(color: AppTheme.warning, label: 'Canal B'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.inactive)),
      ],
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final List<Lectura> lecturas;
  const _ResumenCard({required this.lecturas});

  @override
  Widget build(BuildContext context) {
    final watts = lecturas.map((l) => l.wattsA ?? 0).toList();
    final avg = watts.isEmpty
        ? 0.0
        : watts.reduce((a, b) => a + b) / watts.length;
    final max = watts.isEmpty ? 0.0 : watts.reduce((a, b) => a > b ? a : b);
    final min = watts.isEmpty ? 0.0 : watts.reduce((a, b) => a < b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen Canal A',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ResumenItem(label: 'Promedio', value: '${avg.toStringAsFixed(1)} W'),
                _ResumenItem(label: 'Máximo', value: '${max.toStringAsFixed(1)} W'),
                _ResumenItem(label: 'Mínimo', value: '${min.toStringAsFixed(1)} W'),
                _ResumenItem(label: 'Lecturas', value: '${lecturas.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final String label;
  final String value;
  const _ResumenItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary)),
        const SizedBox(height: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppTheme.inactive)),
      ],
    );
  }
}

class _TablaLecturas extends StatelessWidget {
  final List<Lectura> lecturas;
  const _TablaLecturas({required this.lecturas});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Últimas lecturas',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            ...lecturas.take(20).map((l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          DateFormat('HH:mm:ss').format(l.fechaHora),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.inactive),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${(l.wattsA ?? 0).toStringAsFixed(1)} W',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.primary),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${(l.corrienteA ?? 0).toStringAsFixed(2)} A',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textPrimary),
                        ),
                      ),
                      Icon(
                        l.relayA ? Icons.toggle_on : Icons.toggle_off,
                        size: 16,
                        color: l.relayA
                            ? AppTheme.success
                            : AppTheme.inactive,
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
