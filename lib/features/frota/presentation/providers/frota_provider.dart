import 'package:flutter/foundation.dart';
import '../../../../core/network/paginated_response.dart';
import '../../data/models/frota_models.dart';
import '../../data/repositories/frota_repository.dart';

class FrotaProvider extends ChangeNotifier {
  final FrotaRepository _repository;

  List<FrotaVeiculoModel> _veiculos = [];
  List<AbastecimentoModel> _abastecimentos = [];
  int _paginaVeiculos = 0;
  int _paginaAbastecimentos = 0;
  bool _hasMoreVeiculos = false;
  bool _hasMoreAbastecimentos = false;
  bool _carregandoMaisVeiculos = false;
  bool _carregandoMaisAbastecimentos = false;
  bool _isLoading = false;
  String? _errorMessage;

  FrotaProvider(this._repository);

  List<FrotaVeiculoModel> get veiculos => _veiculos;
  List<AbastecimentoModel> get abastecimentos => _abastecimentos;
  bool get isLoading => _isLoading;
  bool get hasMoreVeiculos => _hasMoreVeiculos;
  bool get hasMoreAbastecimentos => _hasMoreAbastecimentos;
  bool get carregandoMaisVeiculos => _carregandoMaisVeiculos;
  bool get carregandoMaisAbastecimentos => _carregandoMaisAbastecimentos;
  String? get errorMessage => _errorMessage;

  Future<void> carregarTudo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getVeiculos(page: 0, size: 50),
        _repository.getAbastecimentos(page: 0, size: 50),
      ]);
      final veic = results[0] as PaginatedResponse<FrotaVeiculoModel>;
      final abas = results[1] as PaginatedResponse<AbastecimentoModel>;
      _veiculos = veic.items;
      _abastecimentos = abas.items;
      _paginaVeiculos = 0;
      _paginaAbastecimentos = 0;
      _hasMoreVeiculos = veic.hasMore;
      _hasMoreAbastecimentos = abas.hasMore;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarMaisVeiculos() async {
    if (_isLoading || _carregandoMaisVeiculos || !_hasMoreVeiculos) return;
    _carregandoMaisVeiculos = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final pagina = await _repository.getVeiculos(page: _paginaVeiculos + 1, size: 50);
      _veiculos = [..._veiculos, ...pagina.items];
      _paginaVeiculos += 1;
      _hasMoreVeiculos = pagina.hasMore;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _carregandoMaisVeiculos = false;
      notifyListeners();
    }
  }

  Future<void> carregarMaisAbastecimentos() async {
    if (_isLoading || _carregandoMaisAbastecimentos || !_hasMoreAbastecimentos) return;
    _carregandoMaisAbastecimentos = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final pagina = await _repository.getAbastecimentos(page: _paginaAbastecimentos + 1, size: 50);
      _abastecimentos = [..._abastecimentos, ...pagina.items];
      _paginaAbastecimentos += 1;
      _hasMoreAbastecimentos = pagina.hasMore;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _carregandoMaisAbastecimentos = false;
      notifyListeners();
    }
  }

  Future<bool> criarVeiculo(Map<String, dynamic> payload) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizado = Map<String, dynamic>.from(payload);
      final odometro = normalizado['odometroAtual']?.toString();
      if (odometro != null && odometro.isNotEmpty) {
        normalizado['odometroAtual'] = double.tryParse(odometro.replaceAll(',', '.'));
      }
      await _repository.criarVeiculo(normalizado);
      await carregarTudo();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarAbastecimento(Map<String, dynamic> payload) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizado = Map<String, dynamic>.from(payload);
      for (final campo in ['litros', 'valorLitro', 'odometroKm']) {
        final valor = normalizado[campo]?.toString();
        if (valor != null && valor.isNotEmpty) {
          normalizado[campo] = double.tryParse(valor.replaceAll(',', '.'));
        }
      }
      await _repository.registrarAbastecimento(normalizado);
      await carregarTudo();
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