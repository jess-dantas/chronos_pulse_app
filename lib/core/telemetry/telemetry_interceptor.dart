import 'package:dio/dio.dart';

import 'telemetry_service.dart';

/// Interceptor de observabilidade (R27): mede latência e resultado de cada
/// requisição HTTP do app e enfileira eventos `API_REQUEST`/`API_ERRO`.
///
/// Não captura corpos nem cabeçalhos de requisição/resposta (LGPD): apenas
/// endpoint, status HTTP, latência e um resumo do tipo de erro.
class TelemetryInterceptor extends Interceptor {
  TelemetryInterceptor({required TelemetryService telemetryService})
      : _telemetryService = telemetryService;

  final TelemetryService _telemetryService;
  final Map<int, Stopwatch> _cronometros = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_devePular(options)) {
      return handler.next(options);
    }
    _cronometros[identityHashCode(options)] = Stopwatch()..start();
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _registrar(response.requestOptions, response.statusCode ?? 200, null);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _registrar(err.requestOptions, err.response?.statusCode, err);
    handler.next(err);
  }

  bool _devePular(RequestOptions options) {
    if (options.method == 'OPTIONS') return true;
    // Evita recursão: a própria ingestão de telemetria não gera evento.
    if (options.path.contains('/telemetria/')) return true;
    return false;
  }

  void _registrar(RequestOptions options, int? statusHttp, DioException? erro) {
    final cronometro = _cronometros.remove(identityHashCode(options));
    if (cronometro == null) {
      // Requisição ignorada (ex.: ingestão de telemetria ou OPTIONS).
      return;
    }
    final path = options.path;

    if (erro == null) {
      _telemetryService.registrar(
        tipo: TipoEventoTelemetria.apiRequest,
        modulo: _moduloPara(path),
        endpoint: path,
        statusHttp: statusHttp,
        latencyMs: cronometro.elapsedMilliseconds,
      );
      return;
    }

    var mensagem = erro.type.name;
    if (erro.response?.statusCode != null) {
      mensagem = '${erro.response!.statusCode} $mensagem';
    }
    _telemetryService.registrar(
      tipo: TipoEventoTelemetria.apiErro,
      modulo: _moduloPara(path),
      endpoint: path,
      statusHttp: erro.response?.statusCode,
      latencyMs: cronometro.elapsedMilliseconds,
      mensagem: _truncar(mensagem, 200),
    );
  }

  /// Deduz o módulo a partir do primeiro segmento do endpoint.
  /// Ex.: `/estoque/materiais` → `ESTOQUE`; `/auth/login` → `AUTH`.
  static String _moduloPara(String path) {
    final partes = path
        .split('?')
        .first
        .split('/')
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return 'GERAL';
    return partes.first.toUpperCase();
  }

  static String? _truncar(String? valor, int max) {
    if (valor == null) return null;
    return valor.length <= max ? valor : valor.substring(0, max);
  }
}