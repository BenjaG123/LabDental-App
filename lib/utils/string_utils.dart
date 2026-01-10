/// Capitaliza cada palabra de un string.
/// Ejemplo: "juan pérez" -> "Juan Pérez"
String capitalizeWords(String text) {
  if (text.isEmpty) return text;

  return text
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
}

/// Capitaliza solo la primera letra del string completo.
/// Ejemplo: "juan pérez" -> "Juan pérez"
String capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}
