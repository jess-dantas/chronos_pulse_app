import 'package:chronos_pulse_app/core/constants/api_constants.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import '../models/patrimonio_models.dart';

class InventarioRemoteDataSource {
  final DioClient _dioClient;

  InventarioRemoteDataSource(this._dioClient);

  Future<List<InventarioModel>> listarInventarios() async {
    final response = await _dioClient.dio.get(
      ApiConstants.patrimonioInventariosEndpoint,
    );
    if (response.statusCode == 200) {
      final itens = (response.data as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InventarioModel.fromJson)
          .toList();
      return itens;
    }
    throw Exception('Falha ao carregar inventários');
  }

  Future<InventarioModel> buscarInventario(String id) async {
    final response = await _dioClient.dio.get(
      ApiConstants.patrimonioInventarioDetalheEndpoint(id),
    );
    if (response.statusCode == 200) {
      return InventarioModel.fromJson(response.data);
    }
    throw Exception('Falha ao carregar inventário');
  }

  Future<InventarioModel> criarInventario({
    required String descricao,
    String? dataInicio,
    String? dataFim,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.patrimonioInventariosEndpoint,
      data: {
        'descricao': descricao,
        if (dataInicio != null && dataInicio.isNotEmpty) 'dataInicio': dataInicio,
        if (dataFim != null && dataFim.isNotEmpty) 'dataFim': dataFim,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return InventarioModel.fromJson(response.data);
    }
    throw Exception('Falha ao abrir inventário');
  }

  Future<InventarioModel> conferirItem(
    String inventarioId, {
    required String patrimonioId,
    required String resultado,
    String? observacao,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.patrimonioInventarioConferirEndpoint(inventarioId),
      data: {
        'patrimonioId': patrimonioId,
        'resultado': resultado,
        if (observacao != null && observacao.isNotEmpty) 'observacao': observacao,
      },
    );
    if (response.statusCode == 200) {
      return InventarioModel.fromJson(response.data);
    }
    throw Exception('Falha ao conferir item');
  }

  Future<InventarioModel> finalizar(String inventarioId) async {
    final response = await _dioClient.dio.post(
      ApiConstants.patrimonioInventarioFinalizarEndpoint(inventarioId),
    );
    if (response.statusCode == 200) {
      return InventarioModel.fromJson(response.data);
    }
    throw Exception('Falha ao concluir inventário');
  }

  Future<void> cancelar(String inventarioId) async {
    final response = await _dioClient.dio.delete(
      ApiConstants.patrimonioInventarioCancelarEndpoint(inventarioId),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Falha ao cancelar inventário');
    }
  }
}