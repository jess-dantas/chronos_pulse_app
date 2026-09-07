import 'package:chronos_pulse_app/core/constants/api_constants.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import '../models/frota_models.dart';

class FrotaRemoteDataSource {
  final DioClient _dioClient;

  FrotaRemoteDataSource(this._dioClient);

  Future<List<FrotaVeiculoModel>> getVeiculos() async {
    final queryParams = <String, dynamic>{'page': 0, 'size': 100};
    final response = await _dioClient.dio.get(
      ApiConstants.frotaVeiculosEndpoint,
      queryParameters: queryParams,
    );
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map((e) => FrotaVeiculoModel.fromJson(e)).toList();
      }
      if (data is Map) {
        final content = data['content'] as List? ?? [];
        return content.map((e) => FrotaVeiculoModel.fromJson(e)).toList();
      }
    }
    throw Exception('Falha ao carregar veículos');
  }

  Future<FrotaVeiculoModel> criarVeiculo(Map<String, dynamic> payload) async {
    final response = await _dioClient.dio.post(
      ApiConstants.frotaVeiculosEndpoint,
      data: payload,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return FrotaVeiculoModel.fromJson(response.data);
    }
    throw Exception('Falha ao cadastrar veículo');
  }

  Future<List<AbastecimentoModel>> getAbastecimentos() async {
    final queryParams = <String, dynamic>{'page': 0, 'size': 100};
    final response = await _dioClient.dio.get(
      ApiConstants.frotaAbastecimentosEndpoint,
      queryParameters: queryParams,
    );
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data.map((e) => AbastecimentoModel.fromJson(e)).toList();
      }
      if (data is Map) {
        final content = data['content'] as List? ?? [];
        return content.map((e) => AbastecimentoModel.fromJson(e)).toList();
      }
    }
    throw Exception('Falha ao carregar abastecimentos');
  }

  Future<AbastecimentoModel> registrarAbastecimento(Map<String, dynamic> payload) async {
    final response = await _dioClient.dio.post(
      ApiConstants.frotaAbastecimentosEndpoint,
      data: payload,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return AbastecimentoModel.fromJson(response.data);
    }
    throw Exception('Falha ao registrar abastecimento');
  }
}