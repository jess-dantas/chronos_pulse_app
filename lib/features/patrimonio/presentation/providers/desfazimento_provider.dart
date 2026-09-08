import 'package:flutter/foundation.dart';
import '../../data/models/patrimonio_models.dart';
import '../../data/repositories/desfazimento_repository.dart';

class DesfazimentoProvider extends ChangeNotifier {
  final DesfazimentoRepository _repository;

  List<DesfazimentoModel> _solicitacoes = [];
  int _pagina = 0;
  bool _hasMore = false;
  bool _carregandoMais = false;
  bool _isLoading = false;
  String? _errorMessage;

  DesfazimentoProvider(this._repository);

  List<DesfazimentoModel> get solicitacoes => _solicitacoes;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get carregandoMais => _carregandoMais;
  String? get errorMessage => _errorMessage;

  Future<void> carregarSolicitacoes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pagina = await _repository.listarDesfazimentos(page: 0, size: 50);
      _solicitacoes = pagina.items;
      _pagina = 0;
      _hasMore = pagina.hasMore;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarMaisSolicitacoes() async {
    if (_isLoading || _carregandoMais || !_hasMore) return;
    _carregandoMais = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final pagina =
          await _repository.listarDesfazimentos(page: _pagina + 1, size: 50);
      _solicitacoes = [..._solicitacoes, ...pagina.items];
      _pagina += 1;
      _hasMore = pagina.hasMore;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _carregandoMais = false;
      notifyListeners();
    }
  }

  Future<bool> criarDesfazimento({
    required String patrimonioId,
    required String estadoBem,
    required String tipoDesfazimento,
    required String justificativa,
    required String responsavelSolicitacao,
    String? processoNumero,
    String? observacoes,
    List<Map<String, dynamic>> membrosComissao = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.criarDesfazimento({
        'patrimonioId': patrimonioId,
        'estadoBem': estadoBem,
        'tipoDesfazimento': tipoDesfazimento,
        'justificativa': justificativa,
        'responsavelSolicitacao': responsavelSolicitacao,
        if (processoNumero != null && processoNumero.isNotEmpty)
          'processoNumero': processoNumero,
        if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
        if (membrosComissao.isNotEmpty) 'membrosComissao': membrosComissao,
      });
      await carregarSolicitacoes();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> aprovar(String id, {String? parecerComissao}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.aprovarDesfazimento(id, parecerComissao: parecerComissao);
      await carregarSolicitacoes();
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
      await _repository.cancelarDesfazimento(id);
      await carregarSolicitacoes();
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