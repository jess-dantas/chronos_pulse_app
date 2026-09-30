import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Fecha o cache do banco. Uso restrito a testes (migrações/creates).
  static void resetCache() {
    _database = null;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Limite de tempo: se a abertura do SQLite (ex.: WASM/IndexedDB na Web)
    // travar, os chamadores falham rápido e seguem o caminho online em vez de
    // pendurar a UI. Na Web, o openDatabase continua tentando em background.
    _database = await _initDB('chronos_pulse.db').timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw StateError('Banco local indisponível (timeout ao abrir).'),
    );
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      // Roda SEMPRE (inclusive quando version == version, em que onCreate e
      // onUpgrade não disparam): cobre BD órfão sem a tabela `pontos`.
      onOpen: (db) => _criarTabelaPontos(db),
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Garante a tabela mesmo em banco parcial/corrompido: sem o CREATE, um
    // arquivo órfão pula o onCreate e TODAS as leituras/escritas locais
    // passam a falhar em silêncio (histórico vazio + fila sem pendentes).
    await _criarTabelaPontos(db);
    final colunas = await _colunasPontos(db);

    if (oldVersion < 2) {
      await _addColuna(db, colunas, 'idLocal TEXT');
    }
    if (oldVersion < 3) {
      for (final definicao in [
        'ajusteManual INTEGER DEFAULT 0',
        'justificativa TEXT',
        'observacao TEXT',
        'nsr INTEGER',
        'hashLocal TEXT',
        'dataHoraServidor TEXT',
      ]) {
        await _addColuna(db, colunas, definicao);
      }
    }
    if (oldVersion < 4) {
      for (final definicao in [
        'nsrLogico INTEGER',
        'ajusteStatus TEXT',
        'ajusteMotivoRejeicao TEXT',
        'aprovadoPor TEXT',
        'aprovadoEm TEXT',
      ]) {
        await _addColuna(db, colunas, definicao);
      }
    }
  }

  Future<Set<String>> _colunasPontos(Database db) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info(pontos)');
      return info
          .map((r) => (r['name'] as String?)?.toLowerCase() ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('[DatabaseHelper] PRAGMA table_info falhou: $e');
      return <String>{};
    }
  }

  /// Adiciona a coluna apenas se ela não existir. Uma falha isolada (ex.:
  /// "duplicate column name" em BDs criados por builds intermediários) NÃO
  /// pode derrubar a abertura do banco inteiro — isso apagaria a fila offline
  /// e o histórico do dia em silêncio.
  Future<void> _addColuna(
      Database db, Set<String> colunas, String definicao) async {
    final nome = definicao.split(' ').first.toLowerCase();
    if (colunas.contains(nome)) return;
    try {
      await db.execute('ALTER TABLE pontos ADD COLUMN $definicao');
      colunas.add(nome);
    } catch (e) {
      debugPrint('[DatabaseHelper] falha ao adicionar coluna "$nome": $e');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await _criarTabelaPontos(db);
  }

  Future<void> _criarTabelaPontos(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pontos (
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
        nsr INTEGER,
        nsrLogico INTEGER,
        ajusteStatus TEXT,
        ajusteMotivoRejeicao TEXT,
        aprovadoPor TEXT,
        aprovadoEm TEXT
      )
    ''');
  }
}
