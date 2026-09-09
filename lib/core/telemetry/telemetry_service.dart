import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../network/dio_client.dart';

/// Tipos de evento aceitos pela API de telemetria (mesmos valores do backend).
enum TipoEventoTelemetria {
  loginSucesso('LOGIN_SUCESSO'),
  loginFalha('LOGIN_FALHA'),
  apiRequest('API_REQUEST'),
  apiErro('API_ERRO'),
  uiErro('UI_ERRO'),
  conexaoBd('CONEXAO_BD');

  const TipoEventoTelemetria(this.valor);

  final String valor;
}

class _EventoTelemetria {
  const _EventoTelemetria({
    required this.modulo,
    required this.tipo,
    this.endpoint,
    this.statusHttp,
    this.latencyMs,
    this.mensagem,
    this.detalhe,
    this.plataforma,
  });

  final String modulo;
  final TipoEventoTelemetria tipo;
  final String? endpoint;
  final int? statusHttp;
  final int? latencyMs;
  final String? mensagem;
  final String? detalhe;
  final String? plataforma;

  Map<String, dynamic> toJson() => {
        'modulo': modulo,
        'tipo': tipo.valor,
        if (endpoint != null) 'endpoint': endpoint,
        if (statusHttp != null) 'statusHttp': statusHttp,
        if (latencyMs != null) 'latencyMs': latencyMs,
        if (mensagem != null) 'mensagem': mensagem,
        if (detalhe != null) 'detalhe': detalhe,
        if (plataforma != null) 'plataforma': plataforma,
      };
}

/// Fila em memória com envio em lote **best-effort** para o backend (R27).
///
/// Nenhum método lança exceção nem bloqueia a UI: falhas de transmissão apenas
/// re-enfileiram o lote (descartando excesso) para retomada no próximo flush.
/// Sem sessão autenticada o backend rejeitaria a ingestão (401), então os
/// eventos são descartados silenciosamente.
class TelemetryService {
  TelemetryService({
    required DioClient dioClient,
    this.maxBatchSize = 20,
    this.flushInterval = const Duration(seconds: 15),
  }) : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Quantidade máxima de eventos por lote enviado.
  final int maxBatchSize;

  /// Intervalo máximo em que eventos enfileirados aguardam antes do envio.
  final Duration flushInterval;

  final List<_EventoTelemetria> _fila = [];
  Timer? _timer;
  bool _enviando = false;
  bool _desabilitado = false;

  int get _limiteFila => maxBatchSize * 5;

  bool get isEmpty => _fila.isEmpty;

  /// Enfileira um evento de telemetria (sem dados pessoais).
  void registrar({
    required TipoEventoTelemetria tipo,
    required String modulo,
    String? endpoint,
    int? statusHttp,
    int? latencyMs,
    String? mensagem,
    String? detalhe,
  }) {
    if (_desabilitado) return;
    _fila.add(_EventoTelemetria(
      modulo: modulo,
      tipo: tipo,
      endpoint: endpoint,
      statusHttp: statusHttp,
      latencyMs: latencyMs,
      mensagem: mensagem,
      detalhe: detalhe,
      plataforma: _plataforma,
    ));
    if (_fila.length >= maxBatchSize) {
      unawaited(flush());
    } else {
      _agendarFlush();
    }
  }

  /// Registra exceções não tratadas da interface como eventos `UI_ERRO`.
  void registrarErroDeUi(Object erro, StackTrace? stack) {
    registrar(
      tipo: TipoEventoTelemetria.uiErro,
      modulo: 'APP',
      mensagem: _truncar(erro.toString(), 200),
      detalhe: _truncar(_resumirStack(stack), 2000),
    );
  }

  /// Registra um `LOGIN_SUCESSO` quando o usuário autentica pelo app.
  void registrarLoginSucesso() {
    registrar(
      tipo: TipoEventoTelemetria.loginSucesso,
      modulo: 'AUTH',
      endpoint: '/auth/login',
      statusHttp: 200,
      mensagem: 'Login realizado no aplicativo',
    );
  }

  /// Envia a fila em lote. Best-effort: nunca lança exceções.
  Future<void> flush() async {
    if (_desabilitado || _enviando) return;
    _timer?.cancel();
    _timer = null;
    if (_fila.isEmpty) return;

    final token = _dioClient.token;
    if (token == null || token.isEmpty) {
      _fila.clear();
      return;
    }

    _enviando = true;
    final lote = List<_EventoTelemetria>.of(_fila);
    _fila.clear();
    try {
      await _dioClient.dio.post(
        ApiConstants.telemetriaEventosEndpoint,
        data: {
          'eventos': lote.map((e) => e.toJson()).toList(),
        },
      );
    } catch (_) {
      // Best-effort: re-enfileira para retomada no próximo flush.
      _fila.insertAll(0, lote);
      while (_fila.length > _limiteFila) {
        _fila.removeLast();
      }
      _agendarFlush();
    } finally {
      _enviando = false;
    }
  }

  void dispose() {
    _desabilitado = true;
    _timer?.cancel();
    _timer = null;
  }

  void _agendarFlush() {
    if (_timer != null) return;
    _timer = Timer(flushInterval, () {
      _timer = null;
      unawaited(flush());
    });
  }

  String get _plataforma {
    try {
      if (kIsWeb) return 'WEB';
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isLinux) return 'Linux';
      if (Platform.isMacOS) return 'MacOS';
    } catch (_) {
      // Fallback para plataformas sem suporte (ex.: testes em navegador).
    }
    return 'DESCONHECIDA';
  }

  static String? _resumirStack(StackTrace? stack) {
    if (stack == null) return null;
    return stack.toString().split('\n').take(10).join('\n');
  }

  static String? _truncar(String? valor, int max) {
    if (valor == null) return null;
    return valor.length <= max ? valor : valor.substring(0, max);
  }
}