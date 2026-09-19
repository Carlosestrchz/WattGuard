import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart' as wifi;

import '../core/api_client.dart';
import '../core/app_theme.dart';
import 'main_screen.dart';

enum _Step { config, connecting, done }

class OfflineWifiScreen extends StatefulWidget {
  const OfflineWifiScreen({super.key});

  @override
  State<OfflineWifiScreen> createState() => _OfflineWifiScreenState();
}

class _OfflineWifiScreenState extends State<OfflineWifiScreen> {
  static const _channel = MethodChannel('com.cognitio.wattguard/settings');

  final _ssidCtrl = TextEditingController(text: 'WattGuard-Net');
  final _passCtrl = TextEditingController();
  final _ipCtrl = TextEditingController(text: '192.168.4.1');
  final _portCtrl = TextEditingController(text: '3000');

  _Step _step = _Step.config;
  String _statusMsg = '';
  String _currentSsid = '—';
  bool _obscurePass = true;
  bool _isBusy = false;
  Timer? _pollTimer;

  // Guarda SSID e IP para usarlos en el polling sin leer los controllers
  String _targetSsid = '';
  String _targetIp = '';
  String _targetPort = '';

  @override
  void dispose() {
    _pollTimer?.cancel();
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    // Libera el binding de red al salir para no afectar otras conexiones
    if (Platform.isAndroid) {
      wifi.WiFiForIoTPlugin.forceWifiUsage(false);
    }
    super.dispose();
  }

  // ── Lógica principal ────────────────────────────────────────────────────

  Future<void> _iniciarConexion() async {
    final ssid = _ssidCtrl.text.trim();
    final ip = _ipCtrl.text.trim();
    final port = _portCtrl.text.trim();

    if (ssid.isEmpty || ip.isEmpty || port.isEmpty) {
      _snack('Completa los campos requeridos', AppTheme.warning);
      return;
    }

    if (Platform.isAndroid) {
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        if (!mounted) return;
        _snack(
          'Se necesita permiso de ubicación para leer redes WiFi en Android',
          AppTheme.warning,
        );
        return;
      }
    }

    _targetSsid = ssid;
    _targetIp = ip;
    _targetPort = port;

    setState(() {
      _step = _Step.connecting;
      _statusMsg = 'Buscando "$ssid"…';
      _isBusy = true;
    });

    // Intenta conexión programática (funciona bien en Android < 10;
    // en Android 10+ puede requerir confirmación del usuario).
    if (Platform.isAndroid) {
      try {
        final pass = _passCtrl.text;
        final ok = await wifi.WiFiForIoTPlugin.connect(
          ssid,
          password: pass.isNotEmpty ? pass : null,
          security: pass.isNotEmpty
              ? wifi.NetworkSecurity.WPA
              : wifi.NetworkSecurity.NONE,
          joinOnce: false,
          withInternet: false, // Le indica a Android que no espere internet
        );
        if (ok && mounted) {
          setState(() => _statusMsg = 'Conexión iniciada. Verificando…');
        }
      } catch (_) {
        // Android 10+ puede no permitir conexión directa → el usuario conecta manualmente
        if (mounted) {
          setState(
            () => _statusMsg =
                'Conéctate manualmente a "$ssid" desde la configuración WiFi',
          );
        }
      }
    }

    setState(() => _isBusy = false);
    _iniciarPolling();
  }

  void _iniciarPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      String? ssid;
      try {
        ssid = await wifi.WiFiForIoTPlugin.getSSID();
        // En algunos Android el SSID viene entre comillas
        ssid = ssid?.replaceAll('"', '').trim();
      } catch (_) {}

      if (!mounted) return;
      setState(() => _currentSsid = ssid ?? '—');

      if (ssid == _targetSsid) {
        _pollTimer?.cancel();
        await _alConectarse();
      }
    });
  }

  Future<void> _alConectarse() async {
    setState(() {
      _statusMsg = 'Red detectada. Configurando tráfico local…';
      _isBusy = true;
    });

    if (Platform.isAndroid) {
      // bindProcessToNetwork: obliga a Android a enrutar el tráfico HTTP
      // de esta app por este WiFi aunque no tenga acceso a internet.
      // Esto resuelve el problema donde Android prefiere datos móviles
      // cuando el AP no tiene internet.
      await wifi.WiFiForIoTPlugin.forceWifiUsage(true);
    }

    final url = 'http://$_targetIp:$_targetPort';
    await ApiClient.setBaseUrl(url);

    setState(() {
      _step = _Step.done;
      _statusMsg = url;
      _isBusy = false;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  Future<void> _abrirAjustesWifi() async {
    try {
      await _channel.invokeMethod('openWifiSettings');
    } catch (_) {
      _snack(
        'Ve a Ajustes → WiFi y conéctate a "$_targetSsid"',
        AppTheme.primary,
      );
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Modo Offline – Red Local'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        leading: _step == _Step.config
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: switch (_step) {
          _Step.config => _buildConfig(),
          _Step.connecting => _buildConnecting(),
          _Step.done => _buildDone(),
        },
      ),
    );
  }

  Widget _buildConfig() {
    return SingleChildScrollView(
      key: const ValueKey('config'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Descripción
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_tethering, color: AppTheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Conexión al nodo central',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'La app se conectará al Access Point del nodo central '
                        'y forzará el tráfico HTTP por esa red, aunque no tenga '
                        'acceso a internet.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Red del nodo central',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // SSID
          TextField(
            controller: _ssidCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre de red (SSID)',
              prefixIcon: Icon(Icons.wifi, color: AppTheme.textSecondary),
              hintText: 'WattGuard-Net',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          // Contraseña (opcional)
          TextField(
            controller: _passCtrl,
            decoration: InputDecoration(
              labelText: 'Contraseña (dejar vacío si es abierta)',
              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            obscureText: _obscurePass,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),

          const Text(
            'Dirección del servidor',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // IP + Puerto en fila
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _ipCtrl,
                  decoration: const InputDecoration(
                    labelText: 'IP del AP',
                    prefixIcon: Icon(Icons.router_outlined, color: AppTheme.textSecondary),
                    hintText: '192.168.4.1',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _portCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Puerto',
                    hintText: '3000',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          ElevatedButton.icon(
            onPressed: _iniciarConexion,
            icon: const Icon(Icons.bolt),
            label: const Text('Conectar al nodo central'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnecting() {
    final isConnected = _currentSsid == _targetSsid;

    return Padding(
      key: const ValueKey('connecting'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Estado de conexión
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppTheme.success.withAlpha(20)
                  : AppTheme.warning.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConnected
                    ? AppTheme.success.withAlpha(100)
                    : AppTheme.warning.withAlpha(100),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.wifi_find,
                  color: isConnected ? AppTheme.success : AppTheme.warning,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  isConnected
                      ? 'Conectado a "$_targetSsid"'
                      : 'Esperando conexión…',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? AppTheme.success : AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMsg,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isBusy) ...[
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Red detectada actualmente
          _InfoRow(
            label: 'Red actual:',
            value: _currentSsid,
            highlight: isConnected,
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Red objetivo:', value: _targetSsid),
          _InfoRow(
            label: 'Servidor:',
            value: 'http://$_targetIp:$_targetPort',
          ),

          const SizedBox(height: 24),

          // Nota sobre Android
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppTheme.textSecondary, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Nota para Android',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Si Android muestra "Red sin internet, ¿mantener conexión?", '
                  'selecciona Sí o Mantener. La app ya forzará el tráfico '
                  'por esta red automáticamente.',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botón para abrir ajustes WiFi
          OutlinedButton.icon(
            onPressed: _abrirAjustesWifi,
            icon: const Icon(Icons.settings_outlined, color: AppTheme.primary),
            label: const Text(
              'Abrir configuración WiFi',
              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: () {
              _pollTimer?.cancel();
              if (Platform.isAndroid) wifi.WiFiForIoTPlugin.forceWifiUsage(false);
              setState(() => _step = _Step.config);
            },
            child: const Text('Cambiar configuración'),
          ),
        ],
      ),
    );
  }

  Widget _buildDone() {
    return Center(
      key: const ValueKey('done'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Conectado en modo offline',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMsg,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'Abriendo dashboard…',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget auxiliar ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: highlight ? AppTheme.success : AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
