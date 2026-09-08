import 'package:chronos_pulse_app/core/constants/api_constants.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/network/paginated_response.dart';
import '../models/frota_models.dart';

class FrotaRemoteDataSource {
  final DioClient _dioClient;

  FrotaRemoteDataSource(this._dioClient);

  Future<PaginatedResponse<FrotaVeiculoModel>> getVeiculos({int page = 0, int size = 50}) async {
    final queryParams = <String, dynamic>{'page': page, 'size': size};
    final response = await _dioClient.dio.get(
      ApiConstants.frotaVeiculosEndpoint,
      queryParameters: queryParams,
    );
    if (response.statusCode == 200) {
      return PaginatedResponse.from(
        response.data,
        (itens) => itens.map(FrotaVeiculoModel.fromJson).toList(),
      );
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

  Future<PaginatedResponse<AbastecimentoModel>> getAbastecimentos({int page = 0, int size = 50}) async {
    final queryParams = <String, dynamic>{'page': page, 'size': size};
    final response = await _dioClient.dio.get(
      ApiConstants.frotaAbastecimentosEndpoint,
      queryParameters: queryParams,
    );
    if (response.statusCode == 200) {
      return PaginatedResponse.from(
        response.data,
        (itens) => itens.map(AbastecimentoModel.fromJson).toList(),
      );
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