import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:chronos_pulse_app/core/database/database_helper.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_local_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/models/registro_ponto_model.dart';

/// Regressão do esquema SQLite local: o `toJson()` do
/// [RegistroPontoModel] grava colunas de ajuste (v4) que precisam existir
/// no CREATE TABLE e na migração v3 → v4. Sem isto, todo `db.insert`
/// falhava com `no such column: nsrLogico` no Android/iOS (a Web não é
/// afetada: usa SharedPreferences).
void main() {
  late String dbPath;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dbPath = join(await databaseFactory.getDatabasesPath(), 'chronos_pulse.db');
  });

  tearDown(() async {
    DatabaseHelper.resetCache();
    await databaseFactory.deleteDatabase(dbPath);
  });

  RegistroPontoModel registroCompleto() => RegistroPontoModel(
        idLocal: 'ajuste-1',
        colaboradorId: 'col-1',
        dataHoraDispositivo: DateTime(2026, 9, 28, 8, 30),
        dataHoraServidor: DateTime(2026, 9, 28, 11, 30),
        tipoRegistro: 'ENTRADA',
        latitude: -3.73,
        longitude: -38.52,
        precisaoGps: 5.5,
        hashLocal: 'hash-abc',
        ajusteManual: true,
        justificativa: 'Esquecimento de batida',
        observacao: 'Entrada não registrada',
        nsr: 10,
        nsrLogico: 11,
        ajusteStatus: 'PENDENTE',
        aprovadoPor: 'gestor-rh-1',
        aprovadoEm: DateTime(2026, 9, 28, 15, 0),
      );

  test('onCreate (v4) grava e lê todas as colunas de ajuste', () async {
    final ds = PontoLocalDataSource();
    await ds.salvarPontoLocal(registroCompleto());

    final lidos = await ds.obterPontosNaoSincronizados();
    expect(lidos, hasLength(1));

    final r = lidos.single;
    expect(r.nsrLogico, 11);
    expect(r.ajusteStatus, 'PENDENTE');
    expect(r.aprovadoPor, 'gestor-rh-1');
    expect(r.aprovadoEm, DateTime(2026, 9, 28, 15, 0));
    expect(r.justificativa, 'Esquecimento de batida');
    expect(r.ajusteManual, isTrue);
  });

  test('migração v3 → v4 adiciona as colunas faltantes', () async {
    // Recria o banco no schema antigo (versão 3, sem colunas de ajuste).
    await databaseFactory.deleteDatabase(dbPath);
    final legacy = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
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
        },
      ),
    );
    await legacy.close();
    DatabaseHelper.resetCache();

    final ds = PontoLocalDataSource();
    await ds.salvarPontoLocal(registroCompleto());

    final lidos = await ds.obterPontosNaoSincronizados();
    expect(lidos, hasLength(1));
    expect(lidos.single.ajusteStatus, 'PENDENTE');
    expect(lidos.single.nsrLogico, 11);

    final tabela = await DatabaseHelper.instance.database
        .then((db) => db.rawQuery('PRAGMA table_info(pontos)'));
    final colunas = tabela.map((c) => c['name']).toSet();
    expect(
      colunas,
      containsAll([
        'nsrLogico',
        'ajusteStatus',
        'ajusteMotivoRejeicao',
        'aprovadoPor',
        'aprovadoEm',
      ]),
    );
  });

  test('coluna duplicada em upgrade não derruba a abertura do banco',
      () async {
    // BD "defasado": gravado como versão 2 mas já com colunas v3/v4
    // (builds intermediários). Sem guarda, o ALTER com "duplicate column
    // name" lançava, o openDatabase inteiro falhava e TODO o acesso local
    // passava a falhar em silêncio (histórico vazio + fila sem pendentes).
    await databaseFactory.deleteDatabase(dbPath);
    final legacy = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
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
              nsr INTEGER,
              nsrLogico INTEGER,
              ajusteStatus TEXT,
              ajusteMotivoRejeicao TEXT,
              aprovadoPor TEXT,
              aprovadoEm TEXT
            )
          ''');
        },
      ),
    );
    await legacy.close();
    DatabaseHelper.resetCache();

    // Não pode lançar (duplicate column) — e o banco precisa continuar usável.
    final ds = PontoLocalDataSource();
    await ds.salvarPontoLocal(registroCompleto());
    final lidos = await ds.obterPontosNaoSincronizados();
    expect(lidos, hasLength(1));
    expect(lidos.single.ajusteStatus, 'PENDENTE');
  });

  test('BD órfão (v4) sem a tabela pontos é reparado na abertura', () async {
    await databaseFactory.deleteDatabase(dbPath);
    final orphan = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {}, // nada criado: arquivo parcial
      ),
    );
    await orphan.close();
    DatabaseHelper.resetCache();

    // version == version não dispara onCreate/onUpgrade: só onOpen repara.
    final ds = PontoLocalDataSource();
    await ds.salvarPontoLocal(registroCompleto());
    final lidos = await ds.obterPontosNaoSincronizados();
    expect(lidos, hasLength(1));
  });
}
