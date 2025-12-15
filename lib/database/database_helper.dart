import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dental_base.dart';
import '../models/sheet.dart';
import '../services/laboratory_service.dart';

/// DatabaseHelper migrado a Supabase
/// Mantiene la misma interfaz pero usa la nube en lugar de SQLite local
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final SupabaseClient _supabase = Supabase.instance.client;
  final LaboratoryService _laboratoryService = LaboratoryService();

  DatabaseHelper._init();

  /// Obtener laboratory_id del usuario actual
  Future<String?> get _currentLaboratoryId async {
    final profile = await _laboratoryService.getCurrentUserProfile();
    return profile?['laboratory_id'];
  }

  // ==================== DENTAL BASES ====================

  /// Insertar una nueva base dental
  Future<int> insertDentalBase(DentalBase dentalBase) async {
    final labId = await _currentLaboratoryId;
    if (labId == null) throw Exception('Usuario no tiene laboratorio asignado');

    await _supabase.from('dental_bases').insert({
      'oa': dentalBase.oa,
      'laboratory_id': labId,
      'doctor_name': dentalBase.doctorName,
      'patient_name': dentalBase.patientName,
      'patient_rut': dentalBase.patientRUT,
      'action': dentalBase.action,
      'observations': dentalBase.observations,
      'entry_date': dentalBase.entryDate.toIso8601String(),
      'exit_date': dentalBase.exitDate.toIso8601String(),
      'price': dentalBase.price,
      'estado_id': dentalBase.estado.id,
    });

    return dentalBase.oa;
  }

  /// Obtener todas las bases dentales del laboratorio actual
  Future<List<DentalBase>> getAllDentalBases() async {
    final labId = await _currentLaboratoryId;
    if (labId == null) return [];

    final response = await _supabase
        .from('dental_bases')
        .select()
        .eq('laboratory_id', labId)
        .order('oa', ascending: false);

    return (response as List).map((map) => DentalBase.fromMap(map)).toList();
  }

  /// Obtener una base dental por OA
  Future<DentalBase?> getDentalBase(int oa) async {
    final labId = await _currentLaboratoryId;
    if (labId == null) return null;

    final response = await _supabase
        .from('dental_bases')
        .select()
        .eq('oa', oa)
        .eq('laboratory_id', labId)
        .maybeSingle();

    if (response == null) return null;
    return DentalBase.fromMap(response);
  }

  /// Actualizar una base dental
  Future<int> updateDentalBase(DentalBase dentalBase) async {
    final labId = await _currentLaboratoryId;
    if (labId == null) throw Exception('Usuario no tiene laboratorio asignado');

    await _supabase
        .from('dental_bases')
        .update({
          'doctor_name': dentalBase.doctorName,
          'patient_name': dentalBase.patientName,
          'patient_rut': dentalBase.patientRUT,
          'action': dentalBase.action,
          'observations': dentalBase.observations,
          'entry_date': dentalBase.entryDate.toIso8601String(),
          'exit_date': dentalBase.exitDate.toIso8601String(),
          'price': dentalBase.price,
          'estado_id': dentalBase.estado.id,
        })
        .eq('oa', dentalBase.oa)
        .eq('laboratory_id', labId);

    return dentalBase.oa;
  }

  /// Eliminar una base dental
  Future<int> deleteDentalBase(int oa) async {
    final labId = await _currentLaboratoryId;
    if (labId == null) throw Exception('Usuario no tiene laboratorio asignado');

    await _supabase
        .from('dental_bases')
        .delete()
        .eq('oa', oa)
        .eq('laboratory_id', labId);

    return oa;
  }

  // ==================== SHEETS ====================

  /// Insertar una nueva hoja
  Future<int> insertSheet(Sheet sheet) async {
    final labId = await _currentLaboratoryId;
    if (labId == null) throw Exception('Usuario no tiene laboratorio asignado');

    final response = await _supabase
        .from('sheets')
        .insert({
          'laboratory_id': labId,
          'month': sheet.month,
          'year': sheet.year,
          'creation_date': sheet.creationDate.toIso8601String(),
        })
        .select()
        .single();

    return response['id'].hashCode; // Convertir UUID a int para compatibilidad
  }

  /// Obtener una hoja por ID
  Future<Sheet?> getSheet(int id) async {
    final labId = await _currentLaboratoryId;
    if (labId == null) return null;

    final response = await _supabase
        .from('sheets')
        .select()
        .eq('laboratory_id', labId)
        .maybeSingle();

    if (response == null) return null;
    return Sheet.fromMap(response);
  }

  /// Obtener hoja por mes y año
  Future<Sheet?> getSheetByMonthYear(int month, int year) async {
    final labId = await _currentLaboratoryId;
    if (labId == null) return null;

    final response = await _supabase
        .from('sheets')
        .select()
        .eq('laboratory_id', labId)
        .eq('month', month)
        .eq('year', year)
        .maybeSingle();

    if (response == null) return null;
    return Sheet.fromMap(response);
  }

  /// Obtener todas las hojas del laboratorio
  Future<List<Sheet>> getAllSheets() async {
    final labId = await _currentLaboratoryId;
    if (labId == null) return [];

    final response = await _supabase
        .from('sheets')
        .select()
        .eq('laboratory_id', labId)
        .order('year', ascending: false)
        .order('month', ascending: false);

    return (response as List).map((map) => Sheet.fromMap(map)).toList();
  }

  /// Eliminar una hoja
  Future<int> deleteSheet(int id) async {
    final labId = await _currentLaboratoryId;
    if (labId == null) throw Exception('Usuario no tiene laboratorio asignado');

    await _supabase.from('sheets').delete().eq('laboratory_id', labId);

    return id;
  }

  // ==================== RELACIÓN BASES-HOJAS ====================

  /// Vincular una base dental a una hoja
  Future<void> linkDentalBaseToSheet(int dentalBaseOA, int sheetId) async {
    final labId = await _currentLaboratoryId;
    if (labId == null) throw Exception('Usuario no tiene laboratorio asignado');

    // Obtener el UUID real del sheet
    final sheetResponse = await _supabase
        .from('sheets')
        .select('id')
        .eq('laboratory_id', labId)
        .single();

    final sheetUuid = sheetResponse['id'];

    await _supabase.from('dental_base_sheets').insert({
      'dental_base_oa': dentalBaseOA,
      'dental_base_lab_id': labId,
      'sheet_id': sheetUuid,
    });
  }

  /// Obtener bases dentales de una hoja con paginación y filtros
  Future<List<DentalBase>> getDentalBasesBySheet(
    int sheetId, {
    int? limit,
    int? offset,
    bool onlyPending = false,
  }) async {
    final labId = await _currentLaboratoryId;
    if (labId == null) return [];

    // Primero obtener el UUID del sheet
    final sheetResponse = await _supabase
        .from('sheets')
        .select('id')
        .eq('laboratory_id', labId)
        .single();

    final sheetUuid = sheetResponse['id'];

    // Obtener las bases vinculadas
    final linksResponse = await _supabase
        .from('dental_base_sheets')
        .select('dental_base_oa')
        .eq('sheet_id', sheetUuid);

    final oaList = (linksResponse as List)
        .map((link) => link['dental_base_oa'])
        .toList();

    if (oaList.isEmpty) return [];

    // Construir query con paginación
    var query = _supabase
        .from('dental_bases')
        .select('''
          *,
          estado:estados(*)
        ''')
        .eq('laboratory_id', labId)
        .inFilter('oa', oaList)
        .order('oa', ascending: false);

    // Aplicar paginación si se especifica
    if (limit != null) {
      query = query.limit(limit);
      if (offset != null) {
        query = query.range(offset, offset + limit - 1);
      }
    }

    final basesResponse = await query;

    List<DentalBase> bases = (basesResponse as List)
        .map((map) => DentalBase.fromMap(map))
        .toList();

    // Filtrar solo pendientes si se solicita (estado.id != 5)
    if (onlyPending) {
      bases = bases.where((base) => base.estado.id != 5).toList();
    }

    return bases;
  }

  /// Obtener hoja de una base dental
  Future<Sheet?> getSheetForDentalBase(int dentalBaseOA) async {
    final labId = await _currentLaboratoryId;
    if (labId == null) return null;

    final linkResponse = await _supabase
        .from('dental_base_sheets')
        .select('sheet_id')
        .eq('dental_base_oa', dentalBaseOA)
        .eq('dental_base_lab_id', labId)
        .maybeSingle();

    if (linkResponse == null) return null;

    final sheetUuid = linkResponse['sheet_id'];

    final sheetResponse = await _supabase
        .from('sheets')
        .select()
        .eq('id', sheetUuid)
        .eq('laboratory_id', labId)
        .maybeSingle();

    if (sheetResponse == null) return null;
    return Sheet.fromMap(sheetResponse);
  }

  /// Obtener o crear hoja para una fecha
  Future<Sheet> getOrCreateSheetForDate(DateTime exitDate) async {
    final month = exitDate.month;
    final year = exitDate.year;

    // Intentar obtener hoja existente
    Sheet? existingSheet = await getSheetByMonthYear(month, year);

    if (existingSheet != null) {
      return existingSheet;
    }

    // Crear nueva hoja
    final newSheet = Sheet(
      id: 0, // Se generará en Supabase
      month: month,
      year: year,
      creationDate: DateTime.now(),
    );

    final id = await insertSheet(newSheet);
    return newSheet.copyWith(id: id);
  }

  /// Contar bases en una hoja
  Future<int> countBasesInSheet(int sheetId) async {
    final bases = await getDentalBasesBySheet(sheetId);
    return bases.length;
  }

  /// Obtener precio total de una hoja (solo bases en Terminación)
  Future<int> getTotalPriceInSheet(int sheetId) async {
    final bases = await getDentalBasesBySheet(sheetId);
    int total = 0;
    for (var base in bases) {
      // Solo sumar si está en estado "Terminación" (id = 5)
      if (base.estado.id == 5) {
        total += base.price;
      }
    }
    return total;
  }

  /// Cerrar conexión (no necesario en Supabase, pero mantenemos compatibilidad)
  Future<void> close() async {
    // No se necesita cerrar conexión con Supabase
    return;
  }
}
