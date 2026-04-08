import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withAlpha(30),
                      child: const Icon(Icons.person,
                          size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Usuario WattGuard',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modo Offline',
                      style: TextStyle(
                          color: Colors.white.withAlpha(200), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Contenido ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoCard(
                    children: [
                      _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Nombre',
                          value: 'Usuario'),
                      const Divider(height: 1),
                      _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Correo',
                          value: '—'),
                      const Divider(height: 1),
                      _InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Modo',
                          value: 'Offline'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    children: [
                      _InfoRow(
                          icon: Icons.info_outline,
                          label: 'Versión',
                          value: 'v1.0.0'),
                      const Divider(height: 1),
                      _InfoRow(
                          icon: Icons.bolt_outlined,
                          label: 'Sistema',
                          value: 'WattGuard'),
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
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
