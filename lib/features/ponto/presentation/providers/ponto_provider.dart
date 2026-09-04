import 'dart:async';
import 'package:flutter/foundation.dart';
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

  void iniciarMonitoramento({Duration interval = const Duration(seconds: 8)}) {
    _heartbeatTimer?.cancel();
    checarConexao(autoSync: true);
    _heartbeatTimer = Timer.periodic(interval, (_) => checarConexao(autoSync: true));
  }

  Future<void> carregarDados() async {
    _historico = await _repository.obterHistorico(colaboradorId: _colaboradorId);
    _pendentesCount = await _repository.obterQuantidadePendentes(colaboradorId: _colaboradorId);
    await carregarEspelho();
    if (!_isDisposed) notifyListeners();
  }

  Future<void> carregarEspelho({int? mes, int? ano}) async {
    if (_isDisposed) return;
    final m = mes ?? _mesSelecionado;
    final a = ano ?? _anoSelecionado;

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
      _carregandoEspelho = false;
      if (!_isDisposed) notifyListeners();
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
    await carregarDados();
    return sincronizadoOnline;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
