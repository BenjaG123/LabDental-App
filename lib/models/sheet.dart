class Sheet {
  final String id; // Changed from int to String to store UUID
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
      // Supabase devuelve UUID como string
      id: map['id'].toString(),
      month: map['month'],
      year: map['year'],
      creationDate: DateTime.parse(map['creation_date'] ?? map['creationDate']),
    );
  }

  Sheet copyWith({String? id, int? month, int? year, DateTime? creationDate}) {
    return Sheet(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      creationDate: creationDate ?? this.creationDate,
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
