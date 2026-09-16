import 'package:flutter/foundation.dart';
import '../../../auth/data/repositories/lead_repository.dart';

class LeadsProvider extends ChangeNotifier {
  final LeadRepository _repository;

  LeadsProvider(this._repository);

  List<LeadEmpresaModel> _leads = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<LeadEmpresaModel> get leads => _leads;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Ordem canônica do funil de vendas.
  static const List<String> ordemFunil = [
    'NOVO',
    'AGENDADO',
    'REUNIAO',
    'CONTRATADO',
    'DESCARTADO',
  ];

  List<LeadEmpresaModel> leadsDoStatus(String status) =>
      _leads.where((l) => l.status == status).toList();

  int totalDoStatus(String status) =>
      _leads.where((l) => l.status == status).length;

  Future<void> carregarLeads() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _leads = await _repository.listar();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> mover(String id, String novoStatus) async {
    _errorMessage = null;
    try {
      final atualizado = await _repository.alterarStatus(id, novoStatus);
      final index = _leads.indexWhere((l) => l.id == id);
      if (index >= 0) {
        _leads = [..._leads]..[index] = atualizado;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Próximo status do funil (NOVO → AGENDADO → REUNIAO → CONTRATADO).
  String? proximoStatus(String atual) {
    const fluxo = ['NOVO', 'AGENDADO', 'REUNIAO', 'CONTRATADO'];
    final indice = fluxo.indexOf(atual);
    if (indice < 0 || indice == fluxo.length - 1) return null;
    return fluxo[indice + 1];
  }

  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}