import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/dental_base.dart';
import '../models/sheet.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dental_bases.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS dental_bases');
      await _createDB(db, newVersion);
    }
    if (oldVersion < 4) {
      // Crear las nuevas tablas sheets y dental_base_sheets
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sheets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          creationDate TEXT NOT NULL,
          UNIQUE(month, year)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS dental_base_sheets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          dentalBaseOA INTEGER NOT NULL,
          sheetId INTEGER NOT NULL,
          FOREIGN KEY (dentalBaseOA) REFERENCES dental_bases (oa) ON DELETE CASCADE,
          FOREIGN KEY (sheetId) REFERENCES sheets (id) ON DELETE CASCADE,
          UNIQUE(dentalBaseOA)
        )
      ''');

      // Agregar estadoId solo si viene de versión < 4
      await db.execute(
        'ALTER TABLE dental_bases ADD COLUMN estadoId INTEGER NOT NULL DEFAULT 1',
      );
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dental_bases(
        oa INTEGER PRIMARY KEY,
        doctorName TEXT NOT NULL,
        patientName TEXT NOT NULL,
        patientRUT TEXT NOT NULL,
        action TEXT NOT NULL,
        observations TEXT NOT NULL,
        entryDate TEXT NOT NULL,
        exitDate TEXT NOT NULL,
        price INTEGER NOT NULL,
        estadoId INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Crear tablas para sheets si estamos en versión 3
    if (version >= 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sheets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          creationDate TEXT NOT NULL,
          UNIQUE(month, year)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS dental_base_sheets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          dentalBaseOA INTEGER NOT NULL,
          sheetId INTEGER NOT NULL,
          FOREIGN KEY (dentalBaseOA) REFERENCES dental_bases (oa) ON DELETE CASCADE,
          FOREIGN KEY (sheetId) REFERENCES sheets (id) ON DELETE CASCADE,
          UNIQUE(dentalBaseOA)
        )
      ''');
    }
  }

  // ==================== DENTAL BASES CRUD ====================

  // Create
  Future<int> insertDentalBase(DentalBase dentalBase) async {
    final db = await instance.database;
    return await db.insert('dental_bases', dentalBase.toMap());
  }

  // Read
  Future<List<DentalBase>> getAllDentalBases() async {
    final db = await instance.database;
    final result = await db.query('dental_bases');
    return result.map((map) => DentalBase.fromMap(map)).toList();
  }

  Future<DentalBase?> getDentalBase(int oa) async {
    final db = await instance.database;
    final maps = await db.query(
      'dental_bases',
      where: 'oa = ?',
      whereArgs: [oa],
    );

    if (maps.isNotEmpty) {
      return DentalBase.fromMap(maps.first);
    }
    return null;
  }

  // Update
  Future<int> updateDentalBase(DentalBase dentalBase) async {
    final db = await instance.database;
    return await db.update(
      'dental_bases',
      dentalBase.toMap(),
      where: 'oa = ?',
      whereArgs: [dentalBase.oa],
    );
  }

  // Delete
  Future<int> deleteDentalBase(int oa) async {
    final db = await instance.database;
    return await db.delete('dental_bases', where: 'oa = ?', whereArgs: [oa]);
  }

  // ==================== SHEETS CRUD ====================

  // Create
  Future<int> insertSheet(Sheet sheet) async {
    final db = await instance.database;
    return await db.insert('sheets', sheet.toMap());
  }

  // Read
  Future<Sheet?> getSheet(int id) async {
    final db = await instance.database;
    final maps = await db.query('sheets', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Sheet.fromMap(maps.first);
    }
    return null;
  }

  Future<Sheet?> getSheetByMonthYear(int month, int year) async {
    final db = await instance.database;
    final maps = await db.query(
      'sheets',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );

    if (maps.isNotEmpty) {
      return Sheet.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Sheet>> getAllSheets() async {
    final db = await instance.database;
    final result = await db.query('sheets', orderBy: 'year DESC, month DESC');
    return result.map((map) => Sheet.fromMap(map)).toList();
  }

  // Delete
  Future<int> deleteSheet(int id) async {
    final db = await instance.database;
    return await db.delete('sheets', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== RELACIONES ====================

  // Vincular base dental a hoja
  Future<void> linkDentalBaseToSheet(int dentalBaseOA, int sheetId) async {
    final db = await instance.database;

    // Primero eliminar cualquier vinculación anterior
    await db.delete(
      'dental_base_sheets',
      where: 'dentalBaseOA = ?',
      whereArgs: [dentalBaseOA],
    );

    // Insertar nueva vinculación
    await db.insert('dental_base_sheets', {
      'dentalBaseOA': dentalBaseOA,
      'sheetId': sheetId,
    });
  }

  // Obtener todas las bases dentales de una hoja
  Future<List<DentalBase>> getDentalBasesBySheet(int sheetId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT db.* FROM dental_bases db
      INNER JOIN dental_base_sheets dbs ON db.oa = dbs.dentalBaseOA
      WHERE dbs.sheetId = ?
      ORDER BY db.exitDate DESC
    ''',
      [sheetId],
    );

    return result.map((map) => DentalBase.fromMap(map)).toList();
  }

  // Obtener la hoja de una base dental
  Future<Sheet?> getSheetForDentalBase(int dentalBaseOA) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT s.* FROM sheets s
      INNER JOIN dental_base_sheets dbs ON s.id = dbs.sheetId
      WHERE dbs.dentalBaseOA = ?
    ''',
      [dentalBaseOA],
    );

    if (result.isNotEmpty) {
      return Sheet.fromMap(result.first);
    }
    return null;
  }

  // ==================== LÓGICA DE AUTO-CREACIÓN ====================

  // Obtener o crear hoja para una fecha (usando exitDate)
  Future<Sheet> getOrCreateSheetForDate(DateTime exitDate) async {
    final month = exitDate.month;
    final year = exitDate.year;

    // Buscar si existe hoja para ese mes/año
    Sheet? existingSheet = await getSheetByMonthYear(month, year);

    if (existingSheet != null) {
      return existingSheet;
    }

    // No existe, crear nueva hoja
    final db = await instance.database;
    final newSheetId = await db.insert('sheets', {
      'month': month,
      'year': year,
      'creationDate': DateTime.now().toIso8601String(),
    });

    // Retornar la hoja recién creada
    return Sheet(
      id: newSheetId,
      month: month,
      year: year,
      creationDate: DateTime.now(),
    );
  }

  // Contar bases en una hoja
  Future<int> countBasesInSheet(int sheetId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM dental_base_sheets
      WHERE sheetId = ?
    ''',
      [sheetId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Obtener suma total de precios en una hoja
  Future<int> getTotalPriceInSheet(int sheetId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(db.price) as total FROM dental_bases db
      INNER JOIN dental_base_sheets dbs ON db.oa = dbs.dentalBaseOA
      WHERE dbs.sheetId = ? AND db.estadoId = 5
    ''',
      [sheetId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
