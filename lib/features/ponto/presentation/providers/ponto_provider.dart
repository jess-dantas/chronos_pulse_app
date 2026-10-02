import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/telemetry/telemetry_service.dart';
import '../../data/models/espelho_relatorio_model.dart';
import '../../data/models/fila_ajuste_model.dart';
import '../../data/models/registro_ponto_model.dart';
import '../../data/repositories/ponto_repository.dart';
import '../../domain/services/sequencia_ponto.dart';

class PontoProvider extends ChangeNotifier {
  final PontoRepository _repository;
  final TelemetryService? _telemetria;

  String? _colaboradorId;
  bool _isOnline = false;
  bool _isVerificando = false;
  bool _isSincronizando = false;

  /// POST imediato da batida mais recente em voo: o lote do heartbeat espera
  /// ele terminar para nunca rodar junto (a batida em si NUNCA espera — ela
  /// não pode perder o ritmo por causa do sync em background).
  Future<bool>? _batidaEmVoo;
  bool _isDisposed = false;
  bool _carregandoEspelho = false;
  int _pendentesCount = 0;
  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;

  List<RegistroPontoModel> _historico = [];
  List<RegistroPontoModel> _espelho = [];
  EspelhoRelatorioModel? _relatorioEspelho;
  Timer? _heartbeatTimer;

  bool get isOnline => _isOnline;
  bool get isVerificando => _isVerificando;
  bool get isSincronizando => _isSincronizando;
  bool get carregandoEspelho => _carregandoEspelho;
  int get pendentesCount => _pendentesCount;
  int get mesSelecionado => _mesSelecionado;
  int get anoSelecionado => _anoSelecionado;
  List<RegistroPontoModel> get historico => _historico;
  List<RegistroPontoModel> get espelho => _espelho;
  EspelhoRelatorioModel? get relatorioEspelho => _relatorioEspelho;
  String? get colaboradorId => _colaboradorId;

  /// Motivo da última recusa explícita do servidor (null = sem rejeição).
  String? get ultimaFalhaServidor => _repository.ultimaFalhaServidor;

  /// Motivo da última falha de escrita no banco local (null = ok). Quando
  /// preenchido, a batida NÃO está na fila offline e a UI não pode dizer
  /// "salva localmente".
  String? get ultimaFalhaLocal => _repository.ultimaFalhaLocal;

  /// Próximo tipo da sequência pela regra do backend: último tipo do dia + 1,
  /// considerando também os ajustes manuais aprovados no dia. O histórico da
  /// home filtra ajustes (apresentação), então o dia é complementado com o
  /// espelho — única fonte que os traz. Sem espelho carregado (offline),
  /// cai no histórico local, o que equivale à regra antiga.
  String proximoTipoBatida() {
    final agora = DateTime.now();
    final porInstante = <String, RegistroPontoModel>{
      for (final r in _historico) r.dataHoraDispositivo.toIso8601String(): r,
    };

    final espelhoDoMesAtual = _mesSelecionado == agora.month &&
        _anoSelecionado == agora.year;
    if (espelhoDoMesAtual) {
      for (final r in _espelho) {
        final d = r.dataHoraDispositivo.toLocal();
        final mesmoDia = d.year == agora.year &&
            d.month == agora.month &&
            d.day == agora.day;
        if (mesmoDia) {
          porInstante.putIfAbsent(
              r.dataHoraDispositivo.toIso8601String(), () => r);
        }
      }
    }

    return SequenciaPonto.proximo(porInstante.values.toList());
  }

  PontoProvider(this._repository, {TelemetryService? telemetria})
      : _telemetria = telemetria {
    carregarDados();
    iniciarMonitoramento();
  }

  void definirColaborador(String? id) {
    if (_colaboradorId != id) {
      _colaboradorId = id;
      carregarDados();
      carregarEspelho();
    }
  }

  void alterarPeriodoEspelho(int mes, int ano) {
    _mesSelecionado = mes;
    _anoSelecionado = ano;
    carregarEspelho();
  }

  void iniciarMonitoramento({Duration interval = const Duration(seconds: 30)}) {
    _heartbeatTimer?.cancel();
    checarConexao(autoSync: true);
    _heartbeatTimer = Timer.periodic(interval, (_) => checarConexao(autoSync: true));
  }

  /// Evita leituras concorrentes do construtor×initState×definirColaborador:
  /// chamadas durante uma execução ficam na fila (coalescidas) e o futuro
  /// retornado só completa quando a fila drena — quem espera `await` sempre
  /// recebe o estado final com o colaborador mais recente, nunca o de um
  /// carregamento antigo (ex.: id nulo) sobrepondo o correto.
  bool _carregando = false;
  bool _recarregarAguardando = false;
  Future<void>? _filaAtual;

  Future<void> carregarDados() {
    if (_carregando) {
      _recarregarAguardando = true;
      return _filaAtual!;
    }
    _carregando = true;
    final fila = _drenarFila();
    _filaAtual = fila;
    return fila;
  }

  Future<void> _drenarFila() async {
    try {
      do {
        _recarregarAguardando = false;
        await _carregarDadosInterna();
      } while (_recarregarAguardando && !_isDisposed);
    } finally {
      _carregando = false;
      _filaAtual = null;
    }
  }

  Future<void> _carregarDadosInterna() async {
    // 1) Leitura LOCAL primeiro (instantânea/limitada): o botão sequencial e a
    // lista de "Batidas de Hoje" reagem imediatamente — mesmo com o servidor
    // offline, a sequência NUNCA volta para a primeira batida.
    try {
      _historico =
          await _repository.obterHistoricoLocal(colaboradorId: _colaboradorId);
    } catch (e) {
      debugPrint('[PontoProvider] histórico local falhou (colab=$_colaboradorId): $e');
      _historico = [];
    }
    try {
      _pendentesCount =
          await _repository.obterQuantidadePendentes(colaboradorId: _colaboradorId);
    } catch (e) {
      debugPrint('[PontoProvider] pendentes locais falharam (colab=$_colaboradorId): $e');
      _pendentesCount = 0;
    }
    if (!_isDisposed) notifyListeners();

    // 2) Enriquecimento remoto (limitado): só vale a pena quando o servidor
    // responde. Em modo offline a UI já está consistente com o passo 1.
    if (_isOnline) {
      try {
        _historico = await _repository.obterHistorico(colaboradorId: _colaboradorId);
      } catch (_) {
        // mantém o histórico local, que já foi notificado
      }
      await carregarEspelho();
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> carregarEspelho({int? mes, int? ano}) async {
    if (_isDisposed) return;
    final m = mes ?? _mesSelecionado;
    final a = ano ?? _anoSelecionado;

    // Offline: mantém o último espelho carregado em vez de apagar a tela.
    if (!_isOnline) {
      if (!_isDisposed) notifyListeners();
      return;
    }

    _carregandoEspelho = true;
    if (!_isDisposed) notifyListeners();

    try {
      _espelho = await _repository.obterEspelhoPonto(
        colaboradorId: _colaboradorId,
        mes: m,
        ano: a,
      );
    } catch (_) {
      _espelho = [];
    } finally {
      await carregarRelatorioEspelho(mes: m, ano: a);
      _carregandoEspelho = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Relatório do espelho (art. 84): enriquece o PDF com empregador,
  /// trabalhador, jornada contratual e código de verificação. Falhas de rede
  /// mantêm a exportação de PDF funcional apenas com as marcações.
  Future<void> carregarRelatorioEspelho({int? mes, int? ano}) async {
    if (_isDisposed || !_isOnline) return;
    final m = mes ?? _mesSelecionado;
    final a = ano ?? _anoSelecionado;
    try {
      _relatorioEspelho = await _repository.obterRelatorioEspelhoPonto(
        colaboradorId: _colaboradorId,
        mes: m,
        ano: a,
      );
    } catch (_) {
      _relatorioEspelho = null;
    }
  }

  Future<bool> ajustarPontoManual({
    required DateTime dataHora,
    required String tipoRegistro,
    required String justificativa,
    String? observacao,
  }) async {
    final sucesso = await _repository.ajustarPontoManual(
      dataHora: dataHora,
      tipoRegistro: tipoRegistro,
      justificativa: justificativa,
      observacao: observacao,
      colaboradorId: _colaboradorId,
    );

    await carregarDados();
    return sucesso;
  }

  /// Colaborador solicita ajuste (nova API com aprovação)
  Future<bool> solicitarAjuste({
    required DateTime dataHora,
    required String tipoRegistro,
    required String justificativa,
    String? observacao,
  }) async {
    final sucesso = await _repository.solicitarAjuste(
      dataHora: dataHora,
      tipoRegistro: tipoRegistro,
      justificativa: justificativa,
      observacao: observacao,
      colaboradorId: _colaboradorId,
    );

    await carregarDados();
    return sucesso;
  }

  /// RH lista ajustes pendentes
  Future<List<RegistroPontoModel>> listarAjustesPendentes() async {
    return await _repository.listarAjustesPendentes();
  }

  /// RH fila consolidada de ajustes pendentes (nome + marcações do dia)
  Future<List<FilaAjusteModel>> listarFilaAjustes() async {
    return await _repository.listarFilaAjustes();
  }

  /// RH aprova ajuste
  Future<RegistroPontoModel?> aprovarAjuste(String registroId) async {
    final resultado = await _repository.aprovarAjuste(registroId);
    if (resultado != null) {
      await carregarDados();
    }
    return resultado;
  }

  /// RH rejeita ajuste
  Future<RegistroPontoModel?> rejeitarAjuste(String registroId, String motivo) async {
    final resultado = await _repository.rejeitarAjuste(registroId, motivo);
    if (resultado != null) {
      await carregarDados();
    }
    return resultado;
  }

  Future<bool> checarConexao({bool autoSync = false}) async {
    if (_isVerificando || _isDisposed) return _isOnline;
    _isVerificando = true;

    var mudouStatus = false;
    try {
      final online = await _repository.verificarConexao();
      mudouStatus = (_isOnline != online);
      _isOnline = online;

      if ((mudouStatus || _isOnline) && !_isDisposed) {
        notifyListeners();
      }
    } catch (_) {
      _isOnline = false;
      mudouStatus = false;
      if (!_isDisposed) notifyListeners();
    } finally {
      // Libera o guard antes das ações pesadas: quem chamar checarConexao
      // durante um recarregamento não pode receber um estado defasado.
      _isVerificando = false;
    }

    // Auto-sincronização quando o servidor fica online e há pendências
    if (_isOnline && _pendentesCount > 0 && autoSync && !_isSincronizando) {
      await sincronizar();
    } else if (mudouStatus && _isOnline && !_isDisposed) {
      // Transição offline → online sem pendências locais: recarrega o
      // histórico/espelho do servidor. Sem isso a tela fica com a leitura
      // local feita antes do ping responder (o chamador costuma definir o
      // colaborador logo após o construtor, ainda com _isOnline = false).
      await carregarDados();
    }

    return _isOnline;
  }

  Future<int> sincronizar() async {
    if (_isSincronizando || _isDisposed) return 0;

    // Espera o POST de uma batida em voo (a batida nunca espera o inverso):
    // dois lotes em paralelo faziam o backend derivar tipos concorrentemente.
    final batida = _batidaEmVoo;
    if (batida != null) {
      try {
        await batida;
      } catch (_) {
        // falha da batida já tratada no caminho dela
      }
      if (_isDisposed || _isSincronizando) return 0;
    }

    _isSincronizando = true;
    if (!_isDisposed) notifyListeners();

    try {
      final qtdSincronizada =
          await _repository.sincronizarPendentes(colaboradorId: _colaboradorId);
      await carregarDados();
      // Atualiza o status de conexão baseado no resultado
      if (qtdSincronizada > 0) {
        _isOnline = true;
      }
      return qtdSincronizada;
    } catch (e) {
      debugPrint('[PontoProvider] sincronizar() falhou (colab=$_colaboradorId): $e');
      return 0;
    } finally {
      _isSincronizando = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<bool> registrarPonto(RegistroPontoModel registro) async {
    final envio = _repository.registrarPonto(registro: registro);
    _batidaEmVoo = envio;
    bool sincronizadoOnline;
    try {
      sincronizadoOnline = await envio;
    } finally {
      if (identical(_batidaEmVoo, envio)) _batidaEmVoo = null;
    }
    if (!sincronizadoOnline && _repository.ultimaFalhaServidor == null) {
      // Ficou na fila local (offline): registra para observar contingência.
      _telemetria?.registrar(
        tipo: TipoEventoTelemetria.conexaoOffline,
        modulo: 'PONTO',
        mensagem: 'Batida enfileirada offline',
        detalhe: registro.tipoRegistro,
      );
    }
    _isOnline = sincronizadoOnline || _isOnline;
    // Atualiza histórico/espelho com os registros do servidor, sem nunca
    // prender a batida: tudo que toca no banco local já é limitado.
    try {
      await carregarDados().timeout(const Duration(seconds: 12));
    } catch (_) {
      if (!_isDisposed) notifyListeners();
    }
    return sincronizadoOnline;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
