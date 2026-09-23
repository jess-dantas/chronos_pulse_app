import 'package:flutter/foundation.dart';
import '../../data/privacidade_datasource.dart';

class PrivacidadeProvider extends ChangeNotifier {
  final PrivacidadeDataSource _dataSource;

  PrivacidadeProvider(this._dataSource);

  Map<String, dynamic>? politica;
  Map<String, dynamic>? meusDados;
  bool isLoading = false;
  String? errorMessage;

  /// Status do Termo de Ciência da versão vigente (GET .../consentimento/status).
  bool consentimentoPendente = false;
  String? versaoConsentimentoAceita;
  String? dataConsentimentoAceite;

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

  /// Carrega o status sem bloquear a UI: falha de rede não impede o painel
  /// (o modal de ciência tenta novamente no próximo acesso/restauração).
  Future<void> carregarStatusConsentimento() async {
    try {
      final status = await _dataSource.getStatusConsentimento();
      consentimentoPendente = status['aceitePendente'] == true;
      versaoConsentimentoAceita = status['versaoAceita']?.toString();
      dataConsentimentoAceite = status['dataConsentimento']?.toString();
    } catch (_) {
      // silencioso por design
    } finally {
      notifyListeners();
    }
  }

  Future<String?> registrarConsentimento() async {
    final versao = politica?['versao']?.toString() ?? '1.0';
    try {
      await _dataSource.registrarConsentimento(versao);
      consentimentoPendente = false;
      versaoConsentimentoAceita = versao;
      dataConsentimentoAceite = DateTime.now().toIso8601String();
      notifyListeners();
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