import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/alerta.dart';
import '../providers/alertas_provider.dart';

class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertasProvider>();
    final todas = [...provider.activas, ...provider.resueltas];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primary,
            title: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.white),
                const SizedBox(width: 10),
                const Text('Notificaciones',
                    style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                if (provider.countActivas > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.countActivas} sin leer',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: provider.load,
              ),
            ],
          ),

          // ── Lista ──────────────────────────────────────────────────────
          if (provider.cargando)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else if (todas.isEmpty)
            const SliverFillRemaining(
              child: _EmptyNotif(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i == 0 && provider.activas.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(label: 'Activas'),
                        ...provider.activas.map((a) => _AlertaTile(
                              alerta: a,
                              onResolver: () async {
                                final ok =
                                    await provider.resolver(a.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(ok
                                      ? 'Alerta resuelta'
                                      : provider.error ?? 'Error'),
                                  backgroundColor: ok
                                      ? AppTheme.success
                                      : AppTheme.error,
                                ));
                              },
                            )),
                        if (provider.resueltas.isNotEmpty)
                          _SectionLabel(label: 'Anteriores'),
                        ...provider.resueltas
                            .map((a) => _AlertaTile(alerta: a)),
                      ],
                    );
                  }
                  return null;
                },
                childCount: 1,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Widgets internos ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5)),
    );
  }
}

class _AlertaTile extends StatelessWidget {
  final Alerta alerta;
  final VoidCallback? onResolver;

  const _AlertaTile({required this.alerta, this.onResolver});

  _AlertaMeta get _meta {
    final t = alerta.tipo.toLowerCase();
    if (t.contains('consumo') || t.contains('alto')) {
      return _AlertaMeta(
          icon: Icons.warning_amber_rounded,
          color: AppTheme.warning,
          bg: const Color(0xFFFFFBEB));
    }
    if (t.contains('desconect') || t.contains('nodo')) {
      return _AlertaMeta(
          icon: Icons.wifi_off_rounded,
          color: AppTheme.error,
          bg: const Color(0xFFFEF2F2));
    }
    if (t.contains('ahorro') || t.contains('reducción')) {
      return _AlertaMeta(
          icon: Icons.eco_rounded,
          color: AppTheme.success,
          bg: const Color(0xFFF0FDF4));
    }
    if (t.contains('temp')) {
      return _AlertaMeta(
          icon: Icons.thermostat,
          color: AppTheme.error,
          bg: const Color(0xFFFEF2F2));
    }
    return _AlertaMeta(
        icon: Icons.info_outline,
        color: AppTheme.primary,
        bg: const Color(0xFFEFF6FF));
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    final ts = _timeAgo(alerta.fechaHora);
    final resuelta = alerta.resuelta;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Icono
          Container(
            margin: const EdgeInsets.all(14),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: meta.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(meta.icon, color: meta.color, size: 22),
          ),

          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alerta.tipo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: resuelta
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (!resuelta)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: meta.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (alerta.descripcion != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      alerta.descripcion!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 11, color: AppTheme.inactive),
                      const SizedBox(width: 3),
                      Text(ts,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.inactive)),
                      if (onResolver != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: onResolver,
                          child: Text(
                            'Resolver',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} minutos';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} horas';
    return DateFormat('dd/MM HH:mm').format(dt);
  }
}

class _AlertaMeta {
  final IconData icon;
  final Color color;
  final Color bg;
  const _AlertaMeta(
      {required this.icon, required this.color, required this.bg});
}

class _EmptyNotif extends StatelessWidget {
  const _EmptyNotif();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none,
              size: 64, color: AppTheme.inactive),
          SizedBox(height: 12),
          Text('Sin notificaciones',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary)),
          SizedBox(height: 4),
          Text('Todo está funcionando correctamente.',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.inactive)),
        ],
      ),
    );
  }
}
