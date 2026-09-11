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
  group('Modelo · lances da disputa', () {
    test('LanceModel.fromJson expõe campos e data formatada', () {
      final lance = LanceModel.fromJson({
        'id': 'lance-1',
        'licitacaoItemId': 'item-1',
        'itemDescricao': 'Cadeira executiva',
        'fornecedorId': 'forn-1',
        'fornecedorNome': 'Móveis Ltda',
        'valorUnitario': 180.5,
        'valorEstimadoUnitario': 210.0,
        'economia': 29.5,
        'observacao': 'Lance válido',
        'atualizadoEm': '2026-09-10T15:30:00',
      });

      expect(lance.id, 'lance-1');
      expect(lance.licitacaoItemId, 'item-1');
      expect(lance.itemDescricao, 'Cadeira executiva');
      expect(lance.fornecedorNome, 'Móveis Ltda');
      expect(lance.valorUnitario, 180.5);
      expect(lance.valorEstimadoUnitario, 210.0);
      expect(lance.economia, 29.5);
      expect(lance.observacao, 'Lance válido');
      expect(lance.atualizadoEmFormatado, '10/09/2026');
    });

    test('LicitacaoModel.fromJson carrega a lista de lances', () {
      final licitacao = LicitacaoModel.fromJson(_licitacaoJson(lances: [
        _lanceJson(valorUnitario: 180.5),
        _lanceJson(valorUnitario: 195.0, fornecedorId: 'forn-2'),
      ]));

      expect(licitacao.lances, hasLength(2));
      expect(licitacao.totalLances, 2);
      expect(licitacao.economiaTotal, closeTo(44.5, 0.001));
    });

    test('lancesPorItem ordena pelo melhor lance conforme o julgamento', () {
      final menorPreco = LicitacaoModel.fromJson(_licitacaoJson(lances: [
        _lanceJson(valorUnitario: 210.0),
        _lanceJson(valorUnitario: 180.5, fornecedorId: 'forn-2'),
      ]));
      expect(menorPreco.lancesPorItem['item-1']!.first.valorUnitario, 180.5);

      final maiorLance = LicitacaoModel.fromJson(_licitacaoJson(
        tipoJulgamento: 'MAIOR_LANCE',
        lances: [
          _lanceJson(valorUnitario: 500.0),
          _lanceJson(valorUnitario: 750.0, fornecedorId: 'forn-2'),
        ],
      ));
      expect(maiorLance.lancesPorItem['item-1']!.first.valorUnitario, 750.0);
    });

    test('estados emDisputa, emAberta e podeAbrirDisputa', () {
      final publicada =
          LicitacaoModel.fromJson(_licitacaoJson(status: 'PUBLICADA'));
      expect(publicada.emDisputa, isTrue);
      expect(publicada.podeAbrirDisputa, isTrue);
      expect(publicada.emAberta, isFalse);

      final aberta = LicitacaoModel.fromJson(_licitacaoJson(status: 'ABERTA'));
      expect(aberta.emDisputa, isTrue);
      expect(aberta.podeAbrirDisputa, isFalse);
      expect(aberta.emAberta, isTrue);
    });
  });

  group('LicitacoesRemoteDataSource · disputa', () {
    test('abrirDisputa envia POST e converte o retorno', () async {
      final adapter = _RegistroAdapter(corpo: _licitacaoJson(status: 'ABERTA'));
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      final resultado = await datasource.abrirDisputa('licitacao-1');

      final envio = adapter.requisicoes.single;
      expect(envio.options.path, '/licitacoes/licitacao-1/abrir-disputa');
      expect(envio.options.method, 'POST');
      expect(envio.corpo, isNull);
      expect(resultado.status, 'ABERTA');
      expect(resultado.emAberta, isTrue);
    });

    test('registrarLance envia o corpo com item, fornecedor e valor', () async {
      final adapter = _RegistroAdapter(
          corpo: _licitacaoJson(
        status: 'ABERTA',
        lances: [
          _lanceJson(valorUnitario: 180.5),
        ],
      ));
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      final resultado = await datasource.registrarLance(
        'licitacao-1',
        RegistrarLanceDTO(
          licitacaoItemId: 'item-1',
          fornecedorId: 'forn-1',
          valorUnitario: 180.5,
          observacao: 'Lance válido',
        ),
      );

      final envio = adapter.requisicoes.single;
      expect(envio.options.path, '/licitacoes/licitacao-1/lances');
      expect(envio.options.method, 'POST');
      expect(envio.corpo, {
        'licitacaoItemId': 'item-1',
        'fornecedorId': 'forn-1',
        'valorUnitario': 180.5,
        'observacao': 'Lance válido',
      });
      expect(resultado.totalLances, 1);
      expect(resultado.lances.first.valorUnitario, 180.5);
    });

    test('listarLances faz GET e retorna a lista de lances', () async {
      final adapter = _RegistroAdapter(
        corpo: [_lanceJson(valorUnitario: 180.5), _lanceJson(valorUnitario: 195.0)],
        lista: true,
      );
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      final lances = await datasource.listarLances('licitacao-1');

      final envio = adapter.requisicoes.single;
      expect(envio.options.path, '/licitacoes/licitacao-1/lances');
      expect(envio.options.method, 'GET');
      expect(lances, hasLength(2));
    });

    test('abrirDisputa lança exceção quando o servidor falha', () async {
      final adapter = _RegistroAdapter(corpo: null, statusCode: 500);
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      await expectLater(
        datasource.abrirDisputa('licitacao-1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('LicitacoesProvider · disputa', () {
    test('abrirDisputa atualiza o status para ABERTA', () async {
      final fake =
          _FakeDisputaDatasource(_licitacaoJson(status: 'PUBLICADA'));
      final provider =
          LicitacoesProvider(LicitacoesRepository(remoteDataSource: fake));

      await provider.carregarTudo();
      expect(provider.licitacoes.single.emAberta, isFalse);

      final ok = await provider.abrirDisputa('licitacao-1');

      expect(ok, isTrue);
      expect(provider.licitacoes.single.status, 'ABERTA');
      expect(provider.licitacoes.single.podeAbrirDisputa, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('registrarLance atualiza os lances e preenche o cache', () async {
      final fake = _FakeDisputaDatasource(_licitacaoJson(status: 'ABERTA'));
      final provider =
          LicitacoesProvider(LicitacoesRepository(remoteDataSource: fake));

      await provider.carregarTudo();

      final ok = await provider.registrarLance(
        'licitacao-1',
        RegistrarLanceDTO(
          licitacaoItemId: 'item-1',
          fornecedorId: 'forn-1',
          valorUnitario: 180.5,
        ),
      );

      expect(ok, isTrue);
      expect(provider.licitacoes.single.totalLances, 1);
      expect(provider.lances('licitacao-1'), hasLength(1));
    });

    test('falha ao registrar lance define errorMessage e retorna false',
        () async {
      final fake = _FakeDisputaDatasource(
        _licitacaoJson(status: 'ABERTA'),
        falharLance: true,
      );
      final provider =
          LicitacoesProvider(LicitacoesRepository(remoteDataSource: fake));

      await provider.carregarTudo();

      final ok = await provider.registrarLance(
        'licitacao-1',
        RegistrarLanceDTO(
          licitacaoItemId: 'item-1',
          fornecedorId: 'forn-1',
          valorUnitario: 180.5,
        ),
      );

      expect(ok, isFalse);
      expect(provider.errorMessage, contains('lance'));
    });
  });
}

// ============================ HELPERS DE JSON ============================

Map<String, dynamic> _lanceJson({
  String id = 'lance-1',
  String fornecedorId = 'forn-1',
  String fornecedorNome = 'Móveis Ltda',
  double valorUnitario = 180.5,
  double? valorEstimadoUnitario = 210.0,
  double? economia,
  String itemDescricao = 'Cadeira executiva',
}) {
  final economiaFinal = economia ??
      (valorEstimadoUnitario != null
          ? valorEstimadoUnitario - valorUnitario
          : null);
  return {
    'id': id,
    'licitacaoItemId': 'item-1',
    'itemDescricao': itemDescricao,
    'fornecedorId': fornecedorId,
    'fornecedorNome': fornecedorNome,
    'valorUnitario': valorUnitario,
    if (valorEstimadoUnitario != null) 'valorEstimadoUnitario': valorEstimadoUnitario,
    if (economiaFinal != null) 'economia': economiaFinal,
    'atualizadoEm': '2026-09-10T15:30:00',
  };
}

Map<String, dynamic> _licitacaoJson({
  String status = 'ABERTA',
  String tipoJulgamento = 'MENOR_PRECO',
  List<Map<String, dynamic>>? lances = const [],
}) =>
    {
      'id': 'licitacao-1',
      'tenantId': 'tenant-1',
      'numero': 'LIC 2026/001',
      'modalidade': 'PREGAO',
      'tipoJulgamento': tipoJulgamento,
      'objeto': 'Aquisição de cadeiras executivas',
      'status': status,
      'itens': [
        {
          'id': 'item-1',
          'materialId': 'mat-1',
          'descricao': 'Cadeira executiva',
          'quantidade': 10,
          'valorEstimadoUnitario': 210.0,
          'valorEstimadoTotal': 2100.0,
          'unidadeMedida': 'UN',
        },
      ],
      'participantes': [
        {
          'fornecedorId': 'forn-1',
          'fornecedorNome': 'Móveis Ltda',
          'habilitado': true,
        },
        {
          'fornecedorId': 'forn-2',
          'fornecedorNome': 'Escritórios SA',
          'habilitado': true,
        },
      ],
      'lances': lances ?? const [],
    };

// ============================ FAKE / ADAPTER ============================

class _FakeDisputaDatasource extends LicitacoesRemoteDataSource {
  _FakeDisputaDatasource(this._licitacaoJson, {this.falharLance = false})
      : super(DioClient());

  Map<String, dynamic> _licitacaoJson;
  final bool falharLance;

  @override
  Future<List<LicitacaoModel>> getLicitacoes() async =>
      [LicitacaoModel.fromJson(_licitacaoJson)];

  @override
  Future<PlanejamentoLicitacaoModel> getPlanejamento(String id) async =>
      throw Exception('Indisponível no teste');

  @override
  Future<LicitacaoModel> abrirDisputa(String id) async {
    _licitacaoJson = {..._licitacaoJson, 'status': 'ABERTA'};
    return LicitacaoModel.fromJson(_licitacaoJson);
  }

  @override
  Future<LicitacaoModel> registrarLance(String id, RegistrarLanceDTO dto) async {
    if (falharLance) throw Exception('Falha ao registrar o lance');
    _licitacaoJson = {
      ..._licitacaoJson,
      'lances': [_lanceJson(valorUnitario: dto.valorUnitario)],
    };
    return LicitacaoModel.fromJson(_licitacaoJson);
  }

  @override
  Future<List<LanceModel>> listarLances(String id) async =>
      (LicitacaoModel.fromJson(_licitacaoJson)).lances;
}

class _RegistroAdapter implements HttpClientAdapter {
  _RegistroAdapter({
    required dynamic corpo,
    this.statusCode = 200,
    this.lista = false,
  }) : _corpo = corpo;

  final dynamic _corpo;
  final int statusCode;
  final bool lista;
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
      lista ? jsonEncode(_corpo as List) : jsonEncode(_corpo),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

typedef Req = ({RequestOptions options, Map<String, dynamic>? corpo});