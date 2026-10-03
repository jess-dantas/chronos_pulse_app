import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../datasources/ponto_local_datasource.dart';
import '../datasources/ponto_remote_datasource.dart';
import '../models/espelho_relatorio_model.dart';
import '../models/fila_ajuste_model.dart';
import '../models/registro_ponto_model.dart';

class PontoRepository {
  final PontoLocalDataSource localDataSource;
  final PontoRemoteDataSource remoteDataSource;

  String? _ultimaFalhaServidor;

  /// Motivo da última recusa explícita do servidor (null = sem rejeição;
  /// falha de rede NÃO preenche este campo — ela é "offline", não rejeição).
  String? get ultimaFalhaServidor => _ultimaFalhaServidor;

  String? _ultimaFalhaLocal;

  /// Motivo da última falha de ESCRITA/LEITURA no banco local (null = ok).
  /// A UI precisa distinguir "salvo no dispositivo" de "não foi possível
  /// salvar no dispositivo" — sem isso o snackbar mente sobre a fila offline.
  String? get ultimaFalhaLocal => _ultimaFalhaLocal;

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
    _ultimaFalhaServidor = null;
    _ultimaFalhaLocal = null;

    // 1. Salva no banco local primeiro (com limite de tempo: nunca bloqueia a UI)
    final localOk = await _salvarLocalComTimeout(registro);

    // 2. Tenta sincronizar com a API REST (com limite: nunca trava a batida)
    try {
      final idsSucesso = await remoteDataSource
          .sincronizarPontos([registro]).timeout(const Duration(seconds: 8));

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
    } on RejeicaoServidorException catch (e) {
      // Servidor online mas recusou gravar: registra o motivo para a UI
      // mostrar snackbar vermelho em vez de "offline" enganoso.
      _ultimaFalhaServidor = e.mensagem;
      return false;
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
    } on TimeoutException {
      _ultimaFalhaLocal = 'Banco local não respondeu em 3s ao salvar a batida.';
      debugPrint('[PontoRepository] $_ultimaFalhaLocal '
          '(idLocal=${registro.idLocal}, colab=${registro.colaboradorId})');
      return false;
    } catch (e) {
      _ultimaFalhaLocal = 'Falha ao gravar a batida no dispositivo: $e';
      debugPrint('[PontoRepository] $_ultimaFalhaLocal '
          '(idLocal=${registro.idLocal}, colab=${registro.colaboradorId})');
      return false;
    }
  }

  /// Sincroniza em lote todos os registros pendentes acumulados offline
  Future<int> sincronizarPendentes({String? colaboradorId}) async {
    _ultimaFalhaServidor = null;

    final pendentes = await localDataSource.obterPontosNaoSincronizados(
        colaboradorId: colaboradorId);
    if (pendentes.isEmpty) return 0;

    // Envio sempre em ordem cronológica: o backend deriva o tipo de cada
    // batida na ordem em que recebe o lote — lote embaralhado gravava tipo
    // fora de sequência.
    pendentes
        .sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));

    try {
      final idsSucesso = await remoteDataSource
          .sincronizarPontos(pendentes)
          .timeout(const Duration(seconds: 8));
      for (var id in idsSucesso) {
        await localDataSource.marcarComoSincronizado(id);
      }
      return idsSucesso.length;
    } on RejeicaoServidorException catch (e) {
      _ultimaFalhaServidor = e.mensagem;
      debugPrint('[PontoRepository] servidor recusou o lote: ${e.mensagem} '
          '(${pendentes.length} pendente(s))');
      return 0;
    } catch (e) {
      debugPrint('[PontoRepository] sincronização de ${pendentes.length} '
          'pendente(s) falhou: $e');
      return 0;
    }
  }

  Future<int> obterQuantidadePendentes({String? colaboradorId}) async {
    try {
      final pendentes = await localDataSource
          .obterPontosNaoSincronizados(colaboradorId: colaboradorId)
          .timeout(const Duration(seconds: 3));
      return pendentes.length;
    } catch (e) {
      debugPrint('[PontoRepository] falha ao contar pendentes locais: $e');
      return 0;
    }
  }

  /// Histórico do dia SOMENTE do banco local (limitado).
  ///
  /// Fonte de verdade instantânea para o botão sequencial e para a lista,
  /// independente do estado do servidor. Ajustes manuais não entram aqui:
  /// a home reflete apenas as batidas feitas pelo botão.
  Future<List<RegistroPontoModel>> obterHistoricoLocal({
    String? colaboradorId,
  }) async {
    try {
      final lista = await localDataSource
          .obterHistoricoHoje(colaboradorId: colaboradorId)
          .timeout(const Duration(seconds: 3));
      return lista.where((r) => !r.ajusteManual).toList();
    } catch (e) {
      // banco local indisponível: segue sem registros locais (usará o servidor)
      debugPrint('[PontoRepository] falha ao ler histórico local '
          '(colab=$colaboradorId): $e');
      return [];
    }
  }

  /// Batidas locais (inclusive ajustes) das últimas 72h, em ordem cronológica.
  ///
  /// Alimenta a prévia da sequência quando o aparelho está offline: o
  /// histórico de "hoje" ainda está vazio logo depois da meia-noite, mas a
  /// jornada anterior (turno noturno) continua valendo para a próxima
  /// batida. Cobre o mês atual e o anterior (a janela pode cruzar a virada
  /// do mês). Falha de leitura vira lista vazia — a sequência decai para o
  /// histórico de hoje sem derrubar a tela.
  Future<List<RegistroPontoModel>> obterBatidasRecentes({
    String? colaboradorId,
  }) async {
    final agora = DateTime.now();
    final inicio = agora.subtract(const Duration(hours: 72));
    final meses = <(int, int)>{
      (agora.month, agora.year),
      (inicio.month, inicio.year)
    };

    final resultado = <RegistroPontoModel>[];
    for (final (mes, ano) in meses) {
      try {
        final lista = await localDataSource
            .obterPorMesAno(colaboradorId: colaboradorId, mes: mes, ano: ano)
            .timeout(const Duration(seconds: 3));
        resultado.addAll(
            lista.where((r) => !r.dataHoraDispositivo.isBefore(inicio)));
      } catch (e) {
        debugPrint('[PontoRepository] falha ao ler batidas recentes '
            '(mês=$mes/$ano, colab=$colaboradorId): $e');
      }
    }
    resultado
        .sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));
    return resultado;
  }

  /// Histórico do dia: mescla os registros locais com o espelho do servidor.
  ///
  /// Quando o banco local está indisponível (ex.: SQLite Web), o histórico
  /// segue refletindo as batidas já registradas no servidor — o botão avança
  /// para a próxima batida sequencial e a lista de "Batidas de Hoje" aparece.
  ///
  /// Com o servidor respondendo, o dia local é RECONCILIADO com o espelho
  /// (servidor vence): a sequência local passa a igual a do servidor e linhas
  /// removidas no servidor (limpeza de teste) somem também do aparelho.
  Future<List<RegistroPontoModel>> obterHistorico(
      {String? colaboradorId}) async {
    final agora = DateTime.now();
    final inicioDia = DateTime(agora.year, agora.month, agora.day);
    final fimDia =
        DateTime(agora.year, agora.month, agora.day, 23, 59, 59, 999);

    var locais = await obterHistoricoLocal(colaboradorId: colaboradorId);

    List<RegistroPontoModel> remotos = [];
    try {
      // Limitado: servidor inacessível não "prende" o histórico da home.
      final espelho = await remoteDataSource
          .buscarEspelho(
            colaboradorId: colaboradorId,
            mes: agora.month,
            ano: agora.year,
          )
          .timeout(const Duration(seconds: 4));
      remotos = espelho
          .where((r) {
            if (r.ajusteManual) return false;
            final d = r.dataHoraDispositivo.toLocal();
            return !d.isBefore(inicioDia) && !d.isAfter(fimDia);
          })
          .map((r) => r.copyWith(sincronizadoOffline: true))
          .toList();

      try {
        await localDataSource.reconciliarDia(
          colaboradorId: colaboradorId,
          inicioDia: inicioDia,
          fimDia: fimDia,
          remotos: remotos,
        );
        // Relê o dia já reconciliado para a mesclagem refletir o estado real.
        locais = await obterHistoricoLocal(colaboradorId: colaboradorId);
      } catch (e) {
        debugPrint('[PontoRepository] reconciliação do dia falhou: $e');
      }
    } catch (e) {
      // offline: segue somente com o histórico local
      debugPrint('[PontoRepository] falha ao buscar histórico remoto: $e');
    }

    if (remotos.isEmpty) return locais;

    final chaves = remotos.map(_chaveRegistro).toSet();
    final extras =
        locais.where((l) => !chaves.contains(_chaveRegistro(l))).toList();
    return [...remotos, ...extras]
      ..sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));
  }

  Future<List<RegistroPontoModel>> obterEspelhoPonto({
    String? colaboradorId,
    int? mes,
    int? ano,
  }) async {
    List<RegistroPontoModel> remotos = [];
    try {
      // Limitado: espelho nunca depende de servidor demorado para responder.
      remotos = await remoteDataSource
          .buscarEspelho(
            colaboradorId: colaboradorId,
            mes: mes,
            ano: ano,
          )
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      // Se a API estiver offline, usa somente o histórico local
      debugPrint('[PontoRepository] falha ao buscar espelho remoto: $e');
    }

    final locais = await _obterExtrasLocais(
      colaboradorId: colaboradorId,
      mes: mes,
      ano: ano,
    );

    if (remotos.isEmpty) return locais;

    // Mescla registros locais ainda não presentes no servidor (ex.: ajustes offline)
    final chaves = remotos.map(_chaveRegistro).toSet();
    final extras =
        locais.where((l) => !chaves.contains(_chaveRegistro(l))).toList();
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

  /// Chave de identidade da batida para a mesclagem local×servidor.
  ///
  /// Por instante exato (millisecondsSinceEpoch, independente de fuso): a
  /// MESMA batida tem o mesmo dataHoraDispositivo dos dois lados (o servidor
  /// devolve o valor recebido), enquanto o tipo e o colaboradorId podem
  /// divergir — o servidor re-deriva a sequência, e o registro local nasce
  /// com colaboradorId nulo (preenchido só após a sincronização), o que
  /// fazia a mesma batida sobreviver DUAS vezes na lista. Chavar por
  /// colaboradorId|null quebrava justamente esse par. As listas já vêm
  /// escopadas por colaborador, então o instant sozinho é suficiente.
  /// Batidas distintas no mesmo minuto têm instantes diferentes, então não
  /// colapsam.
  String _chaveRegistro(RegistroPontoModel r) {
    return '${r.dataHoraDispositivo.millisecondsSinceEpoch}';
  }

  /// Consulta o relatório do espelho de ponto (art. 84 da Portaria MTP 671/2021)
  /// com empregador, trabalhador, jornada contratual e código de verificação.
  /// Retorna null quando o servidor está indisponível — o PDF segue sendo
  /// exportável somente com as marcações locais/do espelho.
  Future<EspelhoRelatorioModel?> obterRelatorioEspelhoPonto({
    String? colaboradorId,
    int? mes,
    int? ano,
  }) async {
    try {
      return await remoteDataSource
          .buscarRelatorioEspelho(
            colaboradorId: colaboradorId,
            mes: mes,
            ano: ano,
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[PontoRepository] falha ao buscar relatório do espelho: $e');
      return null;
    }
  }

  Future<bool> ajustarPontoManual({
    required DateTime dataHora,
    required String tipoRegistro,
    required String justificativa,
    String? observacao,
    String? colaboradorId,
  }) async {
    final registroLocal = RegistroPontoModel(
      idLocal: const Uuid().v4(),
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
      await remoteDataSource.solicitarAjuste(
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

  /// Colaborador solicita ajuste (nova API com aprovação)
  Future<bool> solicitarAjuste({
    required DateTime dataHora,
    required String tipoRegistro,
    required String justificativa,
    String? observacao,
    String? colaboradorId,
  }) async {
    final registroLocal = RegistroPontoModel(
      idLocal: const Uuid().v4(),
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
      ajusteStatus: 'PENDENTE',
    );

    // Salva localmente primeiro
    await localDataSource.salvarPontoLocal(registroLocal);

    try {
      await remoteDataSource.solicitarAjuste(
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

  /// RH lista ajustes pendentes
  Future<List<RegistroPontoModel>> listarAjustesPendentes() async {
    try {
      return await remoteDataSource.listarAjustesPendentes();
    } catch (_) {
      return [];
    }
  }

  /// RH lista a fila consolidada de ajustes pendentes (nome + marcações do dia).
  /// Propaga erro para a tela mostrar o estado de falha.
  Future<List<FilaAjusteModel>> listarFilaAjustes() {
    return remoteDataSource.listarFilaAjustes();
  }

  /// RH aprova ajuste — propaga o erro real para a tela exibir a causa
  /// (antes `catch (_) => null` escondia 400/403/500 atrás de "Erro ao aprovar").
  Future<RegistroPontoModel?> aprovarAjuste(String registroId) {
    return remoteDataSource.aprovarAjuste(registroId);
  }

  /// RH rejeita ajuste — propaga o erro real (mesmo motivo do aprovar).
  Future<RegistroPontoModel?> rejeitarAjuste(String registroId, String motivo) {
    return remoteDataSource.rejeitarAjuste(registroId, motivo);
  }

  Future<bool> verificarConexao() async {
    return await remoteDataSource.verificarConexao();
  }
}
