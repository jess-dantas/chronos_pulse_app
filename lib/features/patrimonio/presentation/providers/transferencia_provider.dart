import 'package:flutter/foundation.dart';
import '../../data/models/patrimonio_models.dart';
import '../../data/repositories/transferencia_repository.dart';

class TransferenciaProvider extends ChangeNotifier {
  final TransferenciaRepository _repository;

  List<TransferenciaModel> _transferencias = [];
  bool _isLoading = false;
  String? _errorMessage;

  TransferenciaProvider(this._repository);

  List<TransferenciaModel> get transferencias => _transferencias;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> carregarTransferencias() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transferencias = await _repository.listarTransferencias();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> solicitar({
    required String patrimonioId,
    required String localizacaoDestino,
    String? localizacaoOrigem,
    String? responsavelOrigem,
    String? responsavelDestino,
    String? dataPrevista,
    String? justificativa,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.solicitar(
        patrimonioId: patrimonioId,
        localizacaoDestino: localizacaoDestino,
        localizacaoOrigem: localizacaoOrigem,
        responsavelOrigem: responsavelOrigem,
        responsavelDestino: responsavelDestino,
        dataPrevista: dataPrevista,
        justificativa: justificativa,
      );
      await carregarTransferencias();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmar(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final atualizada = await _repository.confirmar(id);
      _substituir(atualizada);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelar(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.cancelar(id);
      _transferencias = _transferencias.where((t) => t.id != id).toList();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _substituir(TransferenciaModel atualizada) {
    final index = _transferencias.indexWhere((t) => t.id == atualizada.id);
    if (index >= 0) {
      _transferencias = List.of(_transferencias)..[index] = atualizada;
    }
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}