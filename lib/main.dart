import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/mobile/home_screen.dart';
import 'screens/desktop/desktop_home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/desktop/desktop_login_screen.dart'; // Added import
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'utils/platform_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // Inicializar Supabase con variables de entorno
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Configurar SQLite para desktop (Windows/Linux/macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bases Lab',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 255, 255),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(), // ← Nuevo: Verificador de autenticación
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Widget que verifica si el usuario está autenticado
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showLogoutButton = false;

  @override
  void initState() {
    super.initState();
    // Mostrar botón de logout después de 5 segundos si sigue cargando
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showLogoutButton = true);
      }
    });
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      setState(() => _showLogoutButton = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Mientras carga, mostrar pantalla de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF4DB6AC)),
                  if (_showLogoutButton) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Tomando más tiempo de lo esperado...',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // Verificar si hay sesión activa
        final session = snapshot.hasData ? snapshot.data!.session : null;

        // Si hay sesión → HomeScreen (adaptativo), si no → LoginScreen
        if (session != null) {
          // Routing adaptativo: Desktop o Mobile
          if (PlatformUtils.isDesktop) {
            return const DesktopHomeScreen();
          } else {
            return const HomeScreen();
          }
        } else {
          // Usuario no autenticado - mostrar login según plataforma
          if (PlatformUtils.isDesktop) {
            return const DesktopLoginScreen();
          } else {
            return const LoginScreen();
          }
        }
      },
    );
  }
}
