import 'package:flutter/foundation.dart';
import '../../data/models/patrimonio_models.dart';
import '../../data/repositories/patrimonio_repository.dart';

class PatrimonioProvider extends ChangeNotifier {
  final PatrimonioRepository _repository;

  List<PatrimonioModel> _bens = [];
  bool _isLoading = false;
  String? _errorMessage;

  PatrimonioProvider(this._repository);

  List<PatrimonioModel> get bens => _bens;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> carregarBens() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bens = await _repository.getBens();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> criarBem({
    String? tombamento,
    required String descricao,
    String? categoria,
    String? estado,
    String? localizacao,
    String? dataAquisicao,
    String? valorAquisicao,
    String? responsavelNome,
    String? numeroNotaFiscal,
    String? observacoes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        if (tombamento != null && tombamento.isNotEmpty) 'tombamento': tombamento,
        'descricao': descricao,
        if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
        if (estado != null && estado.isNotEmpty) 'estado': estado,
        if (localizacao != null && localizacao.isNotEmpty) 'localizacao': localizacao,
        if (dataAquisicao != null && dataAquisicao.isNotEmpty) 'dataAquisicao': dataAquisicao,
        if (valorAquisicao != null && valorAquisicao.isNotEmpty)
          'valorAquisicao': double.tryParse(valorAquisicao.replaceAll(',', '.')),
        if (responsavelNome != null && responsavelNome.isNotEmpty) 'responsavelNome': responsavelNome,
        if (numeroNotaFiscal != null && numeroNotaFiscal.isNotEmpty) 'numeroNotaFiscal': numeroNotaFiscal,
        if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
      };
      await _repository.criarBem(payload);
      await carregarBens();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}