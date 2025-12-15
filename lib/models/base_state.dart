class BaseState {
  final int id;
  final String name;

  const BaseState({required this.id, required this.name});

  // Estados predefinidos (constantes)
  static const BaseState cubeta = BaseState(id: 1, name: 'Cubeta');
  static const BaseState base = BaseState(id: 2, name: 'Base');
  static const BaseState rodete = BaseState(id: 3, name: 'Rodete');
  static const BaseState ordenacion = BaseState(id: 4, name: 'Ordenación');
  static const BaseState terminacion = BaseState(id: 5, name: 'Terminación');
  static const BaseState reparacion = BaseState(id: 6, name: 'Reparación');

  // Lista de todos los estados disponibles
  static const List<BaseState> allStates = [
    cubeta,
    base,
    rodete,
    ordenacion,
    terminacion,
    reparacion,
  ];

  // Obtener estado por ID
  static BaseState getById(int id) {
    return allStates.firstWhere(
      (state) => state.id == id,
      orElse: () => cubeta, // Por defecto retorna cubeta
    );
  }

  // Obtener estado por nombre
  static BaseState? getByName(String name) {
    try {
      return allStates.firstWhere((state) => state.name == name);
    } catch (e) {
      return null;
    }
  }

  // Convertir a Map (para guardar en BD)
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  // Crear desde Map (para leer de BD)
  factory BaseState.fromMap(Map<String, dynamic> map) {
    return BaseState(id: map['id'], name: map['name']);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseState && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}
