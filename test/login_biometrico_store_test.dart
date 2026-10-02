import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/security/login_biometrico_store.dart';

/// Store em memória (injeção de funções) — não toca em Keystore/plugin.
LoginBiometricoStore _store([Map<String, String>? base]) {
  final mapa = <String, String>{...?base};
  return LoginBiometricoStore(
    ler: (k) async => mapa[k],
    gravar: (k, v) async {
      mapa[k] = v;
    },
    remover: (k) async {
      mapa.remove(k);
    },
  );
}

void main() {
  group('LoginBiometricoStore', () {
    test('salvar devolve a credencial completa', () async {
      final store = _store();

      await store.salvar(cpf: '12345678901', senha: 'senha123');

      expect(await store.lerCpf(), '12345678901');
      expect(await store.lerSenha(), 'senha123');
      expect(await store.possuiCredencial(), isTrue);
    });

    test('sem credencial gravada não há credencial utilizável', () async {
      final store = _store();

      expect(await store.lerCpf(), isNull);
      expect(await store.possuiCredencial(), isFalse);
    });

    test('credencial parcial (só cpf) não vale como credencial', () async {
      final store = _store({LoginBiometricoStore.chaveCpf: '12345678901'});

      expect(await store.possuiCredencial(), isFalse);
    });

    test('credencial vazia não vale como credencial', () async {
      final store = _store({
        LoginBiometricoStore.chaveCpf: '',
        LoginBiometricoStore.chaveSenha: '',
      });

      expect(await store.possuiCredencial(), isFalse);
    });

    test('falha de leitura do armazenamento: sem credencial (fail-safe)',
        () async {
      final store = LoginBiometricoStore(
        ler: (k) async => throw Exception('keystore indisponível'),
        gravar: (k, v) async {},
        remover: (k) async {},
      );

      expect(await store.possuiCredencial(), isFalse);
    });

    test('limpar remove as duas chaves', () async {
      final store = _store();
      await store.salvar(cpf: '12345678901', senha: 'senha123');

      await store.limpar();

      expect(await store.lerCpf(), isNull);
      expect(await store.lerSenha(), isNull);
      expect(await store.possuiCredencial(), isFalse);
    });
  });
}
