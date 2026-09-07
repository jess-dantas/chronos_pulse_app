import '../datasources/protocolo_remote_datasource.dart';
import '../models/protocolo_models.dart';

class ProtocoloRepository {
  final ProtocoloRemoteDataSource _remoteDataSource;

  ProtocoloRepository({required ProtocoloRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<ProtocoloModel>> getProtocolos() => _remoteDataSource.getProtocolos();
  Future<ProtocoloModel> criarProtocolo(Map<String, dynamic> payload) => _remoteDataSource.criarProtocolo(payload);
  Future<ProtocoloModel> atualizarStatus(String id, String status, {String? responsavel, String? observacoes}) =>
      _remoteDataSource.atualizarStatus(id, status, responsavel: responsavel, observacoes: observacoes);
}