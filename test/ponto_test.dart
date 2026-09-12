import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chronos_pulse_app/features/ponto/data/models/registro_ponto_model.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_local_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/datasources/ponto_remote_datasource.dart';
import 'package:chronos_pulse_app/features/ponto/data/repositories/ponto_repository.dart';
import 'package:chronos_pulse_app/features/ponto/domain/constants/justificativas_ponto.dart';
import 'package:chronos_pulse_app/features/ponto/domain/services/espelho_agrupador.dart';
import 'package:chronos_pulse_app/features/ponto/domain/services/sequencia_ponto.dart';
import 'package:chronos_pulse_app/features/ponto/presentation/providers/ponto_provider.dart';

class MockPontoLocalDataSource extends PontoLocalDataSource {
  final List<RegistroPontoModel> _banco = [];

  @override
  Future<void> salvarPontoLocal(RegistroPontoModel registro) async {
    _banco.add(registro);
  }

  @override
  Future<List<RegistroPontoModel>> obterPontosNaoSincronizados({String? colaboradorId}) async {
    return _banco
        .where((p) =>
            !p.sincronizadoOffline &&
            (colaboradorId == null || p.colaboradorId == colaboradorId))
        .toList();
  }

  @override
  Future<List<RegistroPontoModel>> obterHistoricoHoje({String? colaboradorId}) async {
    final filtrados = (colaboradorId == null)
        ? _banco
        : _banco.where((p) => p.colaboradorId == colaboradorId).toList();
    return List.from(filtrados);
  }

  @override
  Future<void> marcarComoSincronizado(String idLocal) async {
    final idx = _banco.indexWhere((p) => p.idLocal == idLocal);
    if (idx != -1) {
      final antigo = _banco[idx];
      _banco[idx] = RegistroPontoModel(
        idLocal: antigo.idLocal,
        colaboradorId: antigo.colaboradorId,
        dataHoraDispositivo: antigo.dataHoraDispositivo,
        tipoRegistro: antigo.tipoRegistro,
        latitude: antigo.latitude,
        longitude: antigo.longitude,
        precisaoGps: antigo.precisaoGps,
        fotoUrl: antigo.fotoUrl,
        hashLocal: antigo.hashLocal,
        sincronizadoOffline: true,
        ajusteManual: antigo.ajusteManual,
        justificativa: antigo.justificativa,
        observacao: antigo.observacao,
      );
    }
  }
}

class MockPontoRemoteDataSource extends PontoRemoteDataSource {
  bool online = true;
  List<RegistroPontoModel> ultimosSincronizados = [];
  List<RegistroPontoModel> espelhoRemoto = [];

  MockPontoRemoteDataSource() : super(DioClient());

  @override
  Future<bool> verificarConexao() async {
    return online;
  }

  @override
  Future<List<String>> sincronizarPontos(List<RegistroPontoModel> registros) async {
    if (!online) {
      throw Exception('Servidor indisponível');
    }
    ultimosSincronizados = List.from(registros);
    return registros.map((r) => r.idLocal).toList();
  }

  @override
  Future<List<RegistroPontoModel>> buscarEspelho({
    String? colaboradorId,
    int? mes,
    int? ano,
  }) async {
    if (!online) {
      throw Exception('Servidor indisponível');
    }
    return List.from(espelhoRemoto);
  }

  @override
  Future<RegistroPontoModel> solicitarAjusteManual({
    required DateTime dataHora,
    required String tipoRegistro,
    required String justificativa,
    String? observacao,
    String? colaboradorId,
  }) async {
    if (!online) {
      throw Exception('Servidor indisponível');
    }
    return RegistroPontoModel(
      idLocal: 'ajuste-1',
      colaboradorId: colaboradorId,
      dataHoraDispositivo: dataHora,
      tipoRegistro: tipoRegistro,
      latitude: 0,
      longitude: 0,
      precisaoGps: 0,
      sincronizadoOffline: true,
      ajusteManual: true,
      justificativa: justificativa,
      observacao: observacao,
    );
  }
}

/// Simula o SQLite Web indisponível (ex.: WASM/IndexedDB que não inicializa):
/// a escrita local falha imediatamente e a batida precisa seguir apenas online.
class LocalDataSourceIndisponivel extends PontoLocalDataSource {
  @override
  Future<void> salvarPontoLocal(RegistroPontoModel registro) async {
    throw StateError('banco local indisponível');
  }

  @override
  Future<List<RegistroPontoModel>> obterPontosNaoSincronizados({String? colaboradorId}) async {
    return [];
  }

  @override
  Future<List<RegistroPontoModel>> obterHistoricoHoje({String? colaboradorId}) async {
    return [];
  }

  @override
  Future<List<RegistroPontoModel>> obterPorMesAno({
    String? colaboradorId,
    int? mes,
    int? ano,
  }) async {
    return [];
  }
}

RegistroPontoModel batida({
  required String id,
  required String tipo,
  required DateTime quando,
  bool ajuste = false,
  String? justificativa,
  String? observacao,
}) {
  return RegistroPontoModel(
    idLocal: id,
    dataHoraDispositivo: quando,
    tipoRegistro: tipo,
    latitude: 0,
    longitude: 0,
    precisaoGps: 0,
    fotoUrl: '',
    hashLocal: '',
    sincronizadoOffline: true,
    ajusteManual: ajuste,
    justificativa: justificativa,
    observacao: observacao,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JustificativasPadronizadas', () {
    test('Deve conter as 8 justificativas exigidas com descrições corretas', () {
      final lista = JustificativasPonto.lista;
      expect(lista.length, equals(8));

      final titulos = lista.map((j) => j.titulo).toList();
      expect(titulos, contains('Esquecimento de marcação'));
      expect(titulos, contains('Falha técnica'));
      expect(titulos, contains('Atividade externa'));
      expect(titulos, contains('Viagem a trabalho'));
      expect(titulos, contains('Trabalho remoto'));
      expect(titulos, contains('Atendimento médico'));
      expect(titulos, contains('Autorização da liderança'));
      expect(titulos, contains('Plantão ou sobreaviso'));
    });
  });

  group('PontoProvider & Sensor de Conectividade', () {
    late MockPontoLocalDataSource localDataSource;
    late MockPontoRemoteDataSource remoteDataSource;
    late PontoRepository repository;
    late PontoProvider provider;

    setUp(() {
      localDataSource = MockPontoLocalDataSource();
      remoteDataSource = MockPontoRemoteDataSource();
      repository = PontoRepository(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
      );
      provider = PontoProvider(repository);
    });

    tearDown(() {
      provider.dispose();
    });

    test('Deve salvar localmente como pendente quando offline e sincronizar ao ficar online', () async {
      // 1. Simula servidor offline
      remoteDataSource.online = false;
      await provider.checarConexao();
      expect(provider.isOnline, isFalse);

      final ponto1 = RegistroPontoModel(
        idLocal: 'uuid-1',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'hash1',
        sincronizadoOffline: false,
      );

      final salvoOnline = await provider.registrarPonto(ponto1);
      expect(salvoOnline, isFalse);
      expect(provider.pendentesCount, equals(1));
      expect(provider.historico.length, equals(1));
      expect(provider.historico.first.sincronizadoOffline, isFalse);

      // 2. Servidor volta a ficar online e executa auto-sync
      remoteDataSource.online = true;
      await provider.checarConexao(autoSync: true);

      expect(provider.isOnline, isTrue);
      expect(provider.pendentesCount, equals(0));
      expect(provider.historico.first.sincronizadoOffline, isTrue);
      expect(remoteDataSource.ultimosSincronizados.length, equals(1));
    });

    test('Sincronização manual deve processar lote acumulado', () async {
      remoteDataSource.online = false;

      final p1 = RegistroPontoModel(
        idLocal: 'uuid-a',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'hashA',
        sincronizadoOffline: false,
      );

      final p2 = RegistroPontoModel(
        idLocal: 'uuid-b',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'INTERVALO',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'hashB',
        sincronizadoOffline: false,
      );

      await provider.registrarPonto(p1);
      await provider.registrarPonto(p2);
      expect(provider.pendentesCount, equals(2));

      // Volta a ficar online e dispara sincronização manual
      remoteDataSource.online = true;
      final totalSincronizados = await provider.sincronizar();

      expect(totalSincronizados, equals(2));
      expect(provider.pendentesCount, equals(0));
      expect(provider.isOnline, isTrue);
    });

    test('Ajuste manual é excluído da home, mas permanece no espelho', () async {
      final agora = DateTime.now();
      final sucesso = await provider.ajustarPontoManual(
        dataHora: agora,
        tipoRegistro: 'ENTRADA',
        justificativa: 'Esquecimento de marcação',
        observacao: 'Cheguei no horário correto',
      );

      expect(sucesso, isTrue);
      expect(provider.historico, isEmpty,
          reason: 'Ajuste manual não deve inflar a lista/sequência da home');

      // Servidor já reflete o ajuste no espelho
      remoteDataSource.espelhoRemoto = [
        batida(
          id: 'ajuste-echo',
          tipo: 'ENTRADA',
          quando: agora.toUtc(),
          ajuste: true,
          justificativa: 'Esquecimento de marcação',
          observacao: 'Cheguei no horário correto',
        ),
      ];

      final espelho = await repository.obterEspelhoPonto(
        mes: agora.month,
        ano: agora.year,
      );
      expect(espelho.where((r) => r.ajusteManual).length, equals(1));

      // O histórico (home) desconta o ajuste mesmo quando ele vem do servidor
      final historico = await repository.obterHistorico();

      expect(historico, isEmpty);
    });

    test('Batida não trava quando o banco local está indisponível e sincroniza online', () async {
      final localIndisponivel = LocalDataSourceIndisponivel();
      final remote = MockPontoRemoteDataSource();
      remote.online = true;

      final repo = PontoRepository(
        localDataSource: localIndisponivel,
        remoteDataSource: remote,
      );
      final providerSemLocal = PontoProvider(repo);

      addTearDown(providerSemLocal.dispose);

      final ponto = RegistroPontoModel(
        idLocal: 'uuid-web-db-off',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'hashX',
        sincronizadoOffline: false,
      );

      final salvoOnline = await providerSemLocal.registrarPonto(ponto);

      expect(salvoOnline, isTrue);
      expect(remote.ultimosSincronizados.length, equals(1));
      expect(providerSemLocal.pendentesCount, equals(0));
    });

    test('Histórico reflete o espelho do servidor quando o banco local falha (Web)', () async {
      final localIndisponivel = LocalDataSourceIndisponivel();
      final remote = MockPontoRemoteDataSource();
      remote.online = true;

      final agora = DateTime.now();
      remote.espelhoRemoto = [
        RegistroPontoModel(
          idLocal: 'srv-entrada',
          dataHoraDispositivo: agora.toUtc(),
          tipoRegistro: 'ENTRADA',
          latitude: -23.5,
          longitude: -46.6,
          precisaoGps: 5,
          fotoUrl: '',
          hashLocal: 'h1',
          sincronizadoOffline: false,
        ),
      ];

      final repo = PontoRepository(
        localDataSource: localIndisponivel,
        remoteDataSource: remote,
      );

      final historico = await repo.obterHistorico();

      expect(historico.length, equals(1));
      expect(historico.first.tipoRegistro, equals('ENTRADA'));
      expect(historico.first.sincronizadoOffline, isTrue,
          reason: 'Registro vindo do servidor deve aparecer como sincronizado');
    });

    test('Histórico local/NFC não duplica quando o servidor já tem a batida', () async {
      final local = MockPontoLocalDataSource();
      final remote = MockPontoRemoteDataSource();
      remote.online = true;

      final agora = DateTime.now();
      remote.espelhoRemoto = [
        RegistroPontoModel(
          idLocal: 'srv-1',
          dataHoraDispositivo: agora.toUtc(),
          tipoRegistro: 'INTERVALO',
          latitude: 0,
          longitude: 0,
          precisaoGps: 5,
          fotoUrl: '',
          hashLocal: 'h1',
          sincronizadoOffline: true,
        ),
      ];
      await local.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'local-1',
        dataHoraDispositivo: agora.toUtc(),
        tipoRegistro: 'INTERVALO',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h1',
        sincronizadoOffline: true,
      ));

      final repo = PontoRepository(
        localDataSource: local,
        remoteDataSource: remote,
      );

      final historico = await repo.obterHistorico();

      expect(historico.length, equals(1));
    });

    test('Modo offline preserva a sequência de batidas (não volta à primeira batida)', () async {
      final agora = DateTime.now();
      await localDataSource.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'r1',
        dataHoraDispositivo: agora.toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h1',
        sincronizadoOffline: true,
      ));
      await localDataSource.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'r2',
        dataHoraDispositivo: agora.toUtc().add(const Duration(minutes: 5)),
        tipoRegistro: 'INTERVALO',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h2',
        sincronizadoOffline: true,
      ));
      await localDataSource.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'r3',
        dataHoraDispositivo: agora.toUtc().add(const Duration(minutes: 10)),
        tipoRegistro: 'RETORNO',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h3',
        sincronizadoOffline: true,
      ));

      remoteDataSource.online = false;
      await provider.checarConexao();
      expect(provider.isOnline, isFalse);

      // Recarrega os dados com o servidor offline (equivalente a abrir a tela)
      await provider.carregarDados();

      expect(provider.historico.length, equals(3),
          reason: 'Sequência local deve permanecer visível com o servidor offline');
      final tipos = provider.historico.map((r) => r.tipoRegistro).toList();
      expect(tipos, contains('ENTRADA'));
      expect(tipos, contains('INTERVALO'));
      expect(tipos, contains('RETORNO'));
    });
  });

  group('EspelhoAgrupador (sobreposição de ajustes)', () {
    DateTime dia(int hora, int minuto) => DateTime(2026, 9, 12, hora, minuto);

    test('Batida original sem ajuste mantém célula normal', () {
      final celulas = EspelhoAgrupador.celulasDoDia([
        batida(id: 'o1', tipo: 'INTERVALO', quando: dia(12, 0)),
      ]);

      expect(celulas.length, equals(1));
      expect(celulas.first.ajuste, isFalse);
      expect(celulas.first.incluiOriginal, isFalse);
      expect(celulas.first.hora, equals('12:00'));
      expect(celulas.first.horaOriginal, isNull);
    });

    test('Ajuste sobrepõe a batida original na mesma célula', () {
      final celulas = EspelhoAgrupador.celulasDoDia([
        batida(id: 'o1', tipo: 'ENTRADA', quando: dia(8, 0)),
        batida(
          id: 'a1',
          tipo: 'ENTRADA',
          quando: dia(7, 55),
          ajuste: true,
          justificativa: 'Esquecimento de marcação',
        ),
      ]);

      expect(celulas.length, equals(1),
          reason: 'O ajuste não deve criar uma célula/registro extra');
      final cell = celulas.first;
      expect(cell.ajuste, isTrue);
      expect(cell.incluiOriginal, isTrue);
      expect(cell.hora, equals('07:55'));
      expect(cell.horaOriginal, equals('08:00'));
      expect(cell.justificativa, equals('Esquecimento de marcação'));
    });

    test('Ajuste sem original (marcação incluída) cria célula de ajuste', () {
      final celulas = EspelhoAgrupador.celulasDoDia([
        batida(id: 'a1', tipo: 'SAIDA', quando: dia(18, 0), ajuste: true),
      ]);

      expect(celulas.length, equals(1));
      expect(celulas.first.ajuste, isTrue);
      expect(celulas.first.incluiOriginal, isFalse);
      expect(celulas.first.hora, equals('18:00'));
      expect(celulas.first.horaOriginal, isNull);
    });

    test('colunasDoDia mapeia Entrada/Intervalo/Retorno/Saída e sobrepõe ajuste', () {
      final colunas = EspelhoAgrupador.colunasDoDia([
        batida(id: 'o1', tipo: 'ENTRADA', quando: dia(8, 0)),
        batida(id: 'o2', tipo: 'INTERVALO', quando: dia(12, 0)),
        batida(id: 'o3', tipo: 'RETORNO', quando: dia(13, 0)),
        batida(id: 'o4', tipo: 'SAIDA', quando: dia(18, 0)),
        batida(
          id: 'a1',
          tipo: 'INTERVALO',
          quando: dia(12, 10),
          ajuste: true,
          justificativa: 'Falha técnica',
        ),
      ]);

      expect(colunas.length, equals(4));
      expect(colunas[0]!.hora, equals('08:00'));
      expect(colunas[0]!.ajuste, isFalse);

      expect(colunas[1]!.hora, equals('12:10'));
      expect(colunas[1]!.horaOriginal, equals('12:00'));
      expect(colunas[1]!.justificativa, equals('Falha técnica'));

      expect(colunas[2]!.hora, equals('13:00'));
      expect(colunas[3]!.hora, equals('18:00'));
    });

    test('Ajuste com original ausente entra na primeira coluna livre', () {
      final colunas = EspelhoAgrupador.colunasDoDia([
        batida(id: 'o1', tipo: 'ENTRADA', quando: dia(8, 0)),
        batida(
          id: 'a1',
          tipo: 'RETORNO',
          quando: dia(13, 5),
          ajuste: true,
        ),
      ]);

      expect(colunas[0]!.hora, equals('08:00'));
      expect(colunas[2], isNull);
      expect(colunas[1]!.ajuste, isTrue);
      expect(colunas[1]!.hora, equals('13:05'));
      expect(colunas[1]!.incluiOriginal, isFalse);
    });
  });

  group('SequenciaPonto (ajustes não avançam o ciclo)', () {
    test('Batidas de botão seguem Entrada→Intervalo→Retorno→Saída', () {
      expect(SequenciaPonto.proximo([]), equals('ENTRADA'));
      expect(
        SequenciaPonto.proximo([
          batida(id: 'b1', tipo: 'ENTRADA', quando: DateTime(2026, 9, 12, 8, 0)),
        ]),
        equals('INTERVALO'),
      );
      expect(
        SequenciaPonto.proximo([
          batida(id: 'b1', tipo: 'ENTRADA', quando: DateTime(2026, 9, 12, 8, 0)),
          batida(id: 'b2', tipo: 'INTERVALO', quando: DateTime(2026, 9, 12, 12, 0)),
        ]),
        equals('RETORNO'),
      );
      expect(
        SequenciaPonto.proximo([
          batida(id: 'b1', tipo: 'ENTRADA', quando: DateTime(2026, 9, 12, 8, 0)),
          batida(id: 'b2', tipo: 'INTERVALO', quando: DateTime(2026, 9, 12, 12, 0)),
          batida(id: 'b3', tipo: 'RETORNO', quando: DateTime(2026, 9, 12, 13, 0)),
        ]),
        equals('SAIDA'),
      );
      // Ciclo reinicia após a Saída (5ª batida = Entrada Extra)
      expect(
        SequenciaPonto.proximo([
          batida(id: 'b1', tipo: 'ENTRADA', quando: DateTime(2026, 9, 12, 8, 0)),
          batida(id: 'b2', tipo: 'INTERVALO', quando: DateTime(2026, 9, 12, 12, 0)),
          batida(id: 'b3', tipo: 'RETORNO', quando: DateTime(2026, 9, 12, 13, 0)),
          batida(id: 'b4', tipo: 'SAIDA', quando: DateTime(2026, 9, 12, 18, 0)),
        ]),
        equals('ENTRADA'),
      );
    });

    test('Ajustes manuais não contam para a próxima batida', () {
      // Dia com 3 ajustes (E/I/R) e só 1 batida de botão (E):
      // a próxima deve ser INTERVALO e não cair fora da sequência.
      final registros = [
        batida(id: 'a1', tipo: 'ENTRADA', quando: DateTime(2026, 9, 12, 11, 0), ajuste: true),
        batida(id: 'a2', tipo: 'INTERVALO', quando: DateTime(2026, 9, 12, 15, 30), ajuste: true),
        batida(id: 'a3', tipo: 'RETORNO', quando: DateTime(2026, 9, 12, 16, 30), ajuste: true),
        batida(id: 'b1', tipo: 'ENTRADA', quando: DateTime(2026, 9, 12, 19, 51)),
      ];

      expect(SequenciaPonto.proximo(registros), equals('INTERVALO'));
    });

    test('Ajuste de Saída não atrasa o ciclo após a 4ª batida de botão', () {
      // E/I/R/S pelo botão + ajuste de Intervalo: a contagem continua 4 → Entrada
      // (a próxima do ciclo), em vez de 5 → Intervalo.
      final registros = [
        batida(id: 'b1', tipo: 'ENTRADA', quando: DateTime(2026, 9, 12, 8, 0)),
        batida(id: 'b2', tipo: 'INTERVALO', quando: DateTime(2026, 9, 12, 12, 0)),
        batida(id: 'b3', tipo: 'RETORNO', quando: DateTime(2026, 9, 12, 13, 0)),
        batida(id: 'b4', tipo: 'SAIDA', quando: DateTime(2026, 9, 12, 18, 0)),
        batida(id: 'a1', tipo: 'INTERVALO', quando: DateTime(2026, 9, 12, 12, 10), ajuste: true),
      ];

      expect(SequenciaPonto.proximo(registros), equals('ENTRADA'));
    });
  });

  group('PontoLocalDataSourceWeb (localStorage durável)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Persiste entre instâncias — sobrevive a recarregamento (F5)', () async {
      final store = PontoLocalDataSourceWeb();
      await store.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'w1',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h1',
        sincronizadoOffline: false,
      ));

      // Nova "tela/instância" lê do MESMO armazenamento (simula F5)
      final reload = PontoLocalDataSourceWeb();
      expect((await reload.obterHistoricoHoje()).length, equals(1));
      expect((await reload.obterPontosNaoSincronizados()).length, equals(1));
    });

    test('marcarComoSincronizado persiste e esvazia pendentes', () async {
      final store = PontoLocalDataSourceWeb();
      await store.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'w2',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'INTERVALO',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h2',
        sincronizadoOffline: false,
      ));
      await store.marcarComoSincronizado('w2');

      final reload = PontoLocalDataSourceWeb();
      expect(await reload.obterPontosNaoSincronizados(), isEmpty);
      expect((await reload.obterHistoricoHoje()).first.sincronizadoOffline,
          isTrue);
    });
  });
}
