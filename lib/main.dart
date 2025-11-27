import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

import 'screens/home_page.dart';
import 'screens/login_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/biometric_lock_screen.dart';
import 'services/database_service.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'supabase_config.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicios
  await DatabaseService().init(); // Inicializa Hive (caché local)
  
  // Inicializar Supabase (base de datos en la nube)
  if (SupabaseConfig.isConfigured) {
    try {
      await SupabaseService().init(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.supabaseAnonKey,
      );
      print('✅ Supabase conectado - sincronización cloud habilitada');
    } catch (e) {
      print('⚠️ Supabase no disponible: $e');
      print('ℹ️ La app funcionará solo con almacenamiento local');
    }
  } else {
    print('ℹ️ Supabase no configurado - ver lib/supabase_config.dart');
    print('ℹ️ La app funcionará solo con almacenamiento local');
  }
  
  // Inicializar notificaciones (solo en plataformas compatibles)
  // Comentado temporalmente para evitar crashes en Android
  // try {
  //   await NotificationService().initialize();
  //   await NotificationService().requestPermissions();
  // } catch (e) {
  //   print('⚠️ Notificaciones no disponibles en esta plataforma: $e');
  // }
  
  // Inicializar localización
  await initializeDateFormatting('es_MX');
  Intl.defaultLocale = Intl.defaultLocale ?? 'es_MX';
  
  runApp(const FynceeApp());
}

class FynceeApp extends StatefulWidget {
  const FynceeApp({super.key});

  @override
  State<FynceeApp> createState() => _FynceeAppState();
  
  static _FynceeAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_FynceeAppState>();
  }
}

class _FynceeAppState extends State<FynceeApp> {
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await ThemeService().isDarkMode();
    setState(() {
      _isDarkMode = isDark;
    });
  }

  void toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await ThemeService().setDarkMode(_isDarkMode);
  }

  void setTheme(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });
    await ThemeService().setDarkMode(isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fyncee',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? FynceeTheme.darkTheme : FynceeTheme.lightTheme,
      home: const AuthChecker(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
      },
      onGenerateRoute: (settings) {
        // Ruta dinámica para verificación de email
        if (settings.name == '/verify-email') {
          final user = AuthService().currentUser;
          if (user != null && user.email != null) {
            return MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                email: user.email!,
              ),
            );
          }
        }
        return null;
      },
    );
  }
}

// Widget para verificar la sesión al inicio
class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool _biometricChecked = false;
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _setupDeepLinkListener();
    _checkAuth();
  }

  // Configurar listener para deep links (verificación de email, etc.)
  void _setupDeepLinkListener() async {
    _appLinks = AppLinks();
    
    // Manejar deep link inicial (si la app se abrió con un link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }
    
    // Escuchar deep links mientras la app está abierta
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      print('Error handling deep link: $err');
    });
  }

  // Manejar el deep link recibido
  void _handleDeepLink(Uri uri) {
    print('Deep link recibido: $uri');
    
    // Parsear el fragment para extraer el mensaje
    final fragment = uri.fragment;
    final queryParams = Uri.splitQueryString(fragment);
    final message = queryParams['message'];
    
    // Verificar si es un mensaje de confirmación de cambio de email
    if (message != null && message.contains('Confirmation link accepted')) {
      print('✅ Primer paso de cambio de email completado');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Confirmación recibida. Revisa el correo nuevo para completar el cambio.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }
    
    // Intentar procesar como sesión de autenticación normal
    if (fragment.isNotEmpty && (fragment.contains('access_token') || fragment.contains('refresh_token'))) {
      Supabase.instance.client.auth.getSessionFromUrl(uri).then((response) {
        print('✅ Sesión actualizada desde deep link');
        
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Email verificado correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }).catchError((error) {
        print('Error procesando deep link: $error');
      });
    }
  }

  // Escuchar cambios en la autenticación (incluyendo OAuth callbacks)
  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // Usuario inició sesión exitosamente (incluyendo con Google)
        print('✅ Usuario autenticado: ${data.session?.user.email}');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    });
  }

  Future<void> _checkAuth() async {
    // Esperar un momento para que Supabase inicialice
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // Verificar si hay sesión activa
    final isAuth = AuthService().isAuthenticated;
    final user = AuthService().currentUser;
    
    if (isAuth && user != null) {
      // Verificar si el email está confirmado
      if (user.emailConfirmedAt == null) {
        // Email no verificado - ir a pantalla de verificación
        Navigator.of(context).pushReplacementNamed('/verify-email');
      } else {
        // Email verificado - verificar si necesita autenticación biométrica
        final bioService = BiometricAuthService();
        final requiresAuth = await bioService.requiresAuthOnStartup();
        
        if (requiresAuth && !_biometricChecked) {
          // Mostrar pantalla de bloqueo biométrico
          if (!mounted) return;
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BiometricLockScreen(
                onAuthenticated: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ),
          );
          
          if (result == true && mounted) {
            setState(() => _biometricChecked = true);
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          // No requiere autenticación o ya pasó - ir a home
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } else {
      // No hay sesión - ir a login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: FynceeColors.background,
      body: Center(
        child: CircularProgressIndicator(
          color: FynceeColors.primary,
        ),
      ),
    );
  }
}
