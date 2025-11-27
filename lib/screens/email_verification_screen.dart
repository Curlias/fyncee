import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../theme.dart';
import 'home_page.dart';
import 'login_screen.dart';

/// Pantalla de verificación de email
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  
  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  bool _isCheckingVerification = false;
  bool _canResend = true;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    // Verificar automáticamente cada 5 segundos
    _startAutoCheck();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }

  void _startAutoCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkEmailVerification(showMessage: false);
    });
  }

  Future<void> _checkEmailVerification({bool showMessage = true}) async {
    if (_isCheckingVerification) return;

    setState(() => _isCheckingVerification = true);

    try {
      // Recargar el usuario actual para obtener el estado actualizado
      await _authService.refreshSession();
      
      final user = _authService.currentUser;
      
      if (user != null && user.emailConfirmedAt != null) {
        // Email verificado - navegar a la app
        _checkTimer?.cancel();
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        }
      } else if (showMessage) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El email aún no ha sido verificado'),
              backgroundColor: FynceeColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar: ${e.toString()}'),
            backgroundColor: FynceeColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingVerification = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    try {
      await _authService.resendVerificationEmail();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de verificación enviado'),
            backgroundColor: FynceeColors.incomeGreen,
          ),
        );

        // Iniciar countdown de 60 segundos
        setState(() {
          _canResend = false;
          _resendCountdown = 60;
        });

        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _resendCountdown--;
            if (_resendCountdown <= 0) {
              _canResend = true;
              timer.cancel();
            }
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: FynceeColors.error,
          ),
        );
      }
    }
  }

  Future<void> _changeEmail() async {
    // Cerrar sesión y volver al login
    await _authService.signOut();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FynceeColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: FynceeColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 60,
                    color: FynceeColors.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // Título
                const Text(
                  'Verifica tu email',
                  style: TextStyle(
                    color: FynceeColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Descripción
                Text(
                  'Hemos enviado un correo de verificación a:',
                  style: TextStyle(
                    color: FynceeColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  widget.email,
                  style: const TextStyle(
                    color: FynceeColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Instrucciones
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: FynceeColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildStep(
                        '1',
                        'Abre tu correo electrónico',
                        Icons.mail_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildStep(
                        '2',
                        'Busca el email de Fyncee',
                        Icons.search,
                      ),
                      const SizedBox(height: 16),
                      _buildStep(
                        '3',
                        'Haz clic en el enlace de verificación',
                        Icons.link,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Botón verificar manualmente
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCheckingVerification
                        ? null
                        : () => _checkEmailVerification(showMessage: true),
                    icon: _isCheckingVerification
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      _isCheckingVerification
                          ? 'Verificando...'
                          : 'Ya verifiqué mi email',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FynceeColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Botón reenviar
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _canResend ? _resendVerificationEmail : null,
                    icon: const Icon(Icons.send),
                    label: Text(
                      _canResend
                          ? 'Reenviar email'
                          : 'Reenviar en ${_resendCountdown}s',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FynceeColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Ayuda
                Text(
                  '¿No recibiste el email?',
                  style: TextStyle(
                    color: FynceeColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisa tu carpeta de spam o correo no deseado',
                  style: TextStyle(
                    color: FynceeColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Cambiar email
                TextButton(
                  onPressed: _changeEmail,
                  child: const Text(
                    'Usar otro email',
                    style: TextStyle(
                      color: FynceeColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: FynceeColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: FynceeColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: FynceeColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
        Icon(
          icon,
          color: FynceeColors.textSecondary.withValues(alpha: 0.5),
          size: 20,
        ),
      ],
    );
  }
}
