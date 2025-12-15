class DentalBaseSheet {
  final int id;
  final int dentalBaseOA;
  final int sheetId;

  DentalBaseSheet({
    required this.id,
    required this.dentalBaseOA,
    required this.sheetId,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'dentalBaseOA': dentalBaseOA, 'sheetId': sheetId};
  }

  factory DentalBaseSheet.fromMap(Map<String, dynamic> map) {
    return DentalBaseSheet(
      id: map['id'],
      dentalBaseOA: map['dentalBaseOA'],
      sheetId: map['sheetId'],
    );
  }
}
