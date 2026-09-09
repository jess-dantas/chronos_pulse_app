import 'package:flutter/foundation.dart';
import '../../data/models/patrimonio_models.dart';
import '../../data/repositories/patrimonio_repository.dart';

class PatrimonioProvider extends ChangeNotifier {
  final PatrimonioRepository _repository;

  List<PatrimonioModel> _bens = [];
  int _pagina = 0;
  bool _hasMore = false;
  bool _carregandoMais = false;
  bool _isLoading = false;
  bool _buscando = false;
  String? _errorMessage;

  PatrimonioProvider(this._repository);

  List<PatrimonioModel> get bens => _bens;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get carregandoMais => _carregandoMais;
  bool get buscando => _buscando;
  String? get errorMessage => _errorMessage;

  Future<void> carregarBens() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pagina = await _repository.getBens(page: 0, size: 50);
      _bens = pagina.items;
      _pagina = 0;
      _hasMore = pagina.hasMore;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarMaisBens() async {
    if (_isLoading || _carregandoMais || !_hasMore) return;
    _carregandoMais = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final pagina = await _repository.getBens(page: _pagina + 1, size: 50);
      _bens = [..._bens, ...pagina.items];
      _pagina += 1;
      _hasMore = pagina.hasMore;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _carregandoMais = false;
      notifyListeners();
    }
  }

  Future<void> buscarBens(String termo) async {
    final texto = termo.trim();
    if (texto.isEmpty) {
      await carregarBens();
      return;
    }
    _buscando = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _bens = await _repository.buscarBens(texto);
      _hasMore = false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _buscando = false;
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
    String? vidaUtilMeses,
    String? dataInicioDepreciacao,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = _montarPayload(
        tombamento: tombamento,
        descricao: descricao,
        categoria: categoria,
        estado: estado,
        localizacao: localizacao,
        dataAquisicao: dataAquisicao,
        valorAquisicao: valorAquisicao,
        responsavelNome: responsavelNome,
        numeroNotaFiscal: numeroNotaFiscal,
        observacoes: observacoes,
        vidaUtilMeses: vidaUtilMeses,
        dataInicioDepreciacao: dataInicioDepreciacao,
      );
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

  Future<bool> atualizarBem({
    required String id,
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
    String? vidaUtilMeses,
    String? dataInicioDepreciacao,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = _montarPayload(
        tombamento: tombamento,
        descricao: descricao,
        categoria: categoria,
        estado: estado,
        localizacao: localizacao,
        dataAquisicao: dataAquisicao,
        valorAquisicao: valorAquisicao,
        responsavelNome: responsavelNome,
        numeroNotaFiscal: numeroNotaFiscal,
        observacoes: observacoes,
        vidaUtilMeses: vidaUtilMeses,
        dataInicioDepreciacao: dataInicioDepreciacao,
      );
      await _repository.atualizarBem(id, payload);
      await carregarBens();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> desativarBem(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.desativarBem(id);
      await carregarBens();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<PatrimonioModel?> buscarPorQrCode(String codigo) async {
    try {
      return await _repository.buscarPorQrCode(codigo);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Map<String, dynamic> _montarPayload({
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
    String? vidaUtilMeses,
    String? dataInicioDepreciacao,
  }) {
    return <String, dynamic>{
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
      if (vidaUtilMeses != null && vidaUtilMeses.isNotEmpty)
        'vidaUtilMeses': int.tryParse(vidaUtilMeses),
      if (dataInicioDepreciacao != null && dataInicioDepreciacao.isNotEmpty)
        'dataInicioDepreciacao': dataInicioDepreciacao,
    };
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}