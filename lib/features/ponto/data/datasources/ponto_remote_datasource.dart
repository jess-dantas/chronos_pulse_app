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

  Future<List<RegistroPontoModel>> buscarEspelho({
    String? colaboradorId,
    int? mes,
    int? ano,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (colaboradorId != null) queryParams['colaboradorId'] = colaboradorId;
      if (mes != null) queryParams['mes'] = mes;
      if (ano != null) queryParams['ano'] = ano;

      final response = await _dioClient.dio.get(
        ApiConstants.pontosEspelhoEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> lista = response.data;
        return lista.map((item) => RegistroPontoModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Erro ao buscar espelho de ponto na API');
    } catch (e) {
      throw Exception('Erro ao carregar espelho: ${e.toString()}');
    }
  }

  Future<RegistroPontoModel> solicitarAjusteManual({
    required DateTime dataHora,
    required String tipoRegistro,
    required String justificativa,
    String? observacao,
    String? colaboradorId,
  }) async {
    try {
      final payload = {
        'dataHora': dataHora.toUtc().toIso8601String(),
        'tipoRegistro': tipoRegistro,
        'justificativa': justificativa,
        'observacao': observacao,
        if (colaboradorId != null) 'colaboradorId': colaboradorId,
      };

      final response = await _dioClient.dio.post(
        ApiConstants.pontosAjustarEndpoint,
        data: payload,
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return RegistroPontoModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Falha ao registrar ajuste: status ${response.statusCode}');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Erro ao solicitar ajuste manual na API');
    } catch (e) {
      throw Exception('Erro ao ajustar ponto: ${e.toString()}');
    }
  }
}
