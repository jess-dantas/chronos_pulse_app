import 'package:flutter/foundation.dart';
import '../../data/models/protocolo_models.dart';
import '../../data/repositories/protocolo_repository.dart';

class ProtocoloProvider extends ChangeNotifier {
  final ProtocoloRepository _repository;

  List<ProtocoloModel> _protocolos = [];
  int _pagina = 0;
  bool _hasMore = false;
  bool _carregandoMais = false;
  bool _isLoading = false;
  String? _errorMessage;

  ProtocoloProvider(this._repository);

  List<ProtocoloModel> get protocolos => _protocolos;
  List<ProtocoloModel> get protocolosRecebido =>
      _protocolos.where((p) => p.status == 'RECEBIDO').toList();
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get carregandoMais => _carregandoMais;
  String? get errorMessage => _errorMessage;

  Future<void> carregarProtocolos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pagina = await _repository.getProtocolos(page: 0, size: 50);
      _protocolos = pagina.items;
      _pagina = 0;
      _hasMore = pagina.hasMore;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarMaisProtocolos() async {
    if (_isLoading || _carregandoMais || !_hasMore) return;
    _carregandoMais = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final pagina = await _repository.getProtocolos(page: _pagina + 1, size: 50);
      _protocolos = [..._protocolos, ...pagina.items];
      _pagina += 1;
      _hasMore = pagina.hasMore;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _carregandoMais = false;
      notifyListeners();
    }
  }

  Future<bool> criarProtocolo({
    required String numeroProtocolo,
    required String tipo,
    required String assunto,
    String? descricao,
    String? remetente,
    String? destinatario,
    String? responsavel,
    String? observacoes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'numeroProtocolo': numeroProtocolo,
        'tipo': tipo,
        'assunto': assunto,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
        if (remetente != null && remetente.isNotEmpty) 'remetente': remetente,
        if (destinatario != null && destinatario.isNotEmpty) 'destinatario': destinatario,
        if (responsavel != null && responsavel.isNotEmpty) 'responsavel': responsavel,
        if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
      };
      await _repository.criarProtocolo(payload);
      await carregarProtocolos();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> atualizarStatus(String id, String status, {String? responsavel, String? observacoes}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.atualizarStatus(id, status, responsavel: responsavel, observacoes: observacoes);
      await carregarProtocolos();
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