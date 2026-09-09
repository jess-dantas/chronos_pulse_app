import 'dart:convert';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/licitacoes/data/datasources/licitacoes_remote_datasource.dart';
import 'package:chronos_pulse_app/features/licitacoes/data/models/licitacoes_models.dart';
import 'package:chronos_pulse_app/features/licitacoes/data/models/planejamento_licitacao_models.dart';
import 'package:chronos_pulse_app/features/licitacoes/data/repositories/licitacoes_repository.dart';
import 'package:chronos_pulse_app/features/licitacoes/presentation/providers/licitacoes_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Modelos de planejamento da licitação', () {
    test('fromJson completa com ETP aprovado, TR aprovado e edital publicado',
        () {
      final planejamento = PlanejamentoLicitacaoModel.fromJson(
        _planejamentoJson(
          etp: _etpJson(status: 'APROVADO', responsavel: 'Ana Gestora'),
          tr: _trJson(status: 'APROVADO', responsavel: 'Bruno Comprador'),
          edital: _editalJson(
            status: 'PUBLICADO',
            formaEntregaPropostas: 'ELETRONICA',
          ),
        ),
      );

      expect(planejamento.licitacaoId, 'licitacao-1');
      expect(planejamento.numero, 'LIC 2026/001');
      expect(planejamento.licitacaoStatus, 'EM_ELABORACAO');
      expect(planejamento.etp, isNotNull);
      expect(planejamento.etp!.aprovado, isTrue);
      expect(planejamento.etp!.statusLabel, 'Aprovado');
      expect(planejamento.etp!.objeto, contains('cadeiras'));
      expect(planejamento.etp!.valorEstimado, 45000.5);
      expect(planejamento.tr!.aprovado, isTrue);
      expect(planejamento.tr!.especificacoes, isNotEmpty);
      expect(planejamento.edital!.publicado, isTrue);
      expect(planejamento.edital!.statusLabel, 'Publicado');
      expect(planejamento.edital!.formaEntregaLabel, 'Eletrônica');
      expect(planejamento.edital!.dataSessaoFormatada, '15/10/2026');
    });

    test('fromJson sem documentos resulta em seções nulas', () {
      final planejamento = PlanejamentoLicitacaoModel.fromJson(
        _planejamentoJson(etp: null, tr: null, edital: null),
      );

      expect(planejamento.etp, isNull);
      expect(planejamento.tr, isNull);
      expect(planejamento.edital, isNull);
    });

    test('flags e rótulos de status refletem cada enum', () {
      final etp = EtpModel.fromJson(_etpJson(status: 'RASCUNHO'));
      final tr = TrModel.fromJson(_trJson(status: 'APROVADO'));
      final edital =
          EditalModel.fromJson(_editalJson(status: 'EM_ELABORACAO'));

      expect(etp.aprovado, isFalse);
      expect(etp.statusLabel, 'Rascunho');
      expect(tr.aprovado, isTrue);
      expect(tr.statusLabel, 'Aprovado');
      expect(edital.publicado, isFalse);
      expect(edital.statusLabel, 'Em elaboração');
    });
  });

  group('DTOs de planejamento', () {
    test('EtpDTO.toJson omite campos não informados', () {
      final json = EtpDTO(
        objeto: 'Aquisição',
        justificativa: 'Demanda',
        requisitos: '',
      ).toJson();

      expect(json, {
        'objeto': 'Aquisição',
        'justificativa': 'Demanda',
        'requisitos': '',
      });
    });

    test('EtpDTO.toJson inclui valor estimado quando informado', () {
      final json = EtpDTO(
        objeto: 'Aquisição',
        justificativa: 'Demanda',
        requisitos: 'Requisitos',
        valorEstimado: 1234.56,
      ).toJson();

      expect(json['valorEstimado'], 1234.56);
      expect(json.containsKey('alternativas'), isFalse);
    });

    test('TrDTO.toJson omite campos opcionais vazios', () {
      final json = TrDTO(
        especificacoes: 'Especificações',
        condicoesFornecimento: 'Condições',
        obrigacoes: 'Obrigações',
        criteriosAceitacao: 'Critérios',
        prazosEntrega: 'Prazos',
      ).toJson();

      expect(json.containsKey('garantia'), isFalse);
      expect(json.containsKey('formaPagamento'), isFalse);
      expect(json['especificacoes'], 'Especificações');
    });

    test('EditalDTO.toJson inclui dados da sessão quando informados', () {
      final json = EditalDTO(
        numeroEdital: '2026/07',
        dataAberturaSessao: '2026-10-15',
        horarioAbertura: '09:00',
        formaEntregaPropostas: 'PRESENCIAL',
      ).toJson();

      expect(json['dataAberturaSessao'], '2026-10-15');
      expect(json['horarioAbertura'], '09:00');
      expect(json['formaEntregaPropostas'], 'PRESENCIAL');
      expect(json.containsKey('anexos'), isFalse);
    });

    test('AprovacaoDocumentoDTO.toJson expõe o responsável', () {
      expect(
        AprovacaoDocumentoDTO(responsavel: 'Carlos Analista').toJson(),
        {'responsavel': 'Carlos Analista'},
      );
    });
  });

  group('LicitacoesRemoteDataSource · planejamento', () {
    test('getPlanejamento busca o endpoint e converte o retorno', () async {
      final adapter = _RegistroAdapter(
          corpo: _planejamentoJson(etp: _etpJson(), tr: _trJson(), edital: null));
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      final resultado =
          await datasource.getPlanejamento('licitacao-1');

      expect(adapter.requisicoes.single.options.path,
          '/licitacoes/licitacao-1/planejamento');
      expect(adapter.requisicoes.single.options.method, 'GET');
      expect(resultado.licitacaoId, 'licitacao-1');
      expect(resultado.etp!.status, 'RASCUNHO');
      expect(resultado.edital, isNull);
    });

    test('salvarEtp envia PUT com o corpo do ETP', () async {
      final adapter = _RegistroAdapter(
          corpo: _planejamentoJson(etp: _etpJson(), tr: null, edital: null));
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      await datasource.salvarEtp(
        'licitacao-1',
        EtpDTO(objeto: 'Novo objeto', justificativa: 'Justificativa', requisitos: 'Requisitos'),
      );

      final envio = adapter.requisicoes.single;
      expect(envio.options.path, '/licitacoes/licitacao-1/planejamento/etp');
      expect(envio.options.method, 'PUT');
      expect(envio.corpo!['objeto'], 'Novo objeto');
    });

    test('aprovarEtp envia POST com o responsável', () async {
      final adapter = _RegistroAdapter(corpo: _planejamentoJson(tr: null, edital: null));
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      await datasource.aprovarEtp(
          'licitacao-1', AprovacaoDocumentoDTO(responsavel: 'Ana Gestora'));

      final envio = adapter.requisicoes.single;
      expect(envio.options.path,
          '/licitacoes/licitacao-1/planejamento/etp/aprovar');
      expect(envio.options.method, 'POST');
      expect(envio.corpo!['responsavel'], 'Ana Gestora');
    });

    test('publicarEdital envia POST sem corpo', () async {
      final adapter = _RegistroAdapter(corpo: _planejamentoJson(tr: null, edital: null));
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      await datasource.publicarEdital('licitacao-1');

      final envio = adapter.requisicoes.single;
      expect(envio.options.path,
          '/licitacoes/licitacao-1/planejamento/edital/publicar');
      expect(envio.options.method, 'POST');
    });

    test('lança exceção quando o servidor falha', () async {
      final adapter =
          _RegistroAdapter(corpo: null, statusCode: 500);
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      await expectLater(
        datasource.getPlanejamento('licitacao-1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('LicitacoesProvider · planejamento', () {
    test('carregarPlanejamento popula o mapa e retorna true', () async {
      final provider = LicitacoesProvider(
        LicitacoesRepository(
          remoteDataSource: _FakeLicitacoesDatasource(
            planejamento: PlanejamentoLicitacaoModel.fromJson(
              _planejamentoJson(etp: _etpJson(), tr: null, edital: null),
            ),
          ),
        ),
      );

      final ok = await provider.carregarPlanejamento('licitacao-1');

      expect(ok, isTrue);
      expect(provider.planejamento('licitacao-1'), isNotNull);
      expect(provider.planejamento('licitacao-1')!.etp, isNotNull);
    });

    test('salvarEtp atualiza o planejamento em memória', () async {
      final fake = _FakeLicitacoesDatasource(
        planejamento: PlanejamentoLicitacaoModel.fromJson(
          _planejamentoJson(etp: _etpJson(), tr: null, edital: null),
        ),
      );
      final provider =
          LicitacoesProvider(LicitacoesRepository(remoteDataSource: fake));
      await provider.carregarPlanejamento('licitacao-1');

      final ok = await provider.salvarEtp(
        'licitacao-1',
        EtpDTO(objeto: 'Objeto revisado', justificativa: 'J', requisitos: 'R'),
      );

      expect(ok, isTrue);
      expect(
        provider.planejamento('licitacao-1')!.etp!.objeto,
        'Objeto revisado',
      );
    });

    test('falha ao salvar define errorMessage e retorna false', () async {
      final provider = LicitacoesProvider(
        LicitacoesRepository(
          remoteDataSource: _FakeLicitacoesDatasource(falhar: true),
        ),
      );

      final ok = await provider.salvarEtp(
        'licitacao-1',
        EtpDTO(objeto: 'Objeto', justificativa: 'J', requisitos: 'R'),
      );

      expect(ok, isFalse);
      expect(provider.errorMessage, contains('salvar o ETP'));
    });

    test('planejamentosPendentes considera licitações em elaboração sem '
        'edital publicado', () async {
      final fake = _FakeLicitacoesDatasource(
        planejamento: PlanejamentoLicitacaoModel.fromJson(
          _planejamentoJson(
            etp: _etpJson(status: 'APROVADO'),
            tr: _trJson(status: 'APROVADO'),
            edital: null,
          ),
        ),
      );
      final provider =
          LicitacoesProvider(LicitacoesRepository(remoteDataSource: fake));

      await provider.carregarTudo();

      expect(provider.licitacoes, hasLength(1));
      expect(provider.licitacoes.first.emElaboracao, isTrue);
      expect(provider.planejamentosPendentes, hasLength(1));
      expect(provider.planejamentosEmElaboracaoPendentes, isTrue);
    });
  });
}

// ============================ HELPERS DE JSON ============================

Map<String, dynamic> _planejamentoJson({
  Map<String, dynamic>? etp,
  Map<String, dynamic>? tr,
  Map<String, dynamic>? edital,
}) =>
    {
      'licitacaoId': 'licitacao-1',
      'numero': 'LIC 2026/001',
      'licitacaoStatus': 'EM_ELABORACAO',
      'etp': etp,
      'tr': tr,
      'edital': edital,
    };

Map<String, dynamic> _etpJson({
  String status = 'RASCUNHO',
  String responsavel = '',
}) =>
    {
      'id': 'etp-1',
      'objeto': 'Aquisição de cadeiras executivas',
      'justificativa': 'Renovação do mobiliário',
      'requisitos': 'Conforto e durabilidade',
      'alternativas': 'Locação',
      'valorEstimado': 45000.5,
      'riscos': 'Atraso na entrega',
      'conclusao': 'Viável',
      'responsavel': responsavel,
      'status': status,
    };

Map<String, dynamic> _trJson({
  String status = 'RASCUNHO',
  String responsavel = '',
}) =>
    {
      'id': 'tr-1',
      'especificacoes': 'Cadeiras com espuma injetada',
      'condicoesFornecimento': 'Entrega em 30 dias',
      'obrigacoes': 'Instalação incluída',
      'criteriosAceitacao': 'Garantia de 12 meses',
      'prazosEntrega': 'Até 30 dias',
      'garantia': '12 meses',
      'formaPagamento': '30 dias após nota',
      'responsavel': responsavel,
      'status': status,
    };

Map<String, dynamic> _editalJson({
  String status = 'EM_ELABORACAO',
  String formaEntregaPropostas = '',
}) =>
    {
      'id': 'edital-1',
      'numeroProcesso': '2026/0999',
      'numeroEdital': '2026/07',
      'localSessao': 'Sala de reuniões',
      'dataAberturaSessao': '2026-10-15',
      'horarioAbertura': '09:00',
      'formaEntregaPropostas': formaEntregaPropostas,
      'anexos': 'Modelo de proposta',
      'observacoes': 'Sessão híbrida',
      'status': status,
    };

// ============================ FAKE / ADAPTER ============================

class _FakeLicitacoesDatasource extends LicitacoesRemoteDataSource {
  _FakeLicitacoesDatasource({
    PlanejamentoLicitacaoModel? planejamento,
    this.falhar = false,
  })  : _planejamento = planejamento,
        super(DioClient());

  PlanejamentoLicitacaoModel? _planejamento;
  final bool falhar;

  @override
  Future<List<LicitacaoModel>> getLicitacoes() async => [
        LicitacaoModel.fromJson({
          'id': 'licitacao-1',
          'numero': 'LIC 2026/001',
          'modalidade': 'PREGAO',
          'tipoJulgamento': 'MENOR_PRECO',
          'status': 'EM_ELABORACAO',
        }),
      ];

  @override
  Future<PlanejamentoLicitacaoModel> getPlanejamento(String id) async {
    if (falhar || _planejamento == null) {
      throw Exception('Falha ao carregar o planejamento: erro simulado');
    }
    return _planejamento!;
  }

  @override
  Future<PlanejamentoLicitacaoModel> salvarEtp(String id, EtpDTO dto) async {
    if (falhar) throw Exception('Falha ao salvar o ETP: erro simulado');
    _planejamento = PlanejamentoLicitacaoModel.fromJson({
      ..._planejamentoJson(tr: null, edital: null),
      'etp': {..._etpJson(), 'objeto': dto.objeto, 'justificativa': dto.justificativa},
    });
    return _planejamento!;
  }

  @override
  Future<PlanejamentoLicitacaoModel> aprovarEtp(
          String id, AprovacaoDocumentoDTO dto) async =>
      _salvarTurma(dto);

  PlanejamentoLicitacaoModel _salvarTurma(AprovacaoDocumentoDTO dto) {
    if (falhar) throw Exception('Falha na ação simulada');
    return _planejamento!;
  }

  @override
  Future<PlanejamentoLicitacaoModel> salvarTr(String id, TrDTO dto) async =>
      _salvarTurma(AprovacaoDocumentoDTO(responsavel: ''));

  @override
  Future<PlanejamentoLicitacaoModel> aprovarTr(
          String id, AprovacaoDocumentoDTO dto) async =>
      _salvarTurma(dto);

  @override
  Future<PlanejamentoLicitacaoModel> salvarEdital(
          String id, EditalDTO dto) async =>
      _salvarTurma(AprovacaoDocumentoDTO(responsavel: ''));

  @override
  Future<PlanejamentoLicitacaoModel> publicarEdital(String id) async =>
      _salvarTurma(AprovacaoDocumentoDTO(responsavel: ''));
}

class _RegistroAdapter implements HttpClientAdapter {
  _RegistroAdapter({required Map<String, dynamic>? corpo, this.statusCode = 200})
      : _corpo = corpo;

  final Map<String, dynamic>? _corpo;
  final int statusCode;
  final List<Req> requisicoes = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    await requestStream?.forEach(bytes.addAll);
    Map<String, dynamic>? corpo;
    if (bytes.isNotEmpty) {
      corpo = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    }
    requisicoes.add((options: options, corpo: corpo));

    if (statusCode != 200 || _corpo == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: statusCode,
          data: {'message': 'Erro simulado'},
          headers: Headers(),
        ),
      );
    }

    return ResponseBody.fromString(
      jsonEncode(_corpo),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

typedef Req = ({RequestOptions options, Map<String, dynamic>? corpo});