import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utilidad para detectar la plataforma actual
class PlatformUtils {
  /// Detecta si la app está corriendo en una plataforma desktop
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Detecta si la app está corriendo en una plataforma móvil
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Detecta si la app está corriendo en web
  static bool get isWeb => kIsWeb;

  /// Detecta si está en Windows específicamente
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// Detecta si está en Android específicamente
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// Detecta si está en iOS específicamente
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// Verifica si la pantalla es grande (desktop-like)
  static bool isLargeScreen(double width) => width >= 1024;

  /// Verifica si la pantalla es mediana (tablet-like)
  static bool isMediumScreen(double width) => width >= 600 && width < 1024;

  /// Verifica si la pantalla es pequeña (mobile-like)
  static bool isSmallScreen(double width) => width < 600;
}
