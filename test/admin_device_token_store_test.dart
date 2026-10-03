import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/security/admin_device_token_store.dart';

/// Store com persistência em memória (injeção de funções) — não toca em
/// Keystore/plugin de plataforma.
AdminDeviceTokenStore _store([Map<String, String>? base]) {
  final mapa = <String, String>{...?base};
  return AdminDeviceTokenStore(
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
  group('AdminDeviceTokenStore', () {
    test('salvar e lerAtiva devolve a credencial completa', () async {
      final store = _store();
      final expira = DateTime.now().toUtc().add(const Duration(days: 30));

      await store.salvar(
        token: 'dt-cru-admin',
        username: 'Administrator',
        expiraEm: expira,
      );

      final credencial = await store.lerAtiva();
      expect(credencial, isNotNull);
      expect(credencial!.token, 'dt-cru-admin');
      expect(credencial.username, 'Administrator');
      expect(credencial.expiraEm.isAfter(DateTime.now().toUtc()), isTrue);
      expect(await store.possuiCredencial(), isTrue);
    });

    test('sem credencial gravada devolve null', () async {
      final store = _store();
      expect(await store.lerAtiva(), isNull);
      expect(await store.possuiCredencial(), isFalse);
    });

    test('credencial expirada devolve null e limpa os resíduos', () async {
      final store = _store();
      await store.salvar(
        token: 'dt-velho',
        username: 'Administrator',
        expiraEm: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );

      expect(await store.lerAtiva(), isNull);
      // O token vencido não pode ficar guardado no aparelho.
      expect(await store.lerAtiva(), isNull);
      expect(await store.possuiCredencial(), isFalse);
    });

    test('dados incompletos (sem username/expiração) são tratados como '
        'sem credencial', () async {
      final store = _store({
        AdminDeviceTokenStore.chaveToken: 'dt-sem-resto',
      });

      expect(await store.lerAtiva(), isNull);
      // E o resíduo é removido (fail-safe).
      expect(await store.lerAtiva(), isNull);
    });

    test('limpar remove todas as chaves', () async {
      final store = _store();
      await store.salvar(
        token: 'dt-x',
        username: 'root',
        expiraEm: DateTime.now().toUtc().add(const Duration(days: 30)),
      );

      await store.limpar();

      expect(await store.lerAtiva(), isNull);
      expect(await store.possuiCredencial(), isFalse);
    });
  });
}
