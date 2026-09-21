import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/registro_ponto_model.dart';
import '../models/espelho_relatorio_model.dart';

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

  Future<EspelhoRelatorioModel> buscarRelatorioEspelho({
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
        ApiConstants.pontosEspelhoRelatorioEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return EspelhoRelatorioModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Falha ao consultar relatório do espelho: status ${response.statusCode}');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Erro ao consultar relatório do espelho de ponto na API');
    } catch (e) {
      throw Exception('Erro ao carregar relatório do espelho: ${e.toString()}');
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

  /// Colaborador solicita ajuste (vai para fila de aprovação)
  Future<RegistroPontoModel> solicitarAjuste({
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
        ApiConstants.pontosAjustarSolicitarEndpoint,
        data: payload,
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return RegistroPontoModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Falha ao solicitar ajuste: status ${response.statusCode}');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Erro ao solicitar ajuste na API');
    } catch (e) {
      throw Exception('Erro ao solicitar ajuste: ${e.toString()}');
    }
  }

  /// RH lista ajustes pendentes de aprovação
  Future<List<RegistroPontoModel>> listarAjustesPendentes() async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.pontosAjustesPendentesEndpoint,
      );

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> lista = response.data;
        return lista.map((item) => RegistroPontoModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Erro ao buscar ajustes pendentes na API');
    } catch (e) {
      throw Exception('Erro ao carregar ajustes pendentes: ${e.toString()}');
    }
  }

  /// RH aprova ajuste pendente
  Future<RegistroPontoModel> aprovarAjuste(String registroId) async {
    try {
      final response = await _dioClient.dio.put(
        ApiConstants.pontosAjustesAprovarEndpoint(registroId),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return RegistroPontoModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Falha ao aprovar ajuste: status ${response.statusCode}');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Erro ao aprovar ajuste na API');
    } catch (e) {
      throw Exception('Erro ao aprovar ajuste: ${e.toString()}');
    }
  }

  /// RH rejeita ajuste pendente
  Future<RegistroPontoModel> rejeitarAjuste(String registroId, String motivo) async {
    try {
      final response = await _dioClient.dio.put(
        ApiConstants.pontosAjustesRejeitarEndpoint(registroId),
        data: {'motivo': motivo},
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return RegistroPontoModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Falha ao rejeitar ajuste: status ${response.statusCode}');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw Exception(msg ?? 'Erro ao rejeitar ajuste na API');
    } catch (e) {
      throw Exception('Erro ao rejeitar ajuste: ${e.toString()}');
    }
  }
}
