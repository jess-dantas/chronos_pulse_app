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
  int _pendentesCount = 0;
  List<RegistroPontoModel> _historico = [];
  Timer? _heartbeatTimer;

  bool get isOnline => _isOnline;
  bool get isVerificando => _isVerificando;
  bool get isSincronizando => _isSincronizando;
  int get pendentesCount => _pendentesCount;
  List<RegistroPontoModel> get historico => _historico;
  String? get colaboradorId => _colaboradorId;

  PontoProvider(this._repository) {
    carregarDados();
    iniciarMonitoramento();
  }

  void definirColaborador(String? id) {
    if (_colaboradorId != id) {
      _colaboradorId = id;
      carregarDados();
    }
  }

  void iniciarMonitoramento({Duration interval = const Duration(seconds: 8)}) {
    _heartbeatTimer?.cancel();
    checarConexao(autoSync: true);
    _heartbeatTimer = Timer.periodic(interval, (_) => checarConexao(autoSync: true));
  }

  Future<void> carregarDados() async {
    _historico = await _repository.obterHistorico(colaboradorId: _colaboradorId);
    _pendentesCount = await _repository.obterQuantidadePendentes(colaboradorId: _colaboradorId);
    if (!_isDisposed) notifyListeners();
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
