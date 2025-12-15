class Sheet {
  final int id;
  final int month;
  final int year;
  final DateTime creationDate;

  Sheet({
    required this.id,
    required this.month,
    required this.year,
    required this.creationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'creationDate': creationDate.toIso8601String(),
    };
  }

  factory Sheet.fromMap(Map<String, dynamic> map) {
    return Sheet(
      id: map['id'],
      month: map['month'],
      year: map['year'],
      creationDate: DateTime.parse(map['creationDate']),
    );
  }

  // Obtener nombre formateado de la hoja (ej: "Enero 2026")
  String getSheetName() {
    return _getMonthName(month) + ' $year';
  }

  // Método estático para generar nombre desde una fecha
  static String getSheetNameFromDate(DateTime date) {
    return _getMonthName(date.month) + ' ${date.year}';
  }

  // Convertir número de mes a nombre en español
  static String _getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }
}
