import 'dart:convert';

import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/features/licitacoes/data/datasources/licitacoes_remote_datasource.dart';
import 'package:chronos_pulse_app/features/licitacoes/data/models/execucao_contrato_models.dart';
import 'package:chronos_pulse_app/features/licitacoes/data/models/licitacoes_models.dart';
import 'package:chronos_pulse_app/features/licitacoes/data/repositories/licitacoes_repository.dart';
import 'package:chronos_pulse_app/features/licitacoes/presentation/providers/licitacoes_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Modelo · execução contratual', () {
    test('ContratoExecucaoModel.fromJson carrega campos e listas aninhadas', () {
      final modelo = ContratoExecucaoModel.fromJson(_execucaoJson());

      expect(modelo.numero, 'CT-LIC-2026-000001');
      expect(modelo.status, 'ATIVO');
      expect(modelo.situacao, 'VIGENTE');
      expect(modelo.aditivos, hasLength(1));
      expect(modelo.apontamentos, hasLength(2));
      expect(modelo.medicoes, hasLength(1));
      expect(modelo.sancoes, hasLength(1));
      expect(modelo.rescisao, isNull);
      expect(modelo.apontamentosAbertos, 1);
      expect(modelo.valorMedidoTotal, closeTo(1000.0, 0.001));
      expect(modelo.valorPagoTotal, closeTo(800.0, 0.001));
    });

    test('ContratoExecucaoModel.fromJson carrega rescisão quando presente', () {
      final modelo =
          ContratoExecucaoModel.fromJson(_execucaoJson(status: 'RESCINDIDO', rescindido: true));

      expect(modelo.rescindido, isTrue);
      expect(modelo.situacao, 'RESCINDIDO');
      expect(modelo.rescisao, isNotNull);
      expect(modelo.rescisao!.tipoLabel, 'Judicial');
      expect(modelo.rescisao!.dataRescisaoFormatada, isNotEmpty);
    });

    test('DTOs enviam corpo esperado (aditivo/apontamento/medição/sanção/rescisão)', () {
      final aditivo = AdicionarAditivoDTO(
        tipo: 'VALOR',
        descricao: 'Acréscimo de 10%',
        novoValorTotal: 13200.0,
      );
      expect(aditivo.toJson(), {
        'tipo': 'VALOR',
        'descricao': 'Acréscimo de 10%',
        'novoValorTotal': 13200.0,
      });

      final prazo = AdicionarAditivoDTO(
        tipo: 'PRAZO',
        descricao: 'Prorrogação',
        prazoAdicionadoDias: 60,
      );
      expect(prazo.toJson(), {
        'tipo': 'PRAZO',
        'descricao': 'Prorrogação',
        'prazoAdicionadoDias': 60,
      });

      final apontamento = AdicionarApontamentoDTO(
        fiscal: 'Maria',
        descricao: 'Prazo não cumprido',
        gravidade: 'GRAVE',
      );
      expect(apontamento.toJson(), {
        'fiscal': 'Maria',
        'descricao': 'Prazo não cumprido',
        'gravidade': 'GRAVE',
      });

      final medicao = RegistrarMedicaoDTO(
        periodo: '2026-07',
        valorMedido: 1000.0,
        valorPago: 800.0,
        pagoEm: '2026-08-01',
      );
      expect(medicao.toJson(), {
        'periodo': '2026-07',
        'valorMedido': 1000.0,
        'valorPago': 800.0,
        'pagoEm': '2026-08-01',
      });

      final sancao = AdicionarSancaoDTO(
        tipo: 'MULTA',
        descricao: 'Multa por atraso',
        percentualMulta: 2.0,
        aplicadaEm: '2026-08-10',
      );
      expect(sancao.toJson(), {
        'tipo': 'MULTA',
        'descricao': 'Multa por atraso',
        'percentualMulta': 2.0,
        'aplicadaEm': '2026-08-10',
      });

      final rescisao = RescindirContratoDTO(
        tipo: 'UNILATERAL',
        motivo: 'Inadimplemento',
        dataRescisao: '2026-09-01',
      );
      expect(rescisao.toJson(), {
        'tipo': 'UNILATERAL',
        'motivo': 'Inadimplemento',
        'dataRescisao': '2026-09-01',
      });
    });
  });

  group('LicitacoesRemoteDataSource · execução contratual', () {
    test('getContratos lista as execuções do tenant', () async {
      final adapter = _RegistroAdapter(corpo: [_execucaoJson()]);
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      final resultados = await datasource.getContratos();

      final envio = adapter.requisicoes.single;
      expect(envio.options.path, '/contratos');
      expect(envio.options.method, 'GET');
      expect(resultados, hasLength(1));
      expect(resultados.single.numero, 'CT-LIC-2026-000001');
    });

    test('getContrato carrega a execução de um contrato', () async {
      final adapter = _RegistroAdapter(corpo: _execucaoJson());
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      final resultado = await datasource.getContrato('contrato-1');

      final envio = adapter.requisicoes.single;
      expect(envio.options.path, '/contratos/contrato-1');
      expect(resultado.situacao, 'VIGENTE');
    });

    test('registrarAditivo envia POST com o corpo', () async {
      final adapter = _RegistroAdapter(corpo: {
        'id': 'aditivo-1',
        'tipo': 'VALOR',
        'descricao': 'Acréscimo',
        'aprovado': true,
      });
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      final resultado = await datasource.registrarAditivo(
        'contrato-1',
        AdicionarAditivoDTO(
          tipo: 'VALOR',
          descricao: 'Acréscimo',
          novoValorTotal: 13200.0,
        ),
      );

      final envio = adapter.requisicoes.single;
      expect(envio.options.path, '/contratos/contrato-1/aditivos');
      expect(envio.options.method, 'POST');
      expect(envio.corpo!['tipo'], 'VALOR');
      expect(envio.corpo!['novoValorTotal'], 13200.0);
      expect(resultado.aprovado, isTrue);
    });

    test('resolverApontamento aciona o endpoint correto', () async {
      final adapter = _RegistroAdapter(corpo: {
        'id': 'apontamento-1',
        'fiscal': 'Maria',
        'descricao': 'Prazo',
        'gravidade': 'GRAVE',
        'resolvido': true,
        'resolvidoEm': '2026-08-01T10:00:00Z',
      });
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      final resultado =
          await datasource.resolverApontamento('contrato-1', 'apontamento-1');

      final envio = adapter.requisicoes.single;
      expect(envio.options.path, '/contratos/contrato-1/apontamentos/apontamento-1/resolver');
      expect(envio.options.method, 'POST');
      expect(resultado.resolvido, isTrue);
    });

    test('registrarMedicao envia POST de medição', () async {
      final adapter = _RegistroAdapter(corpo: {
        'id': 'medicao-1',
        'periodo': '2026-07',
        'valorMedido': 1000.0,
        'valorPago': 800.0,
      });
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      final resultado = await datasource.registrarMedicao(
        'contrato-1',
        RegistrarMedicaoDTO(periodo: '2026-07', valorMedido: 1000.0, valorPago: 800.0),
      );

      final envio = adapter.requisicoes.single;
      expect(envio.options.path, '/contratos/contrato-1/medicoes');
      expect(envio.corpo!['periodo'], '2026-07');
      expect(resultado.valorPago, closeTo(800.0, 0.001));
    });

    test('rescindirContrato envia POST de rescisão', () async {
      final adapter = _RegistroAdapter(corpo: {
        'id': 'rescisao-1',
        'tipo': 'UNILATERAL',
        'motivo': 'Inadimplemento',
        'dataRescisao': '2026-09-01',
      });
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      final resultado = await datasource.rescindirContrato(
        'contrato-1',
        RescindirContratoDTO(
          tipo: 'UNILATERAL',
          motivo: 'Inadimplemento',
          dataRescisao: '2026-09-01',
        ),
      );

      final envio = adapter.requisicoes.single;
      expect(envio.options.path, '/contratos/contrato-1/rescindir');
      expect(resultado.tipo, 'UNILATERAL');
    });

    test('lança exceção em falha de servidor', () async {
      final adapter = _RegistroAdapter(corpo: null, statusCode: 500);
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      await expectLater(
        datasource.getContrato('contrato-1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('LicitacoesProvider · execução contratual', () {
    test('carregarContratos popula a lista de execuções', () async {
      final fake = _FakeExecucaoDatasource();
      final provider =
          LicitacoesProvider(LicitacoesRepository(remoteDataSource: fake));

      final ok = await provider.carregarContratos();

      expect(ok, isTrue);
      expect(provider.contratosExecucao, hasLength(2));
      expect(provider.contratosEmAtencao, 1);
      expect(provider.isLoading, isFalse);
    });

    test('carregarExecucao popula o cache e o erro fica limpo', () async {
      final fake = _FakeExecucaoDatasource();
      final provider =
          LicitacoesProvider(LicitacoesRepository(remoteDataSource: fake));

      await provider.carregarContratos();
      final ok = await provider.carregarExecucao('contrato-1');

      expect(ok, isTrue);
      expect(provider.execucao('contrato-1'), isNotNull);
      expect(provider.execucao('contrato-1')!.numero, 'CT-LIC-2026-000001');
      expect(provider.errorMessage, isNull);
    });

    test('registrarSancao atualiza a execução a partir do servidor', () async {
      final fake = _FakeExecucaoDatasource();
      final provider =
          LicitacoesProvider(LicitacoesRepository(remoteDataSource: fake));

      await provider.carregarExecucao('contrato-1');
      final ok = await provider.registrarSancao(
        'contrato-1',
        AdicionarSancaoDTO(
          tipo: 'MULTA',
          descricao: 'Multa',
          valorMulta: 500.0,
          aplicadaEm: '2026-08-10',
        ),
      );

      expect(ok, isTrue);
      expect(provider.execucao('contrato-1')!.sancoes, hasLength(2));
      expect(provider.isLoading, isFalse);
    });

    test('falha ao carregar contratos define errorMessage e retorna false', () async {
      final fake = _FakeExecucaoDatasource(falhar: true);
      final provider =
          LicitacoesProvider(LicitacoesRepository(remoteDataSource: fake));

      final ok = await provider.carregarContratos();

      expect(ok, isFalse);
      expect(provider.errorMessage, contains('contratos'));
    });
  });
}

// ============================ HELPERS DE JSON ============================

Map<String, dynamic> _apontamentoJson({
  String id = 'apontamento-1',
  bool resolvido = false,
}) =>
    {
      'id': id,
      'fiscal': 'Maria Silva',
      'descricao': 'Prazo de entrega não cumprido',
      'gravidade': 'GRAVE',
      'resolvido': resolvido,
      'resolvidoEm': resolvido ? '2026-08-01T10:00:00Z' : null,
      'criadoEm': '2026-07-01T10:00:00Z',
    };

Map<String, dynamic> _aditivoJson() => {
      'id': 'aditivo-1',
      'tipo': 'PRAZO',
      'descricao': 'Prorrogação de 60 dias',
      'justificativa': 'Necessidade de entrega',
      'prazoAdicionadoDias': 60,
      'novoValorTotal': null,
      'aprovado': true,
      'criadoEm': '2026-07-15T10:00:00Z',
    };

Map<String, dynamic> _medicaoJson() => {
      'id': 'medicao-1',
      'periodo': '2026-07',
      'valorMedido': 1000.0,
      'valorPago': 800.0,
      'pagoEm': '2026-08-01',
      'observacao': null,
      'criadoEm': '2026-08-01T10:00:00Z',
    };

Map<String, dynamic> _sancaoJson() => {
      'id': 'sancao-1',
      'tipo': 'MULTA',
      'baseLegal': 'Art. 155 da Lei 14.133/2021',
      'descricao': 'Multa por atraso',
      'percentualMulta': 2.0,
      'valorMulta': null,
      'aplicadaEm': '2026-08-10',
      'criadoEm': '2026-08-10T10:00:00Z',
    };

Map<String, dynamic> _rescisaoJson() => {
      'id': 'rescisao-1',
      'tipo': 'JUDICIAL',
      'motivo': 'Decisão judicial',
      'dataRescisao': '2026-09-01',
      'criadoEm': '2026-09-01T10:00:00Z',
    };

Map<String, dynamic> _execucaoJson({
  String status = 'ATIVO',
  bool rescindido = false,
}) =>
    {
      'id': 'contrato-1',
      'numero': 'CT-LIC-2026-000001',
      'objeto': 'Fornecimento referente à LIC 2026/001 — cadeiras executivas',
      'dataInicio': '2026-09-20',
      'dataFim': '2027-09-19',
      'valorMensal': 1000.0,
      'valorTotal': 12000.0,
      'valorEmpenhado': 12000.0,
      'valorLiquidado': 800.0,
      'empenhoNumero': 'EMP-2026-0001',
      'status': status,
      'situacao': rescindido ? 'RESCINDIDO' : 'VIGENTE',
      'diasParaVencimento': 180,
      'atrasado': false,
      'observacoes': null,
      'licitacaoId': 'licitacao-1',
      'aditivos': [_aditivoJson()],
      'apontamentos': [
        _apontamentoJson(),
        _apontamentoJson(id: 'apontamento-2', resolvido: true),
      ],
      'medicoes': [_medicaoJson()],
      'sancoes': [_sancaoJson()],
      'rescisao': rescindido ? _rescisaoJson() : null,
    };

Map<String, dynamic> _execucaoJson2() => {
      'id': 'contrato-2',
      'numero': 'CT-LIC-2026-000002',
      'objeto': 'Prestação de serviços de limpeza',
      'dataInicio': '2026-01-01',
      'dataFim': '2026-08-15',
      'valorMensal': 2000.0,
      'valorTotal': 24000.0,
      'valorEmpenhado': 24000.0,
      'valorLiquidado': 20000.0,
      'empenhoNumero': 'EMP-2026-0002',
      'status': 'ATIVO',
      'situacao': 'VENCIDO',
      'diasParaVencimento': -26,
      'atrasado': true,
      'observacoes': null,
      'licitacaoId': 'licitacao-2',
      'aditivos': <Map<String, dynamic>>[],
      'apontamentos': <Map<String, dynamic>>[],
      'medicoes': <Map<String, dynamic>>[],
      'sancoes': <Map<String, dynamic>>[],
      'rescisao': null,
    };

// ============================ FAKE / ADAPTER ============================

class _FakeExecucaoDatasource extends LicitacoesRemoteDataSource {
  _FakeExecucaoDatasource({this.falhar = false}) : super(DioClient());

  final bool falhar;
  int _sancoesAdicionais = 0;

  @override
  Future<List<ContratoExecucaoModel>> getContratos() async {
    if (falhar) throw Exception('Falha ao carregar contratos');
    return [_execucaoJson(), _execucaoJson2()].map(ContratoExecucaoModel.fromJson).toList();
  }

  @override
  Future<ContratoExecucaoModel> getContrato(String id) async {
    if (falhar) throw Exception('Falha ao carregar contratos');
    final json = id == 'contrato-2' ? _execucaoJson2() : _execucaoJson();
    if (id == 'contrato-1' && _sancoesAdicionais > 0) {
      final sancoes = (json['sancoes'] as List).cast<Map<String, dynamic>>();
      json['sancoes'] = [...sancoes, _sancaoJson()];
    }
    return ContratoExecucaoModel.fromJson(json);
  }

  @override
  Future<ContratoSancaoModel> registrarSancao(String id, AdicionarSancaoDTO dto) async {
    _sancoesAdicionais++;
    return ContratoSancaoModel.fromJson(_sancaoJson());
  }
}

class _RegistroAdapter implements HttpClientAdapter {
  _RegistroAdapter({required dynamic corpo, this.statusCode = 200})
      : _corpo = corpo;

  final dynamic _corpo;
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