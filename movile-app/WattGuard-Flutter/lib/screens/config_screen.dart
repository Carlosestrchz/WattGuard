import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../providers/config_provider.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _urlController = TextEditingController();
  final _voltajeController = TextEditingController();
  final _nilmController = TextEditingController();
  bool _guardandoUrl = false; // ignore: unused_field

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiClient.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _voltajeController.dispose();
    _nilmController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.error : AppTheme.success,
    ));
  }

  Future<void> _guardarUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    setState(() => _guardandoUrl = true);
    await ApiClient.setBaseUrl(url);
    if (!mounted) return;
    context.read<ConfigProvider>().load();
    setState(() => _guardandoUrl = false);
    _showSnack('URL del servidor actualizada');
  }

  Future<void> _guardarConfig(
      ConfigProvider cp, String clave, TextEditingController ctrl) async {
    final v = ctrl.text.trim();
    if (v.isEmpty) return;
    final ok = await cp.set(clave, v);
    if (!mounted) return;
    _showSnack(
        ok ? 'Parámetro actualizado' : cp.error ?? 'Error',
        error: !ok);
    if (ok) ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ConfigProvider>();
    final voltajeActual = cp.valueOf('voltaje_v') ?? '--';
    final nilmActual = cp.valueOf('nilm_threshold') ?? '--';
    final version = cp.valueOf('version') ?? '1.0.0';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
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
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.settings,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Configuraciones',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Personaliza tu experiencia',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () => cp.load(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: cp.cargando
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary)),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Conexión ─────────────────────────────────
                        _SectionLabel(label: 'Conexión'),
                        _SettingsCard(children: [
                          _SettingsTile(
                            icon: Icons.router_outlined,
                            title: 'Servidor (URL base)',
                            subtitle: ApiClient.baseUrl,
                            onTap: () => _showUrlDialog(context),
                          ),
                        ]),

                        const SizedBox(height: 16),

                        // ── Parámetros del sistema ────────────────────
                        _SectionLabel(label: 'Sistema eléctrico'),
                        _SettingsCard(children: [
                          _SettingsTile(
                            icon: Icons.electric_bolt_outlined,
                            title: 'Voltaje nominal',
                            subtitle: '$voltajeActual V',
                            onTap: () => _showEditDialog(
                              context,
                              label: 'Voltaje (V)',
                              hint: 'ej. 127',
                              controller: _voltajeController,
                              onSave: () =>
                                  _guardarConfig(cp, 'voltaje_v', _voltajeController),
                            ),
                          ),
                          const Divider(height: 1, indent: 56),
                          _SettingsTile(
                            icon: Icons.tune_outlined,
                            title: 'Umbral NILM',
                            subtitle: '$nilmActual W',
                            onTap: () => _showEditDialog(
                              context,
                              label: 'Umbral NILM (W)',
                              hint: 'ej. 20',
                              controller: _nilmController,
                              onSave: () =>
                                  _guardarConfig(cp, 'nilm_threshold', _nilmController),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 16),

                        // ── Notificaciones ───────────────────────────
                        _SectionLabel(label: 'Notificaciones'),
                        _SettingsCard(children: [
                          _SettingsToggle(
                            icon: Icons.notifications_outlined,
                            title: 'Alertas de Consumo Alto',
                            value: true,
                            onChanged: (_) {},
                          ),
                          const Divider(height: 1, indent: 56),
                          _SettingsToggle(
                            icon: Icons.notifications_outlined,
                            title: 'Notificaciones Push',
                            value: false,
                            onChanged: (_) {},
                          ),
                        ]),

                        const SizedBox(height: 16),

                        // ── Soporte ───────────────────────────────────
                        _SectionLabel(label: 'Soporte'),
                        _SettingsCard(children: [
                          _SettingsTile(
                            icon: Icons.bolt_outlined,
                            title: 'Acerca de WattGuard',
                            subtitle: 'WattGuard v$version',
                            onTap: () {},
                            trailing: const Icon(Icons.chevron_right,
                                color: AppTheme.inactive, size: 18),
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // ── Footer ────────────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'WattGuard v$version',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '© 2026 WattGuard. Todos los derechos reservados.',
                                style: TextStyle(
                                    color: AppTheme.inactive, fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showUrlDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('URL del servidor'),
        content: TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'URL base',
            hintText: 'http://192.168.4.1:3000',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _guardarUrl();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required VoidCallback onSave,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onSave();
            },
            child: const Text('Guardar'),
          ),
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
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.textPrimary)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right,
                    color: AppTheme.inactive, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textPrimary)),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
