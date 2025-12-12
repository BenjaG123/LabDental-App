class DentalBase {
  final int oa;
  final String doctorName;
  final String patientName;
  final String patientRUT;
  final String action;
  final String observations;
  final DateTime entryDate;
  final DateTime exitDate;
  final int price;

  DentalBase({
    required this.oa,
    required this.doctorName,
    required this.patientName,
    required this.patientRUT,
    required this.action,
    required this.observations,
    required this.entryDate,
    required this.exitDate,
    required this.price,
  });

  // Convertir un objeto DentalBase a un Map
  Map<String, dynamic> toMap() {
    return {
      'oa': oa,
      'doctorName': doctorName,
      'patientName': patientName,
      'patientRUT': patientRUT,
      'action': action,
      'observations': observations,
      'entryDate': entryDate.toIso8601String(),
      'exitDate': exitDate.toIso8601String(),
      'price': price,
    };
  }

  // Crear un objeto DentalBase desde un Map
  factory DentalBase.fromMap(Map<String, dynamic> map) {
    return DentalBase(
      oa: map['oa'],
      doctorName: map['doctorName'],
      patientName: map['patientName'],
      patientRUT: map['patientRUT'],
      action: map['action'],
      observations: map['observations'],
      entryDate: DateTime.parse(map['entryDate']),
      exitDate: DateTime.parse(map['exitDate']),
      price: map['price'],
    );
  }

  // Crear una copia del objeto con algunos campos modificados
  DentalBase copyWith({
    int? oa,
    String? doctorName,
    String? patientName,
    String? patientRUT,
    String? action,
    String? observations,
    DateTime? entryDate,
    DateTime? exitDate,
    int? price,
  }) {
    return DentalBase(
      oa: oa ?? this.oa,
      doctorName: doctorName ?? this.doctorName,
      patientName: patientName ?? this.patientName,
      patientRUT: patientRUT ?? this.patientRUT,
      action: action ?? this.action,
      observations: observations ?? this.observations,
      entryDate: entryDate ?? this.entryDate,
      exitDate: exitDate ?? this.exitDate,
      price: price ?? this.price,
    );
  }
}