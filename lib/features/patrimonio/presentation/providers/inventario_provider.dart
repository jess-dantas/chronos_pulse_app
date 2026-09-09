import 'package:flutter/foundation.dart';
import '../../data/models/patrimonio_models.dart';
import '../../data/repositories/inventario_repository.dart';

class InventarioProvider extends ChangeNotifier {
  final InventarioRepository _repository;

  List<InventarioModel> _inventarios = [];
  bool _isLoading = false;
  String? _errorMessage;

  InventarioProvider(this._repository);

  List<InventarioModel> get inventarios => _inventarios;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<InventarioModel> get emAndamento =>
      _inventarios.where((i) => i.status == 'EM_ANDAMENTO').toList();

  Future<void> carregarInventarios() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _inventarios = await _repository.listarInventarios();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> criar({
    required String descricao,
    String? dataInicio,
    String? dataFim,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.criarInventario(
        descricao: descricao,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      await carregarInventarios();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<InventarioModel?> conferirItem(
    String inventarioId, {
    required String patrimonioId,
    required String resultado,
    String? observacao,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final atualizado = await _repository.conferirItem(
        inventarioId,
        patrimonioId: patrimonioId,
        resultado: resultado,
        observacao: observacao,
      );
      _substituir(atualizado);
      return atualizado;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> finalizar(String inventarioId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final atualizado = await _repository.finalizar(inventarioId);
      _substituir(atualizado);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelar(String inventarioId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.cancelar(inventarioId);
      _inventarios = _inventarios.where((i) => i.id != inventarioId).toList();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _substituir(InventarioModel atualizado) {
    final index = _inventarios.indexWhere((i) => i.id == atualizado.id);
    if (index >= 0) {
      _inventarios = List.of(_inventarios)..[index] = atualizado;
    }
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}