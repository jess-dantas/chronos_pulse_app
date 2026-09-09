import '../datasources/transferencia_remote_datasource.dart';
import '../models/patrimonio_models.dart';

class TransferenciaRepository {
  final TransferenciaRemoteDataSource _remoteDataSource;

  TransferenciaRepository({required TransferenciaRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<TransferenciaModel>> listarTransferencias() =>
      _remoteDataSource.listarTransferencias();

  Future<TransferenciaModel> solicitar({
    required String patrimonioId,
    required String localizacaoDestino,
    String? localizacaoOrigem,
    String? responsavelOrigem,
    String? responsavelDestino,
    String? dataPrevista,
    String? justificativa,
  }) =>
      _remoteDataSource.solicitar(
        patrimonioId: patrimonioId,
        localizacaoDestino: localizacaoDestino,
        localizacaoOrigem: localizacaoOrigem,
        responsavelOrigem: responsavelOrigem,
        responsavelDestino: responsavelDestino,
        dataPrevista: dataPrevista,
        justificativa: justificativa,
      );

  Future<TransferenciaModel> confirmar(String id) =>
      _remoteDataSource.confirmar(id);

  Future<void> cancelar(String id) => _remoteDataSource.cancelar(id);
}