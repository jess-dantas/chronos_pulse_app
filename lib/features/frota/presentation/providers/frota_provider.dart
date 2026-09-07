import 'package:flutter/foundation.dart';
import '../../data/models/frota_models.dart';
import '../../data/repositories/frota_repository.dart';

class FrotaProvider extends ChangeNotifier {
  final FrotaRepository _repository;

  List<FrotaVeiculoModel> _veiculos = [];
  List<AbastecimentoModel> _abastecimentos = [];
  bool _isLoading = false;
  String? _errorMessage;

  FrotaProvider(this._repository);

  List<FrotaVeiculoModel> get veiculos => _veiculos;
  List<AbastecimentoModel> get abastecimentos => _abastecimentos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> carregarTudo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([_repository.getVeiculos(), _repository.getAbastecimentos()]);
      _veiculos = results[0] as List<FrotaVeiculoModel>;
      _abastecimentos = results[1] as List<AbastecimentoModel>;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
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