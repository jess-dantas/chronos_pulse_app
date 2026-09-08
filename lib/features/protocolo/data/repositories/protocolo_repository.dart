import '../../../../core/network/paginated_response.dart';
import '../datasources/protocolo_remote_datasource.dart';
import '../models/protocolo_models.dart';

class ProtocoloRepository {
  final ProtocoloRemoteDataSource _remoteDataSource;

  ProtocoloRepository({required ProtocoloRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<PaginatedResponse<ProtocoloModel>> getProtocolos({int page = 0, int size = 50}) =>
      _remoteDataSource.getProtocolos(page: page, size: size);
  Future<ProtocoloModel> criarProtocolo(Map<String, dynamic> payload) => _remoteDataSource.criarProtocolo(payload);
  Future<ProtocoloModel> atualizarStatus(String id, String status, {String? responsavel, String? observacoes}) =>
      _remoteDataSource.atualizarStatus(id, status, responsavel: responsavel, observacoes: observacoes);
}