import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferências de segurança do colaborador.
///
/// [ativa] controla se o gate biométrico exige a biometria do aparelho ao
/// abrir o app com a sessão restaurada (padrão: ativada). Quando desligada,
/// a restauração nasce desbloqueada e o gate não é cobrado.
class BiometriaPreferences extends ChangeNotifier {
  BiometriaPreferences({bool? ativa}) : _ativa = ativa ?? true;

  /// Chave persistida — também lida diretamente pelo AuthProvider na
  /// restauração da sessão.
  static const chave = 'chronos_biometria_ativa';

  bool _ativa;

  bool get ativa => _ativa;

  static Future<BiometriaPreferences> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    return BiometriaPreferences(ativa: prefs.getBool(chave) ?? true);
  }

  Future<void> setAtiva(bool valor) async {
    if (_ativa == valor) return;
    _ativa = valor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(chave, valor);
  }

  Future<void> alternar() => setAtiva(!_ativa);
}
