import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/biometric_auth_service.dart';
import '../theme.dart';

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  
  const BiometricLockScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final BiometricAuthService _bioAuth = BiometricAuthService();
  final TextEditingController _pinController = TextEditingController();
  bool _showPinInput = false;
  bool _isAuthenticating = false;
  String _pin = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _attemptBiometricAuth();
  }

  Future<void> _attemptBiometricAuth() async {
    if (_isAuthenticating) return;
    
    if (!mounted) return;
    setState(() => _isAuthenticating = true);
    
    final biometricEnabled = await _bioAuth.isBiometricEnabled();
    
    if (biometricEnabled) {
      final canUse = await _bioAuth.canUseBiometrics();
      if (canUse) {
        final authenticated = await _bioAuth.authenticateWithBiometrics(
          reason: 'Autentícate para abrir Fyncee',
        );
        
        if (authenticated) {
          if (mounted) {
            widget.onAuthenticated();
          }
          return;
        }
      }
    }
    
    // Si falló la biometría, verificar si hay PIN configurado
    final hasPin = await _bioAuth.hasPin();
    
    if (hasPin) {
      // Mostrar teclado PIN
      if (!mounted) return;
      setState(() {
        _showPinInput = true;
        _isAuthenticating = false;
      });
    } else {
      // No hay PIN configurado, permitir acceso
      // (la biometría era la única opción y falló/canceló)
      if (mounted) {
        widget.onAuthenticated();
      }
    }
  }

  void _onPinDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _errorMessage = '';
      });
      
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onPinBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _verifyPin() async {
    final isValid = await _bioAuth.verifyPin(_pin);
    
    if (isValid) {
      if (mounted) {
        widget.onAuthenticated();
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = 'PIN incorrecto';
          _pin = '';
        });
        
        // Vibración de error
        HapticFeedback.vibrate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FynceeColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo oficial de Fyncee
            Image.asset(
              'assets/images/fyncee_logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            
            // Título
            const Text(
              'Fyncee',
              style: TextStyle(
                color: FynceeColors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            
            Center(
              child: Text(
                _showPinInput ? 'Ingresa tu PIN' : 'Autenticándote...',
                style: TextStyle(
                  color: FynceeColors.textSecondary.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 48),
            
            if (_showPinInput) ...[
              // Indicadores de PIN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length
                          ? FynceeColors.primary
                          : FynceeColors.surface,
                      border: Border.all(
                        color: FynceeColors.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              
              // Mensaje de error
              SizedBox(
                height: 24,
                child: _errorMessage.isNotEmpty
                    ? Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: FynceeColors.error,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 32),
              
              // Teclado numérico
              _buildNumericKeypad(),
              const SizedBox(height: 24),
              
              // Botón de biometría (si está disponible)
              FutureBuilder<bool>(
                future: _bioAuth.isBiometricEnabled(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return TextButton.icon(
                      onPressed: _attemptBiometricAuth,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Usar biometría'),
                      style: TextButton.styleFrom(
                        foregroundColor: FynceeColors.primary,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ] else ...[
              const CircularProgressIndicator(
                color: FynceeColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildKeypadRow(['', '0', '⌫']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) {
        if (digit.isEmpty) {
          return const SizedBox(width: 72, height: 72);
        }
        
        return InkWell(
          onTap: () {
            if (digit == '⌫') {
              _onPinBackspace();
            } else {
              _onPinDigit(digit);
            }
            HapticFeedback.selectionClick();
          },
          borderRadius: BorderRadius.circular(36),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FynceeColors.surface,
            ),
            child: Center(
              child: Text(
                digit,
                style: const TextStyle(
                  color: FynceeColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
