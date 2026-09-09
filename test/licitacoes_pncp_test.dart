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
  group('Modelo · campos PNCP', () {
    test('fromJson com aviso publicado no PNCP expõe protocolo e rótulo',
        () {
      final licitacao = LicitacaoModel.fromJson(
        _licitacaoJson(
          status: 'PUBLICADA',
          pncpStatus: 'PUBLICADO',
          pncpProtocolo: 'PNCP-2026-00001',
          pncpPublicadoEm: '2026-09-09T10:30:00',
          pncpErro: '',
        ),
      );

      expect(licitacao.pncpStatus, 'PUBLICADO');
      expect(licitacao.pncpProtocolo, 'PNCP-2026-00001');
      expect(licitacao.pncpPublicado, isTrue);
      expect(licitacao.pncpFalhou, isFalse);
      expect(licitacao.pncpStatusLabel, 'Publicado no PNCP');
      expect(licitacao.pncpPublicadoEmFormatado, '09/09/2026');
    });

    test('padrão sem exposição é NAO_PUBLICADO', () {
      final licitacao = LicitacaoModel.fromJson(_licitacaoJson());

      expect(licitacao.pncpStatus, 'NAO_PUBLICADO');
      expect(licitacao.pncpPublicado, isFalse);
      expect(licitacao.pncpFalhou, isFalse);
      expect(licitacao.pncpStatusLabel, 'Não publicado no PNCP');
    });

    test('FALHA registra erro e permite nova tentativa', () {
      final licitacao = LicitacaoModel.fromJson(
        _licitacaoJson(
          status: 'ABERTA',
          pncpStatus: 'FALHA',
          pncpProtocolo: '',
          pncpPublicadoEm: '',
          pncpErro: 'Falha de autenticação no PNCP',
        ),
      );

      expect(licitacao.pncpFalhou, isTrue);
      expect(licitacao.pncpPublicado, isFalse);
      expect(licitacao.pncpErro, 'Falha de autenticação no PNCP');
      expect(licitacao.pncpStatusLabel, 'Falha no PNCP');
    });
  });

  group('LicitacoesRemoteDataSource · publicarPncp', () {
    test('envia POST para o endpoint PNCP e converte o retorno', () async {
      final adapter = _RegistroAdapter(
        corpo: _licitacaoJson(
          status: 'ABERTA',
          pncpStatus: 'PUBLICADO',
          pncpProtocolo: 'PNCP-2026-00042',
          pncpPublicadoEm: '2026-09-09T11:05:00',
        ),
      );
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      final resultado = await datasource.publicarPncp('licitacao-1');

      final envio = adapter.requisicoes.single;
      expect(envio.options.path, '/licitacoes/licitacao-1/publicar-pncp');
      expect(envio.options.method, 'POST');
      expect(envio.corpo, isNull);
      expect(resultado.pncpStatus, 'PUBLICADO');
      expect(resultado.pncpProtocolo, 'PNCP-2026-00042');
    });

    test('lança exceção quando o servidor falha', () async {
      final adapter = _RegistroAdapter(corpo: null, statusCode: 500);
      final dioClient = DioClient(initialToken: 'token-teste')
        ..dio.httpClientAdapter = adapter;
      final datasource = LicitacoesRemoteDataSource(dioClient);

      await expectLater(
        datasource.publicarPncp('licitacao-1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('LicitacoesProvider · publicarPncp', () {
    test('publica o aviso e recarrega a lista com o protocolo', () async {
      final fake = _FakePncpDatasource(_licitacaoJson(status: 'PUBLICADA'));
      final provider =
          LicitacoesProvider(LicitacoesRepository(remoteDataSource: fake));

      final ok = await provider.publicarPncp('licitacao-1');

      expect(ok, isTrue);
      expect(provider.licitacoes, hasLength(1));
      expect(provider.licitacoes.single.pncpPublicado, isTrue);
      expect(provider.licitacoes.single.pncpProtocolo, 'PNCP-2026-00042');
    });

    test('falha define errorMessage e retorna false', () async {
      final provider = LicitacoesProvider(
        LicitacoesRepository(
          remoteDataSource: _FakePncpDatasource(_licitacaoJson(), falhar: true),
        ),
      );

      final ok = await provider.publicarPncp('licitacao-1');

      expect(ok, isFalse);
      expect(provider.errorMessage, contains('PNCP'));
    });
  });
}

// ============================ HELPERS DE JSON ============================

Map<String, dynamic> _licitacaoJson({
  String status = 'EM_ELABORACAO',
  String pncpStatus = 'NAO_PUBLICADO',
  String pncpProtocolo = '',
  String pncpPublicadoEm = '',
  String pncpErro = '',
}) =>
    {
      'id': 'licitacao-1',
      'tenantId': 'tenant-1',
      'numero': 'LIC 2026/001',
      'modalidade': 'PREGAO',
      'tipoJulgamento': 'MENOR_PRECO',
      'objeto': 'Aquisição de cadeiras executivas',
      'status': status,
      'pncpStatus': pncpStatus,
      if (pncpProtocolo.isNotEmpty) 'pncpProtocolo': pncpProtocolo,
      if (pncpPublicadoEm.isNotEmpty) 'pncpPublicadoEm': pncpPublicadoEm,
      if (pncpErro.isNotEmpty) 'pncpErro': pncpErro,
    };

// ============================ FAKE / ADAPTER ============================

class _FakePncpDatasource extends LicitacoesRemoteDataSource {
  _FakePncpDatasource(this._licitacaoJson, {this.falhar = false})
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
  Future<LicitacaoModel> publicarPncp(String id) async {
    if (falhar) throw Exception('Falha ao publicar o aviso no PNCP');
    _licitacaoJson = {
      ..._licitacaoJson,
      'status': 'ABERTA',
      'pncpStatus': 'PUBLICADO',
      'pncpProtocolo': 'PNCP-2026-00042',
      'pncpPublicadoEm': '2026-09-09T11:05:00',
    };
    return LicitacaoModel.fromJson(_licitacaoJson);
  }
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