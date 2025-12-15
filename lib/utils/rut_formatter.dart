import 'package:flutter/services.dart';

/// Formateador personalizado para RUT chileno
/// Acepta RUTs de 7 u 8 dígitos
/// Formato: X.XXX.XXX-X o XX.XXX.XXX-X
class RutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Eliminar todo excepto dígitos y K
    String text = newValue.text.replaceAll(RegExp(r'[^0-9Kk]'), '');

    // Limitar a 9 caracteres (8 dígitos + 1 verificador)
    if (text.length > 9) {
      text = text.substring(0, 9);
    }

    // Si está vacío, retornar
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Formatear según la longitud
    String formatted = '';

    if (text.length <= 1) {
      formatted = text;
    } else if (text.length <= 4) {
      // Sin puntos aún: "1234" o menos
      formatted = text.substring(0, text.length - 1).isEmpty
          ? text
          : '${text.substring(0, text.length - 1)}.${text.substring(text.length - 1)}';
    } else if (text.length <= 7) {
      // Formato: X.XXX.XXX
      int pos1 = text.length - 4;
      int pos2 = text.length - 1;
      formatted =
          '${text.substring(0, pos1)}.${text.substring(pos1, pos2)}.${text.substring(pos2)}';
    } else {
      // Formato completo con guión: XX.XXX.XXX-X
      int pos1 = text.length - 7;
      int pos2 = text.length - 4;
      int pos3 = text.length - 1;
      formatted =
          '${text.substring(0, pos1)}.${text.substring(pos1, pos2)}.${text.substring(pos2, pos3)}-${text.substring(pos3)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
