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

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS dental_bases');
      await _createDB(db, newVersion);
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
        price INTEGER NOT NULL
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

  // Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
