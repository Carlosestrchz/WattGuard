import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../providers/alertas_provider.dart';
import 'alertas_screen.dart';
import 'config_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'perfil_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AlertasScreen(),
    PerfilScreen(),
    ConfigScreen(),
  ];

  void _salir() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertasCount = context.watch<AlertasProvider>().countActivas;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          if (i == 4) {
            _salir();
          } else {
            setState(() => _currentIndex = i);
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: alertasCount > 0,
              label: Text('$alertasCount'),
              backgroundColor: AppTheme.error,
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: alertasCount > 0,
              label: Text('$alertasCount'),
              backgroundColor: AppTheme.error,
              child: const Icon(Icons.notifications),
            ),
            label: 'Alertas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
          NavigationDestination(
            icon: const Icon(Icons.logout, color: AppTheme.error),
            selectedIcon: const Icon(Icons.logout, color: AppTheme.error),
            label: 'Salir',
          ),
        ],
      ),
    );
  }
}
