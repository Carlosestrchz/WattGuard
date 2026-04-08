import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/lectura.dart';
import '../providers/estado_provider.dart';
import '../services/wattguard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = WattGuardService();

  List<Lectura> _historial = [];
  bool _cargandoChart = false;
  EstadoProvider? _estadoProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Escucha al EstadoProvider: cada vez que llega un nuevo polling (2s)
    // también actualizamos el historial del chart.
    final provider = context.read<EstadoProvider>();
    if (_estadoProvider != provider) {
      _estadoProvider?.removeListener(_cargarHistorial);
      _estadoProvider = provider;
      _estadoProvider!.addListener(_cargarHistorial);
      _cargarHistorial(); // carga inicial
    }
  }

  @override
  void dispose() {
    _estadoProvider?.removeListener(_cargarHistorial);
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    if (_cargandoChart) return;
    setState(() => _cargandoChart = true);
    try {
      final data = await _service.getLecturas(limit: 40);
      if (mounted) {
        setState(() => _historial = data.reversed.toList());
      }
    } catch (_) {
      // Silencioso — el chart simplemente no muestra datos
    } finally {
      if (mounted) setState(() => _cargandoChart = false);
    }
  }

  Future<void> _toggleRelay({
    required int nodoId,
    required String canal,
    required bool nuevoEstado,
  }) async {
    try {
      await _service.setRelay(
          nodoId: nodoId, canal: canal, estado: nuevoEstado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Canal ${canal.toUpperCase()} → ${nuevoEstado ? "ON" : "OFF"}'),
          backgroundColor:
              nuevoEstado ? AppTheme.success : AppTheme.textSecondary,
        ));
      }
      // Fuerza actualización inmediata del estado
      if (mounted) context.read<EstadoProvider>().refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EstadoProvider>();
    final lecturas = provider.lecturas;

    final totalWatts = lecturas.fold<double>(
      0,
      (sum, l) => sum + (l.wattsA ?? 0) + (l.wattsB ?? 0),
    );
    final nodosActivos =
        lecturas.where((l) => l.relayA || l.relayB).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          provider.refresh();
          await _cargarHistorial();
        },
        color: AppTheme.primary,
        child: CustomScrollView(
          slivers: [
            // ── Header azul ───────────────────────────────────────────
            _WattGuardHeader(conectado: provider.conectado),

            // ── Resumen de consumo ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _ResumenCard(
                totalWatts: totalWatts,
                nodosActivos: nodosActivos,
                totalNodos: lecturas.length,
              ),
            ),

            // ── Monitoreo de consumo (chart) ───────────────────────────
            SliverToBoxAdapter(
              child: _ChartCard(
                historial: _historial,
                cargando: _cargandoChart,
                onRefresh: _cargarHistorial,
              ),
            ),

            // ── Sección nodos ─────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Sensores / Nodos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),

            if (lecturas.isEmpty)
              const SliverToBoxAdapter(child: _EmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _NodoCard(
                    lectura: lecturas[i],
                    colorIndex: i,
                    onToggleRelay: (canal, estado) => _toggleRelay(
                      nodoId: lecturas[i].nodoId,
                      canal: canal,
                      nuevoEstado: estado,
                    ),
                  ),
                  childCount: lecturas.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets internos ────────────────────────────────────────────────────────

class _WattGuardHeader extends StatelessWidget {
  final bool conectado;
  const _WattGuardHeader({required this.conectado});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryDark, AppTheme.primary],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          child: Row(
            children: [
              // Logo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset('assets/images/logo.png'),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'WattGuard',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    conectado ? 'En línea' : 'Modo Offline',
                    style: TextStyle(
                        color: Colors.white.withAlpha(200), fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              // Estado de conexión
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      conectado ? Icons.wifi : Icons.wifi_off,
                      size: 13,
                      color: conectado
                          ? Colors.greenAccent
                          : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      conectado ? 'Online' : 'Offline',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final double totalWatts;
  final int nodosActivos;
  final int totalNodos;

  const _ResumenCard({
    required this.totalWatts,
    required this.nodosActivos,
    required this.totalNodos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              const Text(
                'Consumo Total en Tiempo Real',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: totalWatts.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    height: 1.1,
                  ),
                ),
                const TextSpan(
                  text: ' W',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$nodosActivos de $totalNodos nodos activos',
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final List<Lectura> historial;
  final bool cargando;
  final VoidCallback onRefresh;

  const _ChartCard({
    required this.historial,
    required this.cargando,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Agrupar lecturas por nodo_id
    final Map<int, List<Lectura>> porNodo = {};
    for (final l in historial) {
      porNodo.putIfAbsent(l.nodoId, () => []).add(l);
    }

    final colors = [
      AppTheme.primary,
      AppTheme.success,
      const Color(0xFF8B5CF6),
      AppTheme.warning,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera ──────────────────────────────────────────────────
          Row(
            children: [
              const Text(
                'Monitoreo de Consumo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (cargando)
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primary))
              else
                GestureDetector(
                  onTap: onRefresh,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.fiber_manual_record,
                            size: 8, color: AppTheme.success),
                        SizedBox(width: 4),
                        Text('Actualización en vivo',
                            style: TextStyle(
                                fontSize: 10, color: AppTheme.primary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (historial.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'Sin datos de historial',
                  style: TextStyle(
                      color: AppTheme.inactive, fontSize: 13),
                ),
              ),
            )
          else
            _buildChart(porNodo, colors),

          // ── Leyenda ───────────────────────────────────────────────────
          if (porNodo.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: porNodo.entries.toList().asMap().entries.map((e) {
                final idx = e.key;
                final lectura = e.value.value.first;
                final color = colors[idx % colors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 16,
                        height: 3,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Text(
                      lectura.nombre ?? 'Nodo ${lectura.nodoId}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChart(
      Map<int, List<Lectura>> porNodo, List<Color> colors) {
    // Máximo de wattsA+B en todo el historial → define el techo del eje Y
    final maxY = historial
        .map((l) => (l.wattsA ?? 0) + (l.wattsB ?? 0))
        .fold<double>(0, (prev, v) => v > prev ? v : prev);
    // Techo redondeado al múltiplo de 50 más próximo por arriba (mín. 50 W)
    final yMax = ((maxY * 1.15 / 50).ceil() * 50.0).clamp(50.0, double.infinity);
    final yInterval = (yMax / 4).roundToDouble().clamp(10.0, double.infinity);

    // Número máximo de puntos en cualquier nodo → base para el intervalo X
    final maxPuntos = porNodo.values
        .map((v) => v.length)
        .fold<int>(1, (a, b) => b > a ? b : a);
    // Mostrar ~5 etiquetas en el eje X como máximo
    final xInterval = (maxPuntos / 4).ceilToDouble().clamp(1.0, 999.0);

    // Lista de lecturas del primer nodo (para las etiquetas de tiempo del eje X)
    final primerasLecturas =
        porNodo.values.isNotEmpty ? porNodo.values.first : <Lectura>[];

    return SizedBox(
      height: 210,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: yMax,
          clipData: const FlClipData.all(),
          // ── Tooltip al tocar ─────────────────────────────────────────
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (spots) => spots.map((s) {
                final color = colors[s.barIndex % colors.length];
                return LineTooltipItem(
                  '${s.y.toStringAsFixed(0)} W',
                  TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          // ── Cuadrícula ───────────────────────────────────────────────
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppTheme.border,
              strokeWidth: 1,
            ),
          ),
          // ── Borde inferior e izquierdo ────────────────────────────────
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: AppTheme.border, width: 1),
              left: BorderSide(color: AppTheme.border, width: 1),
            ),
          ),
          // ── Ejes ─────────────────────────────────────────────────────
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              axisNameWidget: const Text(
                'W',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary),
              ),
              axisNameSize: 18,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: yInterval,
                getTitlesWidget: (v, meta) {
                  // Omitir la etiqueta en el límite superior para evitar recorte
                  if (v == meta.max || v < 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 6,
                    child: Text(
                      v.toStringAsFixed(0),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: xInterval,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= primerasLecturas.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 6,
                    child: Text(
                      DateFormat('HH:mm')
                          .format(primerasLecturas[idx].fechaHora),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ),
          // ── Líneas ───────────────────────────────────────────────────
          lineBarsData: porNodo.entries
              .toList()
              .asMap()
              .entries
              .map((entry) {
            final colorIdx = entry.key;
            final nodoLecturas = entry.value.value;
            final spots = nodoLecturas
                .asMap()
                .entries
                .map((e) => FlSpot(
                      e.key.toDouble(),
                      (e.value.wattsA ?? 0) + (e.value.wattsB ?? 0),
                    ))
                .toList();
            final color = colors[colorIdx % colors.length];
            return LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withAlpha(25),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NodoCard extends StatefulWidget {
  final Lectura lectura;
  final int colorIndex;
  final Future<void> Function(String canal, bool estado) onToggleRelay;

  const _NodoCard({
    required this.lectura,
    required this.colorIndex,
    required this.onToggleRelay,
  });

  @override
  State<_NodoCard> createState() => _NodoCardState();
}

class _NodoCardState extends State<_NodoCard> {
  bool _enviandoA = false;
  bool _enviandoB = false;

  Future<void> _toggle(String canal) async {
    final isA = canal == 'a';
    setState(() {
      if (isA) _enviandoA = true;
      else _enviandoB = true;
    });
    try {
      final estado = isA ? !widget.lectura.relayA : !widget.lectura.relayB;
      await widget.onToggleRelay(canal, estado);
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
    final l = widget.lectura;
    final color = AppTheme.nodeColor(widget.colorIndex);
    final esTwin = l.tipo == 'twin outlet';
    final estaActivo = l.relayA || l.relayB;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Borde izquierdo de color
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Fila superior ──────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: estaActivo ? color : AppTheme.inactive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Nodo ${l.nodoId}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary),
                        ),
                        const Spacer(),
                        // Ícono de power
                        Icon(
                          Icons.power_settings_new,
                          size: 18,
                          color: estaActivo ? color : AppTheme.inactive,
                        ),
                        const SizedBox(width: 8),
                        // Toggle relay A
                        _enviandoA
                            ? const SizedBox(
                                width: 36,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary))
                            : Transform.scale(
                                scale: 0.85,
                                child: Switch(
                                  value: l.relayA,
                                  onChanged: (_) => _toggle('a'),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Nombre del nodo
                    Text(
                      l.nombre ?? 'Nodo ${l.nodoId}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Mini cards de stats ────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatMiniCard(
                            icon: Icons.bolt,
                            label: 'Consumo',
                            value: '${(l.wattsA ?? 0).toStringAsFixed(0)}',
                            unit: 'W',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatMiniCard(
                            icon: Icons.thermostat,
                            label: 'Temperatura',
                            value: l.temperatura != null
                                ? l.temperatura!.toStringAsFixed(1)
                                : '--',
                            unit: '°C',
                          ),
                        ),
                      ],
                    ),

                    // Canal B (twin outlet)
                    if (esTwin) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _StatMiniCard(
                              icon: Icons.bolt,
                              label: 'Canal B',
                              value:
                                  '${(l.wattsB ?? 0).toStringAsFixed(0)}',
                              unit: 'W',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              children: [
                                const Text('Relay B:',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary)),
                                const SizedBox(width: 6),
                                _enviandoB
                                    ? const SizedBox(
                                        width: 24,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.primary))
                                    : Transform.scale(
                                        scale: 0.75,
                                        child: Switch(
                                          value: l.relayB,
                                          onChanged: (_) => _toggle('b'),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 10),

                    // ── Estado ─────────────────────────────────────────
                    Row(
                      children: [
                        const Text('Estado:',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary)),
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: estaActivo
                                ? AppTheme.success
                                : AppTheme.inactive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          estaActivo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: estaActivo
                                ? AppTheme.success
                                : AppTheme.inactive,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _StatMiniCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.device_hub, size: 56, color: AppTheme.inactive),
          SizedBox(height: 12),
          Text(
            'Sin nodos disponibles',
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4),
          Text(
            'Los nodos ESP32-C3 se registran\nautomáticamente al conectarse.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.inactive, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
