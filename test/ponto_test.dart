import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chronos_pulse_app/features/ponto/data/models/espelho_relatorio_model.dart';
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
    // Filtra ajustes manuais para simular o comportamento real do repositório
    final lista =
        List<RegistroPontoModel>.from(filtrados.where((r) => !r.ajusteManual));
    // Espelha o datasource real: ordem cronológica crescente.
    lista.sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));
    return lista;
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

  /// Espelha a implementação real (SQLite/Web): upsert por instante com o
  /// servidor vencendo, remove órfãos sincronizados e preserva pendentes.
  @override
  Future<void> reconciliarDia({
    required String? colaboradorId,
    required DateTime inicioDia,
    required DateTime fimDia,
    required List<RegistroPontoModel> remotos,
  }) async {
    final porInstante = <int, RegistroPontoModel>{
      for (final r in remotos) r.dataHoraDispositivo.millisecondsSinceEpoch: r,
    };
    final mantidos = <RegistroPontoModel>[];
    final gravados = <int>{};

    for (final local in _banco) {
      final noColaborador =
          colaboradorId == null || local.colaboradorId == colaboradorId;
      final data = local.dataHoraDispositivo.toLocal();
      final noDia = !data.isBefore(inicioDia) && !data.isAfter(fimDia);
      if (!noColaborador || !noDia) {
        mantidos.add(local);
        continue;
      }
      final instante = local.dataHoraDispositivo.millisecondsSinceEpoch;
      final remoto = porInstante[instante];
      if (remoto != null) {
        mantidos.add(remoto);
        gravados.add(instante);
      } else if (!(local.sincronizadoOffline && !local.ajusteManual)) {
        mantidos.add(local);
      }
    }
    for (final r in remotos) {
      if (gravados.add(r.dataHoraDispositivo.millisecondsSinceEpoch)) {
        mantidos.add(r);
      }
    }
    _banco
      ..clear()
      ..addAll(mantidos);
  }
}

/// Local que falha na 1ª escrita (simula SQLite indisponível/corrompido) e
/// volta a funcionar — usado para provar que a UI distingue "não salvou" de
/// "offline".
class _LocalFalhaNaPrimeiraEscrita extends MockPontoLocalDataSource {
  bool _falhou = false;

  @override
  Future<void> salvarPontoLocal(RegistroPontoModel registro) async {
    if (!_falhou) {
      _falhou = true;
      throw Exception('disk I/O error');
    }
    await super.salvarPontoLocal(registro);
  }
}

/// Local lenta (SQLite frio no primeiro acesso) — expõe a janela de corrida
/// entre a leitura do construtor do provider e a recarga com o colaborador.
class _LocalLenta extends MockPontoLocalDataSource {
  int leituras = 0;

  @override
  Future<List<RegistroPontoModel>> obterHistoricoHoje(
      {String? colaboradorId}) async {
    leituras++;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return super.obterHistoricoHoje(colaboradorId: colaboradorId);
  }
}

class MockPontoRemoteDataSource extends PontoRemoteDataSource {
  bool online = true;
  bool rejeitar = false;
  List<RegistroPontoModel> ultimosSincronizados = [];
  List<RegistroPontoModel> espelhoRemoto = [];

  MockPontoRemoteDataSource() : super(DioClient());

  @override
  Future<bool> verificarConexao() async {
    return online;
  }

  @override
  Future<List<String>> sincronizarPontos(List<RegistroPontoModel> registros) async {
    if (rejeitar) {
      throw const RejeicaoServidorException(
          'O servidor recebeu a batida, mas não foi possível gravá-la. Tente novamente.');
    }
    if (!online) {
      throw Exception('Servidor indisponível');
    }
    ultimosSincronizados = List.from(registros);
    // Como no servidor real: aceite grava a batida e ela passa a constar
    // no espelho consultado em seguida (alimenta a reconciliação local).
    espelhoRemoto = [...espelhoRemoto, ...registros];
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
  Future<EspelhoRelatorioModel> buscarRelatorioEspelho({
    String? colaboradorId,
    int? mes,
    int? ano,
  }) async {
    if (!online) {
      throw Exception('Servidor indisponível');
    }
    return EspelhoRelatorioModel(
      periodo: EspelhoRelatorioPeriodo(
        inicio: DateTime(2026, 9, 1),
        fim: DateTime(2026, 9, 30),
      ),
      dataEmissao: DateTime(2026, 9, 16, 10, 30),
      empregador: const EspelhoRelatorioEmpregador(
        nome: 'Empresa Teste LTDA',
        cnpj: '12345678000199',
      ),
      trabalhador: EspelhoRelatorioTrabalhador(
        nome: 'João da Silva',
        cpf: '12345678901',
        dataAdmissao: DateTime(2020, 3, 2),
        cargo: 'Analista de Sistemas',
        matricula: '000123',
        departamento: 'TI',
      ),
      jornadaContratual: const EspelhoRelatorioJornada(
        nome: 'Jornada Administrativa 44h',
        cargaHorariaDiariaMinutos: 440,
        intervaloMinimoMinutos: 60,
      ),
      marcacoes: List.from(espelhoRemoto),
      codigoVerificacao: 'abc'.padRight(64, '0'),
    );
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

  @override
  Future<RegistroPontoModel> solicitarAjuste({
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
      ajusteStatus: 'PENDENTE',
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

  @override
  Future<void> reconciliarDia({
    required String? colaboradorId,
    required DateTime inicioDia,
    required DateTime fimDia,
    required List<RegistroPontoModel> remotos,
  }) async {
    throw StateError('banco local indisponível');
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

    test('Relatório do espelho (art. 84) acompanha o espelho com empregador, jornada e código de verificação', () async {
      remoteDataSource.online = true;
      remoteDataSource.espelhoRemoto = [
        batida(id: 'e1', tipo: 'ENTRADA', quando: DateTime(2026, 9, 1, 8, 0).toUtc()),
      ];

      await provider.carregarEspelho(mes: 9, ano: 2026);

      expect(provider.relatorioEspelho, isNotNull);
      final relatorio = provider.relatorioEspelho!;
      expect(relatorio.empregador?.nome, equals('Empresa Teste LTDA'));
      expect(relatorio.empregador?.cnpj, equals('12345678000199'));
      expect(relatorio.trabalhador?.cargo, equals('Analista de Sistemas'));
      expect(relatorio.trabalhador?.dataAdmissao, equals(DateTime(2020, 3, 2)));
      expect(relatorio.jornadaContratual?.nome, equals('Jornada Administrativa 44h'));
      expect(relatorio.codigoVerificacao, hasLength(64));
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

    test('Reconciliação: tipo do servidor vence e a mesma batida não duplica', () async {
      final agora = DateTime.now().toUtc();

      // O aparelho gravou ENTRADA offline; o servidor, com a sequência dele,
      // armazenou SAÍDA para o MESMO instante (bug real de produção).
      await localDataSource.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'local-entrada',
        dataHoraDispositivo: agora,
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h1',
        sincronizadoOffline: true,
      ));
      remoteDataSource.espelhoRemoto = [
        RegistroPontoModel(
          idLocal: 'srv-saida',
          dataHoraDispositivo: agora,
          tipoRegistro: 'SAIDA',
          latitude: 0,
          longitude: 0,
          precisaoGps: 5,
          fotoUrl: '',
          hashLocal: 'h2',
          sincronizadoOffline: true,
          nsr: 7,
          nsrLogico: 7,
        ),
      ];

      final historico = await repository.obterHistorico();

      expect(historico.length, equals(1),
          reason: 'a mesma batida não pode aparecer duas vezes na lista');
      expect(historico.first.tipoRegistro, equals('SAIDA'),
          reason: 'o tipo atribuído pelo servidor vence');

      // E o banco local passou a espelhar o servidor — leitura offline futura
      // já sai com a sequência certa.
      final localApos = await localDataSource.obterHistoricoHoje();
      expect(localApos.length, equals(1));
      expect(localApos.first.tipoRegistro, equals('SAIDA'));
      expect(localApos.first.nsr, equals(7));
    });

    test('Reconciliação desenfileira pendente já aceito pelo servidor', () async {
      final agora = DateTime.now().toUtc();
      await localDataSource.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'p-off',
        dataHoraDispositivo: agora,
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h1',
        sincronizadoOffline: false,
      ));
      remoteDataSource.espelhoRemoto = [
        RegistroPontoModel(
          idLocal: 'srv-x',
          dataHoraDispositivo: agora,
          tipoRegistro: 'ENTRADA',
          latitude: 0,
          longitude: 0,
          precisaoGps: 5,
          fotoUrl: '',
          hashLocal: 'h2',
          sincronizadoOffline: true,
        ),
      ];

      final historico = await repository.obterHistorico();

      expect(historico.length, equals(1));
      expect(await repository.obterQuantidadePendentes(), equals(0),
          reason: 'batida aceita pelo servidor sai da fila de reenvio');
    });

    test('Reconciliação remove órfão sincronizado e preserva pendente', () async {
      final hoje = DateTime.now();
      final inicio = DateTime(hoje.year, hoje.month, hoje.day);

      // Órfão: sincronizado localmente, mas não existe mais no servidor
      // (ex.: histórico de teste limpo no deploy).
      await localDataSource.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'orfao',
        dataHoraDispositivo: inicio.add(const Duration(hours: 8)).toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h1',
        sincronizadoOffline: true,
      ));
      // Pendente: nunca é tocado pela reconciliação.
      await localDataSource.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'pendente',
        dataHoraDispositivo: inicio.add(const Duration(hours: 9)).toUtc(),
        tipoRegistro: 'INTERVALO',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h2',
        sincronizadoOffline: false,
      ));
      remoteDataSource.espelhoRemoto = []; // servidor limpo

      final historico = await repository.obterHistorico();

      expect(historico.map((r) => r.idLocal).toList(), equals(['pendente']));
      final localApos = await localDataSource.obterHistoricoHoje();
      expect(localApos.map((r) => r.idLocal).toList(), equals(['pendente']),
          reason: 'o órfão sai também do banco local (offline já regra certo)');
      expect(await repository.obterQuantidadePendentes(), equals(1));
    });

    test('carregarDados sobreposto enfileira e reexecuta com o colaborador vigente', () async {
      final lento = _LocalLenta();
      await lento.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'a1',
        colaboradorId: 'colab-A',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h1',
        sincronizadoOffline: false,
      ));
      await lento.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'b1',
        colaboradorId: 'colab-B',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h2',
        sincronizadoOffline: false,
      ));
      final remotoOffline = MockPontoRemoteDataSource()..online = false;
      final repo = PontoRepository(
        localDataSource: lento,
        remoteDataSource: remotoOffline,
      );
      final p = PontoProvider(repo); // leitura 1 dispara no construtor
      addTearDown(p.dispose);

      p.carregarDados(); // ainda rodando a do construtor → enfileira
      p.definirColaborador('colab-A'); // enfileira de novo (coalesce)
      expect(p.colaboradorId, equals('colab-A'));

      for (var i = 0; i < 50 && lento.leituras < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(lento.leituras, equals(2),
          reason: 'construtor + UMA reexecução coalescida (fila), não corrida');
      expect(p.historico.length, equals(1),
          reason: 'resultado antigo (id nulo, 2 batidas) não pode vencer');
      expect(p.historico.first.colaboradorId, equals('colab-A'));
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
        sincronizadoOffline: false,
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
        sincronizadoOffline: false,
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
        sincronizadoOffline: false,
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

    test('Batidas de hoje aparecem em ordem crescente (Entrada #1 → Retorno #N)',
        () async {
      final agora = DateTime.now().toUtc();
      remoteDataSource.online = false;
      // Insere fora de ordem de escrita para provar que a ordenação
      // (e não a ordem de inserção) define a exibição.
      final batidas = [
        ('r2', agora.add(const Duration(minutes: 10)), 'RETORNO'),
        ('r1', agora, 'ENTRADA'),
        ('r3', agora.add(const Duration(minutes: 5)), 'INTERVALO'),
      ];
      for (final (id, quando, tipo) in batidas) {
        await localDataSource.salvarPontoLocal(RegistroPontoModel(
          idLocal: id,
          dataHoraDispositivo: quando,
          tipoRegistro: tipo,
          latitude: 0,
          longitude: 0,
          precisaoGps: 5,
          fotoUrl: '',
          hashLocal: 'h-$id',
          sincronizadoOffline: false,
        ));
      }

      await provider.carregarDados();

      final tipos = provider.historico.map((r) => r.tipoRegistro).toList();
      expect(tipos, equals(['ENTRADA', 'INTERVALO', 'RETORNO']),
          reason: 'A lista deve ser cronológica: #1 Entrada, #2 Intervalo, #3 Retorno');
      // Espelha o rótulo '#${index + 1}' da home: a mais antiga é #1.
      expect(provider.historico.first.tipoRegistro, equals('ENTRADA'));
      expect(provider.historico.last.tipoRegistro, equals('RETORNO'));
    });

    test('Rejeição explícita do servidor preenche ultimaFalhaServidor', () async {
      remoteDataSource.online = true;
      remoteDataSource.rejeitar = true;

      final salvo = await provider.registrarPonto(RegistroPontoModel(
        idLocal: 'uuid-rejeitado',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'hashR',
        sincronizadoOffline: false,
      ));

      expect(salvo, isFalse);
      expect(repository.ultimaFalhaServidor, isNotNull,
          reason: 'Rejeição do servidor deve ser distinguível de "offline"');
      expect(repository.ultimaFalhaServidor,
          contains('não foi possível gravá-la'));
    });

    test('Falha de rede NÃO preenche ultimaFalhaServidor (é offline, não rejeição)',
        () async {
      remoteDataSource.online = false;

      final salvo = await provider.registrarPonto(RegistroPontoModel(
        idLocal: 'uuid-offline',
        dataHoraDispositivo: DateTime.now().toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'hashO',
        sincronizadoOffline: false,
      ));

      expect(salvo, isFalse);
      expect(repository.ultimaFalhaServidor, isNull,
          reason: 'Sem rede = pendente/offline, sem motivo de rejeição');
      expect(repository.ultimaFalhaLocal, isNull,
          reason: 'Escrita local OK: a batida está na fila');
    });

    test('Falha de escrita local preenche ultimaFalhaLocal e a nova batida limpa',
        () async {
      final repo = PontoRepository(
        localDataSource: _LocalFalhaNaPrimeiraEscrita(),
        remoteDataSource: MockPontoRemoteDataSource()..online = false,
      );

      RegistroPontoModel batida(String id) => RegistroPontoModel(
            idLocal: id,
            dataHoraDispositivo: DateTime.now().toUtc(),
            tipoRegistro: 'ENTRADA',
            latitude: 0,
            longitude: 0,
            precisaoGps: 5,
            fotoUrl: '',
            hashLocal: 'hash-$id',
            sincronizadoOffline: false,
          );

      // 1ª batida: banco local falha → a UI NÃO pode dizer "salva localmente".
      final primeira = await repo.registrarPonto(registro: batida('b1'));
      expect(primeira, isFalse);
      expect(repo.ultimaFalhaLocal, isNotNull);
      expect(repo.ultimaFalhaLocal, contains('Falha ao gravar'));
      expect(repo.ultimaFalhaServidor, isNull,
          reason: 'a falha foi do dispositivo, não recusa do servidor');
      expect(await repo.obterQuantidadePendentes(), 0,
          reason: 'sem linha local não existe fila offline');

      // 2ª batida: local volta ao normal → falha local é zerada e a fila
      // passa a refletir a verdade (1 pendente).
      final segunda = await repo.registrarPonto(registro: batida('b2'));
      expect(segunda, isFalse); // continua offline (servidor fora)
      expect(repo.ultimaFalhaLocal, isNull);
      expect(await repo.obterQuantidadePendentes(), 1);
    });

    test('Ajuste manual gera idLocal UUID v4 (timestamp derrubava o lote no backend)',
        () async {
      remoteDataSource.online = false;

      final ok = await repository.ajustarPontoManual(
        dataHora: DateTime.now(),
        tipoRegistro: 'ENTRADA',
        justificativa: 'Esquecimento de marcação',
      );
      expect(ok, isFalse, reason: 'offline: ajuste fica pendente local');

      final pendentes = await localDataSource.obterPontosNaoSincronizados();
      expect(pendentes, hasLength(1));

      final id = pendentes.first.idLocal;
      final uuidV4 = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(uuidV4.hasMatch(id), isTrue,
          reason: 'idLocal="$id" deve ser UUID v4 — backend espera UUID '
              'e um timestamp rejeitava o lote inteiro no Jackson');
    });

    test('Solicitação de ajuste também gera idLocal UUID v4', () async {
      remoteDataSource.online = false;

      final ok = await repository.solicitarAjuste(
        dataHora: DateTime.now(),
        tipoRegistro: 'INTERVALO',
        justificativa: 'Falha técnica',
      );
      expect(ok, isFalse);

      final pendentes = await localDataSource.obterPontosNaoSincronizados();
      expect(pendentes, hasLength(1));

      final id = pendentes.first.idLocal;
      final uuidV4 = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(uuidV4.hasMatch(id), isTrue,
          reason: 'idLocal="$id" deve ser UUID v4');
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

    test('obterHistoricoHoje devolve em ordem crescente (não DESC)', () async {
      final store = PontoLocalDataSourceWeb();
      final base = DateTime.now().toUtc();
      // Escrita em ordem inversa à cronológica.
      for (final (id, offsetMin, tipo) in [
        ('ord-3', 10, 'RETORNO'),
        ('ord-1', 0, 'ENTRADA'),
        ('ord-2', 5, 'INTERVALO'),
      ]) {
        await store.salvarPontoLocal(RegistroPontoModel(
          idLocal: id,
          dataHoraDispositivo: base.add(Duration(minutes: offsetMin)),
          tipoRegistro: tipo,
          latitude: 0,
          longitude: 0,
          precisaoGps: 5,
          fotoUrl: '',
          hashLocal: 'h-$id',
          sincronizadoOffline: false,
        ));
      }

      final lista = await store.obterHistoricoHoje();
      expect(lista.map((r) => r.tipoRegistro).toList(),
          equals(['ENTRADA', 'INTERVALO', 'RETORNO']));
    });

    test('reconciliarDia: servidor vence, órfão sai e pendente fica', () async {
      final store = PontoLocalDataSourceWeb();
      final base = DateTime.now();

      // Local pendente que já está no servidor com OUTRO tipo.
      await store.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'w-m',
        dataHoraDispositivo: base.toUtc(),
        tipoRegistro: 'ENTRADA',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h1',
        sincronizadoOffline: false,
      ));
      // Órfão sincronizado (servidor limpo no deploy).
      await store.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'w-o',
        dataHoraDispositivo: base.add(const Duration(hours: 1)).toUtc(),
        tipoRegistro: 'INTERVALO',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h2',
        sincronizadoOffline: true,
      ));
      // Pendente sem contraparte no servidor: preservado.
      await store.salvarPontoLocal(RegistroPontoModel(
        idLocal: 'w-p',
        dataHoraDispositivo: base.add(const Duration(hours: 2)).toUtc(),
        tipoRegistro: 'RETORNO',
        latitude: 0,
        longitude: 0,
        precisaoGps: 5,
        fotoUrl: '',
        hashLocal: 'h3',
        sincronizadoOffline: false,
      ));

      await store.reconciliarDia(
        colaboradorId: null,
        inicioDia: DateTime(base.year, base.month, base.day),
        fimDia: DateTime(base.year, base.month, base.day, 23, 59, 59, 999),
        remotos: [
          RegistroPontoModel(
            idLocal: 'srv-w-m',
            dataHoraDispositivo: base.toUtc(),
            tipoRegistro: 'SAIDA',
            latitude: 0,
            longitude: 0,
            precisaoGps: 5,
            fotoUrl: '',
            hashLocal: 'h4',
            sincronizadoOffline: true,
            nsr: 11,
          ),
        ],
      );

      final depois = await store.obterHistoricoHoje();
      final porId = {for (final r in depois) r.idLocal: r};
      expect(porId.keys, containsAll(['srv-w-m', 'w-p']));
      expect(porId.keys, isNot(contains('w-m')),
          reason: 'local no mesmo instante é substituído pelo do servidor');
      expect(porId.keys, isNot(contains('w-o')),
          reason: 'órfão sincronizado ausente do servidor é removido');
      expect(porId['srv-w-m']!.tipoRegistro, equals('SAIDA'),
          reason: 'o registro do servidor substitui o local no mesmo instante');
      expect(porId['srv-w-m']!.sincronizadoOffline, isTrue);
      expect(await store.obterPontosNaoSincronizados(), hasLength(1),
          reason: 'pendente sem contraparte segue na fila');
    });
  });
}
