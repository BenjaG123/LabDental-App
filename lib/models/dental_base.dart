class DentalBase {
  final int? id;
  final String patientName;
  final String baseType;
  final DateTime creationDate;
  final DateTime? deliveryDate;
  final String status;
  final String? notes;

  DentalBase({
    this.id,
    required this.patientName,
    required this.baseType,
    required this.creationDate,
    this.deliveryDate,
    required this.status,
    this.notes,
  });

  // Convertir un objeto DentalBase a un Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'baseType': baseType,
      'creationDate': creationDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  // Crear un objeto DentalBase desde un Map
  factory DentalBase.fromMap(Map<String, dynamic> map) {
    return DentalBase(
      id: map['id'],
      patientName: map['patientName'],
      baseType: map['baseType'],
      creationDate: DateTime.parse(map['creationDate']),
      deliveryDate: map['deliveryDate'] != null ? DateTime.parse(map['deliveryDate']) : null,
      status: map['status'],
      notes: map['notes'],
    );
  }

  // Crear una copia del objeto con algunos campos modificados
  DentalBase copyWith({
    int? id,
    String? patientName,
    String? baseType,
    DateTime? creationDate,
    DateTime? deliveryDate,
    String? status,
    String? notes,
  }) {
    return DentalBase(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      baseType: baseType ?? this.baseType,
      creationDate: creationDate ?? this.creationDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}