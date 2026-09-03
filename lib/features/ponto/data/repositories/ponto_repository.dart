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

  /// Salva localmente primeiro (offline-first) e tenta sincronizar com o backend
  Future<bool> registrarPonto({
    required RegistroPontoModel registro,
  }) async {
    // 1. Salva no banco local primeiro
    await localDataSource.salvarPontoLocal(registro);

    // 2. Tenta sincronizar com a API REST
    try {
      final idsSucesso = await remoteDataSource.sincronizarPontos([registro]);

      if (idsSucesso.contains(registro.idLocal) || idsSucesso.isNotEmpty) {
        await localDataSource.marcarComoSincronizado(registro.idLocal);
        return true; // Sincronizado online com sucesso
      }
      return false; // Salvo offline
    } catch (_) {
      // Falha de rede ou servidor indisponível: ponto permanece salvo offline
      return false;
    }
  }

  /// Sincroniza em lote todos os registros pendentes acumulados offline
  Future<int> sincronizarPendentes({String? colaboradorId}) async {
    final pendentes = await localDataSource.obterPontosNaoSincronizados(
        colaboradorId: colaboradorId);
    if (pendentes.isEmpty) return 0;

    try {
      final idsSucesso = await remoteDataSource.sincronizarPontos(pendentes);
      for (var id in idsSucesso) {
        await localDataSource.marcarComoSincronizado(id);
      }
      return idsSucesso.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> obterQuantidadePendentes({String? colaboradorId}) async {
    final pendentes = await localDataSource.obterPontosNaoSincronizados(
        colaboradorId: colaboradorId);
    return pendentes.length;
  }

  Future<List<RegistroPontoModel>> obterHistorico({String? colaboradorId}) async {
    return await localDataSource.obterHistoricoHoje(colaboradorId: colaboradorId);
  }

  Future<bool> verificarConexao() async {
    return await remoteDataSource.verificarConexao();
  }
}
