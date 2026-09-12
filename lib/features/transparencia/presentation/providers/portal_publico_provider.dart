import 'package:flutter/foundation.dart';
import '../../data/models/portal_publico_models.dart';
import '../../data/models/transparencia_models.dart';
import '../../data/repositories/portal_publico_repository.dart';

class PortalPublicoProvider extends ChangeNotifier {
  final PortalPublicoRepository _repository;

  PortalResumoModel? _resumo;
  List<PortalLicitacaoModel> _licitacoes = [];
  List<PortalContratoModel> _contratos = [];
  List<PortalPublicacaoModel> _publicacoes = [];
  DespesasMensaisModel? _despesasMensais;
  PortalLicitacaoDetalheModel? _licitacaoDetalhe;
  PortalContratoDetalheModel? _contratoDetalhe;
  bool _isLoading = false;
  String? _errorMessage;

  PortalPublicoProvider(this._repository);

  PortalResumoModel? get resumo => _resumo;
  List<PortalLicitacaoModel> get licitacoes => _licitacoes;
  List<PortalContratoModel> get contratos => _contratos;
  List<PortalPublicacaoModel> get publicacoes => _publicacoes;
  DespesasMensaisModel? get despesasMensais => _despesasMensais;
  PortalLicitacaoDetalheModel? get licitacaoDetalhe => _licitacaoDetalhe;
  PortalContratoDetalheModel? get contratoDetalhe => _contratoDetalhe;
  bool get isLoading => _isLoading;
  bool get hasData => _resumo != null;
  String? get errorMessage => _errorMessage;

  Future<void> carregarTudo(String slug) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getResumo(slug),
        _repository.getLicitacoes(slug),
        _repository.getContratos(slug),
        _repository.getPublicacoes(slug),
        _repository.getDespesasMensais(slug, DateTime.now().year),
      ]);
      _resumo = results[0] as PortalResumoModel;
      _licitacoes = (results[1] as List).cast<PortalLicitacaoModel>();
      _contratos = (results[2] as List).cast<PortalContratoModel>();
      _publicacoes = (results[3] as List).cast<PortalPublicacaoModel>();
      _despesasMensais = results[4] as DespesasMensaisModel;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarDetalheLicitacao(String slug, String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _licitacaoDetalhe = await _repository.getLicitacao(slug, id);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarDetalheContrato(String slug, String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _contratoDetalhe = await _repository.getContrato(slug, id);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limparDetalhes() {
    _licitacaoDetalhe = null;
    _contratoDetalhe = null;
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}