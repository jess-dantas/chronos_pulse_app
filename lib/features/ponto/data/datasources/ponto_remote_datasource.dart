import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/registro_ponto_model.dart';

class PontoRemoteDataSource {
  final DioClient _dioClient;

  PontoRemoteDataSource(this._dioClient);

  /// Verifica se o backend está respondendo (Heartbeat / Ping)
  Future<bool> verificarConexao() async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.pingEndpoint,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> sincronizarPontos(List<RegistroPontoModel> registros) async {
    if (registros.isEmpty) return [];

    try {
      final payload = {
        'registros': registros.map((r) => r.toApiJson()).toList(),
      };

      final response = await _dioClient.dio.post(
        ApiConstants.pontosEndpoint,
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['idsSucesso'] != null) {
          final List<dynamic> sucessos = data['idsSucesso'];
          return sucessos.map((id) => id.toString()).toList();
        }
        return registros.map((r) => r.idLocal).toList();
      } else {
        throw Exception('Falha ao registrar ponto: status ${response.statusCode}');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Erro de rede ao conectar com a API');
    } catch (e) {
      throw Exception('Erro ao sincronizar ponto: ${e.toString()}');
    }
  }
}
