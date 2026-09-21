import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/espelho_relatorio_model.dart';
import '../../data/models/registro_ponto_model.dart';
import '../../data/repositories/ponto_repository.dart';

class PontoProvider extends ChangeNotifier {
  final PontoRepository _repository;

  String? _colaboradorId;
  bool _isOnline = false;
  bool _isVerificando = false;
  bool _isSincronizando = false;
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

  PontoProvider(this._repository) {
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

  Future<void> carregarDados() async {
    // 1) Leitura LOCAL primeiro (instantânea/limitada): o botão sequencial e a
    // lista de "Batidas de Hoje" reagem imediatamente — mesmo com o servidor
    // offline, a sequência NUNCA volta para a primeira batida.
    try {
      _historico =
          await _repository.obterHistoricoLocal(colaboradorId: _colaboradorId);
    } catch (_) {
      _historico = [];
    }
    try {
      _pendentesCount =
          await _repository.obterQuantidadePendentes(colaboradorId: _colaboradorId);
    } catch (_) {
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

    try {
      final online = await _repository.verificarConexao();
      final mudouStatus = (_isOnline != online);
      _isOnline = online;

      if ((mudouStatus || _isOnline) && !_isDisposed) {
        notifyListeners();
      }

      // Auto-sincronização quando o servidor fica online e há pendências
      if (_isOnline && _pendentesCount > 0 && autoSync && !_isSincronizando) {
        await sincronizar();
      }

      return _isOnline;
    } catch (_) {
      _isOnline = false;
      if (!_isDisposed) notifyListeners();
      return false;
    } finally {
      _isVerificando = false;
    }
  }

  Future<int> sincronizar() async {
    if (_isSincronizando || _isDisposed) return 0;

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
    } catch (_) {
      return 0;
    } finally {
      _isSincronizando = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<bool> registrarPonto(RegistroPontoModel registro) async {
    final sincronizadoOnline = await _repository.registrarPonto(registro: registro);
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
