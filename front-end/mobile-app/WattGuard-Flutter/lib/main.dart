import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/app_theme.dart';
import 'providers/alertas_provider.dart';
import 'providers/config_provider.dart';
import 'providers/estado_provider.dart';
import 'providers/nodos_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.init();
  runApp(const WattGuardApp());
}

class WattGuardApp extends StatelessWidget {
  const WattGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EstadoProvider()..startPolling()),
        ChangeNotifierProvider(create: (_) => NodosProvider()..load()),
        ChangeNotifierProvider(create: (_) => AlertasProvider()..load()),
        ChangeNotifierProvider(create: (_) => ConfigProvider()..load()),
      ],
      child: MaterialApp(
        title: 'WattGuard',
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
