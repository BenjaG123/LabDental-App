import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/dental_base.dart';

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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dental_bases(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientName TEXT NOT NULL,
        baseType TEXT NOT NULL,
        creationDate TEXT NOT NULL,
        deliveryDate TEXT,
        status TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  // CRUD Operations

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

  Future<DentalBase?> getDentalBase(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'dental_bases',
      where: 'id = ?',
      whereArgs: [id],
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
      where: 'id = ?',
      whereArgs: [dentalBase.id],
    );
  }

  // Delete
  Future<int> deleteDentalBase(int id) async {
    final db = await instance.database;
    return await db.delete(
      'dental_bases',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}