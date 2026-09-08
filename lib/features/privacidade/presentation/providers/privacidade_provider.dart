import 'package:flutter/foundation.dart';
import '../../data/privacidade_datasource.dart';

class PrivacidadeProvider extends ChangeNotifier {
  final PrivacidadeDataSource _dataSource;

  PrivacidadeProvider(this._dataSource);

  Map<String, dynamic>? politica;
  Map<String, dynamic>? meusDados;
  bool isLoading = false;
  String? errorMessage;

  Future<void> carregarPolitica() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      politica = await _dataSource.getPolitica();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> registrarConsentimento() async {
    final versao = politica?['versao']?.toString() ?? '1.0';
    try {
      await _dataSource.registrarConsentimento(versao);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> exportarMeusDados() async {
    try {
      meusDados = await _dataSource.getMeusDados();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> apagarMeusDados() async {
    try {
      await _dataSource.apagarMeusDados();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}