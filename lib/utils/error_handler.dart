/// Utilidad para manejar y parsear errores de forma amigable
class ErrorHandler {
  /// Parsear errores de autenticación de Supabase
  static String parseAuthError(dynamic error) {
    final errorMsg = error.toString().toLowerCase();

    // Credenciales inválidas
    if (errorMsg.contains('invalid login credentials') ||
        errorMsg.contains('invalid email or password')) {
      return 'Correo o contraseña incorrectos';
    }

    // Usuario no encontrado
    if (errorMsg.contains('user not found')) {
      return 'Usuario no encontrado';
    }

    // Email ya registrado
    if (errorMsg.contains('user already registered') ||
        errorMsg.contains('email already exists')) {
      return 'Este email ya está registrado';
    }

    // Contraseña muy débil
    if (errorMsg.contains('password') && errorMsg.contains('weak')) {
      return 'La contraseña es muy débil. Usa al menos 6 caracteres';
    }

    // Email inválido
    if (errorMsg.contains('invalid email')) {
      return 'El formato del email es inválido';
    }

    // Cuenta deshabilitada
    if (errorMsg.contains('account disabled') ||
        errorMsg.contains('user disabled')) {
      return 'Esta cuenta ha sido deshabilitada';
    }

    // Error de red
    if (errorMsg.contains('network') ||
        errorMsg.contains('connection') ||
        errorMsg.contains('timeout')) {
      return 'Sin conexión a internet. Verifica tu conexión';
    }

    // Error genérico
    return 'Error de autenticación. Intenta de nuevo';
  }

  /// Parsear errores de base de datos (PostgreSQL/Supabase)
  static String parseDatabaseError(dynamic error) {
    final errorMsg = error.toString().toLowerCase();

    // Violación de clave única (duplicate)
    if (errorMsg.contains('23505') ||
        errorMsg.contains('unique constraint') ||
        errorMsg.contains('duplicate key')) {
      return 'Este registro ya existe en la base de datos';
    }

    // Violación de clave foránea
    if (errorMsg.contains('23503') ||
        errorMsg.contains('foreign key constraint')) {
      return 'No se puede eliminar: hay datos relacionados';
    }

    // Violación de restricción NOT NULL
    if (errorMsg.contains('23502') || errorMsg.contains('not null')) {
      return 'Falta información requerida';
    }

    // Timeout
    if (errorMsg.contains('timeout')) {
      return 'Tiempo de espera agotado. Intenta de nuevo';
    }

    // Permisos insuficientes
    if (errorMsg.contains('permission denied') ||
        errorMsg.contains('insufficient privileges')) {
      return 'No tienes permisos para realizar esta acción';
    }

    // Error de conexión
    if (errorMsg.contains('connection') || errorMsg.contains('network')) {
      return 'Error de conexión. Verifica tu internet';
    }

    return 'Error en la base de datos. Intenta de nuevo';
  }

  /// Parsear errores específicos de Supabase
  static String parseSupabaseError(dynamic error) {
    final errorMsg = error.toString();

    // PGRST116 - Query devolvió múltiples resultados
    if (errorMsg.contains('PGRST116')) {
      return 'Error interno: datos inconsistentes';
    }

    // PGRST301 - Sin permiso
    if (errorMsg.contains('PGRST301')) {
      return 'No tienes permiso para acceder a este recurso';
    }

    // Primero intentar parsear como error de DB
    if (errorMsg.contains('23')) {
      // Códigos de PostgreSQL empiezan con números
      return parseDatabaseError(error);
    }

    return 'Error del servidor. Intenta más tarde';
  }

  /// Parsear errores de validación de laboratorios
  static String parseLaboratoryError(dynamic error) {
    final errorMsg = error.toString().toLowerCase();

    if (errorMsg.contains('código de invitación inválido')) {
      return 'El código de invitación no existe o es inválido';
    }

    if (errorMsg.contains('laboratorio no encontrado')) {
      return 'No se encontró el laboratorio';
    }

    return parseSupabaseError(error);
  }

  /// Mensaje de error amigable genérico
  static String getFriendlyError(dynamic error) {
    if (error == null) return 'Error desconocido';

    final errorMsg = error.toString().toLowerCase();

    // Intentar parsear por tipo
    if (errorMsg.contains('auth') || errorMsg.contains('login')) {
      return parseAuthError(error);
    }

    if (errorMsg.contains('database') ||
        errorMsg.contains('postgres') ||
        errorMsg.contains('23')) {
      return parseDatabaseError(error);
    }

    if (errorMsg.contains('pgrst')) {
      return parseSupabaseError(error);
    }

    // Default
    return 'Ocurrió un error inesperado';
  }
}
