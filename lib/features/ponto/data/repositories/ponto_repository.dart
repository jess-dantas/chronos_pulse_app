import '../datasources/ponto_local_datasource.dart';
import '../datasources/ponto_remote_datasource.dart';
import '../models/registro_ponto_model.dart';

class PontoRepository {
  final PontoLocalDataSource localDataSource;
  final PontoRemoteDataSource remoteDataSource;

  PontoRepository({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  Future<bool> registrarPonto({
    required RegistroPontoModel registro,
    required String cpfColaborador,
  }) async {
    // 1. Salva no banco SQLite local primeiro
    await localDataSource.salvarPontoLocal(registro);

    // 2. Tenta enviar para a API Spring Boot
    try {
      await remoteDataSource.registrarPonto(
        registro: registro,
        cpfColaborador: cpfColaborador,
      );

      // Se a API aceitou, marca como sincronizado localmente
      await localDataSource.marcarComoSincronizado(
          registro.dataHoraDispositivo.toIso8601String());
      return true; // Sincronizado online com sucesso
    } catch (e) {
      // Se falhar (offline ou erro no servidor), o registro permanece gravado localmente
      return false; // Salvo offline
    }
  }

  Future<void> sincronizarPendentes(String cpfColaborador) async {
    final pendentes = await localDataSource.obterPontosNaoSincronizados();

    for (var ponto in pendentes) {
      try {
        await remoteDataSource.registrarPonto(
          registro: ponto,
          cpfColaborador: cpfColaborador,
        );
        await localDataSource.marcarComoSincronizado(
            ponto.dataHoraDispositivo.toIso8601String());
      } catch (_) {
        // Permanece pendente para a próxima tentativa
      }
    }
  }

  Future<List<RegistroPontoModel>> obterHistorico() async {
    return await localDataSource.obterHistoricoHoje();
  }
}
