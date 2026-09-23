import 'package:flutter/material.dart';

import '../../data/models/titularidade_model.dart';
import '../../data/repositories/titularidade_repository.dart';

/// Estado do assistente de transferência de titularidade (3 etapas):
/// 1) iniciar + biometria; 2) OTP + confirmação do celular; 3) OTP do
/// e-mail corporativo do novo titular → concluir.
class TitularidadeProvider extends ChangeNotifier {
  final TitularidadeRepository _repository;

  TitularidadeIniciado? _iniciado;
  String? _destinoCelular;
  String? _destinoEmail;
  bool _biometriaConfirmada = false;
  bool _celularVerificado = false;
  bool _emailVerificado = false;
  bool _concluida = false;
  bool _isLoading = false;
  String? _errorMessage;

  TitularidadeProvider(this._repository);

  TitularidadeIniciado? get iniciado => _iniciado;
  String? get destinoCelular => _destinoCelular;
  String? get destinoEmail => _destinoEmail;
  bool get biometriaConfirmada => _biometriaConfirmada;
  bool get celularVerificado => _celularVerificado;
  bool get emailVerificado => _emailVerificado;
  bool get concluida => _concluida;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get podeConcluir =>
      _iniciado != null &&
      _biometriaConfirmada &&
      _celularVerificado &&
      _emailVerificado;

  /// Etapa atual do assistente (1..4; 4 = pronto para concluir).
  int get etapa {
    if (_iniciado == null || !_biometriaConfirmada) return 1;
    if (!_celularVerificado) return 2;
    if (!_emailVerificado) return 3;
    return 4;
  }

  String _tratarErro(Object e, String prefixo) {
    return '$prefixo: ${e.toString().replaceAll('Exception: ', '')}';
  }

  void limpar() {
    _iniciado = null;
    _destinoCelular = null;
    _destinoEmail = null;
    _biometriaConfirmada = false;
    _celularVerificado = false;
    _emailVerificado = false;
    _concluida = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<TitularidadeIniciado?> iniciar(String novoTitularId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Iniciar uma nova transferência cancela as anteriores em aberto.
      _iniciado = await _repository.iniciar(novoTitularId);
      _destinoCelular = null;
      _destinoEmail = null;
      _biometriaConfirmada = false;
      _celularVerificado = false;
      _emailVerificado = false;
      _concluida = false;
      return _iniciado;
    } catch (e) {
      _errorMessage = _tratarErro(e, 'Erro ao iniciar a transferência');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmarBiometria({bool confirmado = true}) async {
    final transferenciaId = _iniciado?.transferenciaId;
    if (transferenciaId == null) {
      _errorMessage = 'Transferência não iniciada.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.confirmarBiometria(transferenciaId, confirmado);
      _biometriaConfirmada = confirmado;
      return confirmado;
    } catch (e) {
      _errorMessage = _tratarErro(e, 'Erro ao confirmar a biometria');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> enviarCodigoCelular() async {
    final transferenciaId = _iniciado?.transferenciaId;
    if (transferenciaId == null) {
      _errorMessage = 'Transferência não iniciada.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final destino = await _repository.enviarCodigoCelular(transferenciaId);
      _destinoCelular = destino;
      return destino;
    } catch (e) {
      _errorMessage = _tratarErro(e, 'Erro ao enviar o código de celular');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verificarCelular({
    required String codigo,
    required bool celularConfirmado,
  }) async {
    final transferenciaId = _iniciado?.transferenciaId;
    if (transferenciaId == null) {
      _errorMessage = 'Transferência não iniciada.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.verificarCelular(
        transferenciaId,
        codigo: codigo,
        celularConfirmado: celularConfirmado,
      );
      _celularVerificado = true;
      return true;
    } catch (e) {
      _errorMessage = _tratarErro(e, 'Erro ao validar o código de celular');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> enviarCodigoEmail() async {
    final transferenciaId = _iniciado?.transferenciaId;
    if (transferenciaId == null) {
      _errorMessage = 'Transferência não iniciada.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final destino = await _repository.enviarCodigoEmail(transferenciaId);
      _destinoEmail = destino;
      return destino;
    } catch (e) {
      _errorMessage = _tratarErro(e, 'Erro ao enviar o código por e-mail');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verificarEmail({required String codigo}) async {
    final transferenciaId = _iniciado?.transferenciaId;
    if (transferenciaId == null) {
      _errorMessage = 'Transferência não iniciada.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.verificarEmail(transferenciaId, codigo: codigo);
      _emailVerificado = true;
      return true;
    } catch (e) {
      _errorMessage = _tratarErro(e, 'Erro ao validar o código de e-mail');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> concluir() async {
    final transferenciaId = _iniciado?.transferenciaId;
    if (transferenciaId == null) {
      _errorMessage = 'Transferência não iniciada.';
      notifyListeners();
      return false;
    }
    if (!podeConcluir) {
      _errorMessage = 'Conclua todas as etapas antes de finalizar.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.concluir(transferenciaId);
      _concluida = true;
      return true;
    } catch (e) {
      _errorMessage = _tratarErro(e, 'Erro ao concluir a transferência');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelar() async {
    final transferenciaId = _iniciado?.transferenciaId;
    if (transferenciaId == null) {
      // Nada aberto: apenas limpa o estado local.
      limpar();
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.cancelar(transferenciaId);
      limpar();
      return true;
    } catch (e) {
      _errorMessage = _tratarErro(e, 'Erro ao cancelar a transferência');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
