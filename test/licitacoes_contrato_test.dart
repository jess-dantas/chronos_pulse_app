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
  group('Modelo · formalização do contrato', () {
    test('LicitacaoModel.fromJson carrega contratoGerado e formalizavel', () {
      final homologada = LicitacaoModel.fromJson(_licitacaoJson(status: 'HOMOLOGADA'));
      expect(homologada.homologada, isTrue);
      expect(homologada.contratoGerado, isFalse);
      expect(homologada.formalizavel, isTrue);

      final formalizada = LicitacaoModel.fromJson(
          _licitacaoJson(status: 'HOMOLOGADA', contratoGerado: true));
      expect(formalizada.contratoGerado, isTrue);
      expect(formalizada.formalizavel, isFalse);

      final emDisputa =
          LicitacaoModel.fromJson(_licitacaoJson(status: 'ADJUDICADA'));
      expect(emDisputa.formalizavel, isFalse);
    });

    test('valorTotalVencedores soma quantidade x valor dos vencedores', () {
      final licitacao = LicitacaoModel.fromJson(
        _licitacaoJson(
          status: 'HOMOLOGADA',
          itens: [
            _itemJson(materialId: 'mat-1', quantidade: 10, valorEstimadoUnitario: 210.0),
            _itemJson(materialId: 'mat-2', quantidade: 5, valorEstimadoUnitario: 80.0),
          ],
          propostas: [
            _propostaJson(materialId: 'mat-1', valorUnitario: 180.5, vencedor: true),
            _propostaJson(materialId: 'mat-2', valorUnitario: 75.0, vencedor: true),
            _propostaJson(
                materialId: 'mat-1', valorUnitario: 200.0, vencedor: false),
          ],
        ),
      );

      expect(licitacao.vencedores, hasLength(2));
      expect(licitacao.valorTotalVencedores, closeTo(2180.0, 0.001));
    });

    test('FormalizarContratoDTO.toJson monta o corpo da requisição', () {
      final dto = FormalizarContratoDTO(
        dataInicio: '2026-09-20',
        dataFim: '2027-09-19',
        observacoes: 'Vigência de 12 meses',
        empenhoNumero: 'EMP-2026-0001',
        valorEmpenhado: 2175.0,
      );

      expect(dto.toJson(), {
        'dataInicio': '2026-09-20',
        'dataFim': '2027-09-19',
        'observacoes': 'Vigência de 12 meses',
        'empenhoNumero': 'EMP-2026-0001',
        'valorEmpenhado': 2175.0,
      });

      final minimo = FormalizarContratoDTO(dataInicio: 'a', dataFim: 'b');
      expect(minimo.toJson(), {'dataInicio': 'a', 'dataFim': 'b'});
    });
  });

  group('LicitacoesRemoteDataSource · formalização', () {
    test('formalizarContrato envia POST com os dados de vigência', () async {
      final adapter = _RegistroAdapter(
          corpo: _licitacaoJson(status: 'HOMOLOGADA', contratoGerado: true));
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      final resultado = await datasource.formalizarContrato(
        'licitacao-1',
        FormalizarContratoDTO(
          dataInicio: '2026-09-20',
          dataFim: '2027-09-19',
          observacoes: 'Vigência de 12 meses',
        ),
      );

      final envio = adapter.requisicoes.single;
      expect(envio.options.path, '/licitacoes/licitacao-1/contrato');
      expect(envio.options.method, 'POST');
      expect(envio.corpo, {
        'dataInicio': '2026-09-20',
        'dataFim': '2027-09-19',
        'observacoes': 'Vigência de 12 meses',
      });
      expect(resultado.contratoGerado, isTrue);
      expect(resultado.formalizavel, isFalse);
    });

    test('formalizarContrato lança exceção quando o servidor falha', () async {
      final adapter = _RegistroAdapter(corpo: null, statusCode: 500);
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      await expectLater(
        datasource.formalizarContrato(
          'licitacao-1',
          FormalizarContratoDTO(dataInicio: 'a', dataFim: 'b'),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('LicitacoesProvider · formalização', () {
    test('formalizarContrato marca a licitação como formalizada', () async {
      final fake = _FakeContratoDatasource(_licitacaoJson(status: 'HOMOLOGADA'));
      final provider =
          LicitacoesProvider(LicitacoesRepository(remoteDataSource: fake));

      await provider.carregarTudo();
      expect(provider.licitacoes.single.formalizavel, isTrue);

      final ok = await provider.formalizarContrato(
        'licitacao-1',
        FormalizarContratoDTO(dataInicio: '2026-09-20', dataFim: '2027-09-19'),
      );

      expect(ok, isTrue);
      expect(provider.licitacoes.single.contratoGerado, isTrue);
      expect(provider.licitacoes.single.formalizavel, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('falha ao formalizar define errorMessage e retorna false', () async {
      final fake = _FakeContratoDatasource(
        _licitacaoJson(status: 'HOMOLOGADA'),
        falhar: true,
      );
      final provider =
          LicitacoesProvider(LicitacoesRepository(remoteDataSource: fake));

      await provider.carregarTudo();

      final ok = await provider.formalizarContrato(
        'licitacao-1',
        FormalizarContratoDTO(dataInicio: '2026-09-20', dataFim: '2027-09-19'),
      );

      expect(ok, isFalse);
      expect(provider.errorMessage, contains('contrato'));
    });
  });
}

// ============================ HELPERS DE JSON ============================

Map<String, dynamic> _itemJson({
  String id = 'item-1',
  required String materialId,
  required double quantidade,
  required double valorEstimadoUnitario,
}) =>
    {
      'id': id,
      'materialId': materialId,
      'descricao': 'Material $materialId',
      'quantidade': quantidade,
      'valorEstimadoUnitario': valorEstimadoUnitario,
      'valorEstimadoTotal': quantidade * valorEstimadoUnitario,
      'unidadeMedida': 'UN',
    };

Map<String, dynamic> _propostaJson({
  String id = 'prop-1',
  required String materialId,
  required double valorUnitario,
  required bool vencedor,
}) =>
    {
      'id': id,
      'fornecedorId': 'forn-1',
      'fornecedorNome': 'Móveis Ltda',
      'materialId': materialId,
      'materialDescricao': 'Material $materialId',
      'valorUnitario': valorUnitario,
      'vencedor': vencedor,
    };

Map<String, dynamic> _licitacaoJson({
  String status = 'HOMOLOGADA',
  bool contratoGerado = false,
  List<Map<String, dynamic>>? itens,
  List<Map<String, dynamic>>? propostas,
}) =>
    {
      'id': 'licitacao-1',
      'tenantId': 'tenant-1',
      'numero': 'LIC 2026/001',
      'modalidade': 'PREGAO',
      'tipoJulgamento': 'MENOR_PRECO',
      'objeto': 'Aquisição de cadeiras executivas',
      'status': status,
      'contratoGerado': contratoGerado,
      'itens': itens ??
          [
            _itemJson(
                materialId: 'mat-1', quantidade: 10, valorEstimadoUnitario: 210.0),
          ],
      'participantes': [
        {
          'fornecedorId': 'forn-1',
          'fornecedorNome': 'Móveis Ltda',
          'habilitado': true,
        },
      ],
      'propostas': propostas ??
          [
            _propostaJson(
                materialId: 'mat-1', valorUnitario: 180.5, vencedor: true),
          ],
    };

// ============================ FAKE / ADAPTER ============================

class _FakeContratoDatasource extends LicitacoesRemoteDataSource {
  _FakeContratoDatasource(this._licitacaoJson, {this.falhar = false})
      : super(DioClient());

  Map<String, dynamic> _licitacaoJson;
  final bool falhar;

  @override
  Future<List<LicitacaoModel>> getLicitacoes() async =>
      [LicitacaoModel.fromJson(_licitacaoJson)];

  @override
  Future<PlanejamentoLicitacaoModel> getPlanejamento(String id) async =>
      throw Exception('Indisponível no teste');

  @override
  Future<LicitacaoModel> formalizarContrato(String id, FormalizarContratoDTO dto) async {
    if (falhar) throw Exception('Falha ao formalizar o contrato');
    _licitacaoJson = {..._licitacaoJson, 'contratoGerado': true};
    return LicitacaoModel.fromJson(_licitacaoJson);
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