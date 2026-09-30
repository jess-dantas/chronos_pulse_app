import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/api_constants.dart';
import '../security/device_token_store.dart';

/// Resultado do diagnóstico de conexão feito na abertura do app (mobile).
enum DiagnosticoConexao {
  /// Backend respondendo — seguir o fluxo normal.
  online,

  /// Sem conexão (internet/backend/banco) e o aparelho NÃO tem contingência
  /// ativa — só dá para resolver logando (que também exige conexão).
  offlineSemVinculo,

  /// Sem conexão e o aparelho PODE bater ponto sem login (vínculo ativo) —
  /// levar direto para a tela de batida offline.
  offlineComVinculo,
}

/// Diagnóstico leve de conexão com o backend.
///
/// Usa `GET /auth/ping` (rota pública, barata) com timeout curto — em vez de
/// checar apenas a rede do dispositivo, valida o caminho que o app realmente
/// precisa: internet + backend + banco de dados.
class ConexaoService {
  final Future<bool> Function() ping;

  ConexaoService({Future<bool> Function()? ping}) : ping = ping ?? _pingPadrao;

  static Future<bool> _pingPadrao() async {
    // Ambiente de teste (`flutter test`): não faz rede real e não dispara o
    // toast "Sem conexão!" em testes de widget existentes — os testes do
    // diagnóstico injetam `ping` falso para exercitar o caminho offline.
    if (_emTeste) return true;

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      final response = await dio.get(ApiConstants.pingEndpoint);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// `true` quando rodando sob `flutter test` (web-safe: `dart:io` pode
  /// lançar em plataformas sem suporte).
  static bool get _emTeste {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Ping + checagem do vínculo de contingência (7 dias).
  Future<DiagnosticoConexao> diagnosticar({DeviceTokenStore? store}) async {
    final ok = await ping();
    if (ok) return DiagnosticoConexao.online;

    final temVinculo =
        await (store ?? DeviceTokenStore.instancia).vinculoAtivo();
    return temVinculo
        ? DiagnosticoConexao.offlineComVinculo
        : DiagnosticoConexao.offlineSemVinculo;
  }

  /// Toast padrão "Sem conexão!" (mesmo texto nas telas de home e login).
  static void avisarSemConexao(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sem conexão!'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
