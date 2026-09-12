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

  /// Salva localmente primeiro (offline-first) e tenta sincronizar com o backend.
  ///
  /// O banco local é limitado por timeout: se a escrita local não completar
  /// (ex.: SQLite Web com WASM/IndexedDB lento), a batida SEGUE apenas online
  /// em vez de travar o "Processando Registro..." por tempo indeterminado.
  Future<bool> registrarPonto({
    required RegistroPontoModel registro,
  }) async {
    // 1. Salva no banco local primeiro (com limite de tempo: nunca bloqueia a UI)
    final localOk = await _salvarLocalComTimeout(registro);

    // 2. Tenta sincronizar com a API REST
    try {
      final idsSucesso = await remoteDataSource.sincronizarPontos([registro]);

      if (idsSucesso.contains(registro.idLocal) || idsSucesso.isNotEmpty) {
        if (localOk) {
          try {
            await localDataSource
                .marcarComoSincronizado(registro.idLocal)
                .timeout(const Duration(seconds: 3));
          } catch (_) {
            // marcação local falhou: irrelevante para o resultado online
          }
        }
        return true; // Sincronizado online com sucesso
      }
      return false; // Salvo offline
    } catch (_) {
      // Falha de rede ou servidor indisponível: ponto permanece salvo offline
      return false;
    }
  }

  Future<bool> _salvarLocalComTimeout(RegistroPontoModel registro) async {
    try {
      await localDataSource
          .salvarPontoLocal(registro)
          .timeout(const Duration(seconds: 3));
      return true;
    } catch (_) {
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

  Future<List<RegistroPontoModel>> obterEspelhoPonto({
    String? colaboradorId,
    int? mes,
    int? ano,
  }) async {
    List<RegistroPontoModel> remotos = [];
    try {
      remotos = await remoteDataSource.buscarEspelho(
        colaboradorId: colaboradorId,
        mes: mes,
        ano: ano,
      );
    } catch (_) {
      // Se a API estiver offline, usa somente o histórico local
    }

    final locais = await _obterExtrasLocais(
      colaboradorId: colaboradorId,
      mes: mes,
      ano: ano,
    );

    if (remotos.isEmpty) return locais;

    // Mescla registros locais ainda não presentes no servidor (ex.: ajustes offline)
    final chaves = remotos.map(_chaveRegistro).toSet();
    final extras = locais.where((l) => !chaves.contains(_chaveRegistro(l))).toList();
    return [...remotos, ...extras];
  }

  /// Leitura local limitada: se o banco local estiver lento, o espelho segue
  /// apenas com os registros do servidor em vez de pendurar a tela.
  Future<List<RegistroPontoModel>> _obterExtrasLocais({
    String? colaboradorId,
    int? mes,
    int? ano,
  }) async {
    try {
      return await localDataSource
          .obterPorMesAno(
            colaboradorId: colaboradorId,
            mes: mes,
            ano: ano,
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      return [];
    }
  }

  String _chaveRegistro(RegistroPontoModel r) {
    final local = r.dataHoraDispositivo.toLocal();
    final minuto = DateTime(local.year, local.month, local.day, local.hour, local.minute);
    return '${r.tipoRegistro}|${minuto.toIso8601String()}';
  }

  Future<bool> ajustarPontoManual({
    required DateTime dataHora,
    required String tipoRegistro,
    required String justificativa,
    String? observacao,
    String? colaboradorId,
  }) async {
    final registroLocal = RegistroPontoModel(
      idLocal: DateTime.now().millisecondsSinceEpoch.toString(),
      colaboradorId: colaboradorId,
      dataHoraDispositivo: dataHora,
      tipoRegistro: tipoRegistro,
      latitude: 0,
      longitude: 0,
      precisaoGps: 0,
      sincronizadoOffline: false,
      ajusteManual: true,
      justificativa: justificativa,
      observacao: observacao,
    );

    // Salva localmente primeiro
    await localDataSource.salvarPontoLocal(registroLocal);

    try {
      await remoteDataSource.solicitarAjusteManual(
        dataHora: dataHora,
        tipoRegistro: tipoRegistro,
        justificativa: justificativa,
        observacao: observacao,
        colaboradorId: colaboradorId,
      );
      await localDataSource.marcarComoSincronizado(registroLocal.idLocal);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verificarConexao() async {
    return await remoteDataSource.verificarConexao();
  }
}
