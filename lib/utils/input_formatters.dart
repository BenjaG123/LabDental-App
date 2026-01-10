import 'package:flutter/services.dart';

/// Formatter that capitalizes the first letter of each word
class NameCapitalizationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only capitalize when text is being finalized (not while typing)
    // This will be triggered on focus change
    return newValue;
  }

  /// Static method to capitalize a string
  static String capitalize(String text) {
    if (text.isEmpty) return text;

    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

/// Formatter for price input with thousand separators
class PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    // Format with thousand separators
    String formatted = _formatWithThousands(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithThousands(String number) {
    // Reverse the string to make it easier to add dots
    String reversed = number.split('').reversed.join('');

    // Add dots every 3 digits
    String formatted = '';
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted += '.';
      }
      formatted += reversed[i];
    }

    // Reverse back
    return formatted.split('').reversed.join('');
  }

  /// Static method to get raw integer value from formatted string
  static int? getRawValue(String formatted) {
    String digitsOnly = formatted.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.isEmpty ? null : int.tryParse(digitsOnly);
  }

  /// Static method to format an integer with thousand separators
  static String formatPrice(int? price) {
    if (price == null || price == 0) return '0';

    String number = price.toString();
    String reversed = number.split('').reversed.join('');

    String formatted = '';
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted += '.';
      }
      formatted += reversed[i];
    }

    return formatted.split('').reversed.join('');
  }
}
