import 'package:dio/dio.dart';

/// Falha de rede/timeout: o servidor não chegou a responder. NÃO é rejeição
/// de credenciais — quem trata (refresh de sessão, sync offline) deve manter
/// a identidade local e tentar novamente quando a conexão voltar.
class FalhaDeRedeException implements Exception {
  final String mensagem;
  const FalhaDeRedeException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// `true` quando o erro do Dio é de transporte (sem resposta HTTP), ou seja,
/// conexão/recorte de rede — e não uma resposta do servidor.
bool ehFalhaDeRede(DioException e) =>
    e.response == null ||
    e.type == DioExceptionType.connectionError ||
    e.type == DioExceptionType.connectionTimeout ||
    e.type == DioExceptionType.sendTimeout ||
    e.type == DioExceptionType.receiveTimeout;


/// Mensagem de erro amigável (pt-BR), sem vazar detalhes técnicos ao usuário.
///
/// Prioriza a mensagem do servidor (`mensagem`/`message`) quando presente;
/// em seguida mapeia o status HTTP para um texto amigável; por fim usa uma
/// mensagem genérica.
String mensagemErroAmigavel(
  Object erro, {
  String fallback =
      'Não foi possível concluir a operação. Verifique sua conexão.',
}) {
  if (erro is DioException) {
    final serverMsg = _mensagemDoServidor(erro.response?.data);
    if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;
    final statusMsg = _mensagemPorStatus(erro.response?.statusCode);
    if (statusMsg != null) return statusMsg;
  } else if (erro is Exception) {
    final texto = erro.toString();
    if (texto.startsWith('Exception: ')) {
      final semPrefixo = texto.replaceFirst('Exception: ', '');
      if (!semPrefixo.contains('Exception')) return semPrefixo;
    }
  }
  return fallback;
}

String? _mensagemDoServidor(dynamic data) {
  if (data is Map) {
    final msg = data['mensagem'] ?? data['message'];
    if (msg is String && msg.trim().isNotEmpty) return msg;
  }
  return null;
}

String? _mensagemPorStatus(int? status) {
  if (status == null) return null;
  switch (status) {
    case 400:
      return 'Revise os dados informados.';
    case 401:
    case 403:
      return 'Acesso não autorizado. Verifique suas credenciais ou permissões.';
    case 404:
      return 'Recurso não encontrado.';
    case 429:
      return 'Muitas solicitações. Tente novamente em instantes.';
    case >= 500:
      return 'Erro interno no servidor. Tente novamente mais tarde.';
    default:
      return null;
  }
}
