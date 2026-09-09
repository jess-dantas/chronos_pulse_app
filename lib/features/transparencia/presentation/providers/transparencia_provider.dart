import 'package:flutter/foundation.dart';
import '../../data/models/transparencia_models.dart';
import '../../data/repositories/transparencia_repository.dart';

class TransparenciaProvider extends ChangeNotifier {
  final TransparenciaRepository _repository;

  TransparenciaResumoModel? _resumo;
  DespesasMensaisModel? _despesasMensais;
  List<TransparenciaPublicacaoModel> _publicacoes = [];
  bool _isLoading = false;
  String? _errorMessage;

  TransparenciaProvider(this._repository);

  TransparenciaResumoModel? get resumo => _resumo;
  DespesasMensaisModel? get despesasMensais => _despesasMensais;
  List<TransparenciaPublicacaoModel> get publicacoes => _publicacoes;
  bool get isLoading => _isLoading;
  bool get hasData => _resumo != null;
  String? get errorMessage => _errorMessage;

  Future<void> carregarTudo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getResumo(),
        _repository.getDespesasMensais(DateTime.now().year),
        _repository.getPublicacoes(),
      ]);
      _resumo = results[0] as TransparenciaResumoModel;
      _despesasMensais = results[1] as DespesasMensaisModel;
      _publicacoes = (results[2] as List).cast<TransparenciaPublicacaoModel>();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> criarPublicacao(Map<String, dynamic> payload) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final payloadNormalizado = Map<String, dynamic>.from(payload);
      if (payloadNormalizado['valorTotal'] != null) {
        final valor = payloadNormalizado['valorTotal'].toString();
        if (valor.isNotEmpty) {
          payloadNormalizado['valorTotal'] = double.tryParse(valor.replaceAll(',', '.'));
        }
      }
      await _repository.criarPublicacao(payloadNormalizado);
      await carregarPublicacoes();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> publicar(String id) async {
    try {
      await _repository.publicarPublicacao(id);
      await carregarPublicacoes();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> remover(String id) async {
    try {
      await _repository.removerPublicacao(id);
      await carregarPublicacoes();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> carregarPublicacoes() async {
    try {
      _publicacoes = await _repository.getPublicacoes();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}