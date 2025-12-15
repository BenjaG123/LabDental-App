import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio de autenticación con Supabase
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Usuario actual autenticado
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Verificar si hay un usuario autenticado
  bool get isAuthenticated => currentUser != null;

  /// Registrar nuevo usuario con email y contraseña
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  /// Iniciar sesión con email y contraseña
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Obtener ID del usuario actual
  String? get currentUserId => currentUser?.id;

  /// Obtener email del usuario actual
  String? get currentUserEmail => currentUser?.email;
}
