import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'main_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _entrarOffline(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ── Header azul ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryDark, AppTheme.primary],
              ),
            ),
            padding: const EdgeInsets.only(top: 72, bottom: 40),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Image.asset('assets/images/logo.png'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'WattGuard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agente de gestión energética',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ── Formulario ───────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: Icon(Icons.email_outlined,
                          color: AppTheme.textSecondary),
                      hintText: 'tu@email.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: false, // Sin backend de auth
                  ),
                  const SizedBox(height: 14),

                  // Contraseña
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline,
                          color: AppTheme.textSecondary),
                      suffixIcon: Icon(Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary),
                    ),
                    obscureText: true,
                    enabled: false, // Sin backend de auth
                  ),
                  const SizedBox(height: 24),

                  // Botón Iniciar Sesión (deshabilitado)
                  ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor:
                          AppTheme.primary.withAlpha(80),
                      disabledForegroundColor: Colors.white,
                    ),
                    child: const Text('Iniciar Sesión'),
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: TextButton(
                      onPressed: null,
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                        children: [
                          const TextSpan(text: '¿No tienes cuenta? '),
                          TextSpan(
                            text: 'Regístrate',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // ── Modo Offline ──────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: () => _entrarOffline(context),
                    icon: const Icon(Icons.bolt, color: AppTheme.primary),
                    label: const Text(
                      'Iniciar Modo Offline',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '© 2026 WattGuard. Todos los derechos reservados.',
              style: TextStyle(
                color: AppTheme.textSecondary.withAlpha(150),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
