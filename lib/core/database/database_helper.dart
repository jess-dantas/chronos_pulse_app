import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chronos_pulse.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      // Inicializador específico do SQLite para ambiente Web
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(
        filePath,
        version: 1,
        onCreate: _createDB,
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE pontos ADD COLUMN idLocal TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE pontos ADD COLUMN ajusteManual INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE pontos ADD COLUMN justificativa TEXT');
      await db.execute('ALTER TABLE pontos ADD COLUMN observacao TEXT');
      await db.execute('ALTER TABLE pontos ADD COLUMN nsr INTEGER');
      await db.execute('ALTER TABLE pontos ADD COLUMN hashLocal TEXT');
      await db.execute('ALTER TABLE pontos ADD COLUMN dataHoraServidor TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pontos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idLocal TEXT,
        colaboradorId TEXT NOT NULL,
        dataHoraDispositivo TEXT NOT NULL,
        dataHoraServidor TEXT,
        tipoRegistro TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        precisaoGps REAL NOT NULL,
        fotoUrl TEXT,
        hashLocal TEXT,
        sincronizadoOffline INTEGER NOT NULL,
        ajusteManual INTEGER DEFAULT 0,
        justificativa TEXT,
        observacao TEXT,
        nsr INTEGER
      )
    ''');
  }
}
