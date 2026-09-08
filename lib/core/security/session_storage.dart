import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Armazena segredos da sessão (access/refresh token) de forma segura.
///
/// Em plataformas nativas (Android/iOS) usa o Keystore/Keychain via
/// [FlutterSecureStorage]. Na Web não há keystore do sistema operacional;
/// o fallback usa SharedPreferences (IndexedDB do navegador), já que a
/// criptografia real exige um backend de servidor.
class SessionStorage {
  static const _storage = FlutterSecureStorage();

  static bool get _usarSeguro => !kIsWeb;

  static Future<String?> readToken(String key) async {
    if (_usarSeguro) {
      return _storage.read(key: key);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> writeToken(String key, String value) async {
    if (_usarSeguro) {
      await _storage.write(key: key, value: value);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  static Future<void> removeToken(String key) async {
    if (_usarSeguro) {
      await _storage.delete(key: key);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }
}