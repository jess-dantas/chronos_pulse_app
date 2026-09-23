import '../../../../core/network/dio_client.dart';

class TitularidadeRemoteDataSource {
  final DioClient _dioClient;

  TitularidadeRemoteDataSource(this._dioClient);

  Future<Map<String, dynamic>> iniciar(String novoTitularId) async {
    final response = await _dioClient.dio.post(
      '/titularidade/iniciar',
      data: {'novoTitularId': novoTitularId},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> confirmarBiometria(
      String transferenciaId, bool confirmado) async {
    await _dioClient.dio.post(
      '/titularidade/$transferenciaId/etapa/biometria',
      data: {'confirmado': confirmado},
    );
  }

  Future<Map<String, dynamic>> enviarCodigoCelular(
      String transferenciaId) async {
    final response = await _dioClient.dio
        .post('/titularidade/$transferenciaId/etapa/celular/enviar');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> verificarCelular(
    String transferenciaId, {
    required String codigo,
    required bool celularConfirmado,
  }) async {
    await _dioClient.dio.post(
      '/titularidade/$transferenciaId/etapa/celular/verificar',
      data: {
        'codigo': codigo,
        'celularConfirmado': celularConfirmado,
      },
    );
  }

  Future<Map<String, dynamic>> enviarCodigoEmail(
      String transferenciaId) async {
    final response = await _dioClient.dio
        .post('/titularidade/$transferenciaId/etapa/email/enviar');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> verificarEmail(
    String transferenciaId, {
    required String codigo,
  }) async {
    await _dioClient.dio.post(
      '/titularidade/$transferenciaId/etapa/email/verificar',
      data: {'codigo': codigo},
    );
  }

  Future<void> concluir(String transferenciaId) async {
    await _dioClient.dio.post('/titularidade/$transferenciaId/concluir');
  }

  Future<void> cancelar(String transferenciaId) async {
    await _dioClient.dio.post('/titularidade/$transferenciaId/cancelar');
  }
}
