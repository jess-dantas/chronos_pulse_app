import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/security/device_token_store.dart';

/// Store com persistência em memória (injeção de funções) — não toca em
/// Keystore/plugin de plataforma.
DeviceTokenStore _store([Map<String, String>? base]) {
  final mapa = <String, String>{...?base};
  return DeviceTokenStore(
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
  group('DeviceTokenStore', () {
    test('salvar e lerAtivo devolve o vínculo completo', () async {
      final store = _store();
      final expira = DateTime.now().toUtc().add(const Duration(days: 7));

      await store.salvar(
        token: 'dt-token-cru',
        cpcId: 'cpc-123',
        nome: 'Samsung A32',
        expiraEm: expira,
      );

      final vinculo = await store.lerAtivo();
      expect(vinculo, isNotNull);
      expect(vinculo!.token, 'dt-token-cru');
      expect(vinculo.cpcId, 'cpc-123');
      expect(vinculo.nome, 'Samsung A32');
      expect(vinculo.expiraEm.isAfter(DateTime.now().toUtc()), isTrue);
      expect(await store.vinculoAtivo(), isTrue);
    });

    test('sem vínculo gravado devolve null', () async {
      final store = _store();
      expect(await store.lerAtivo(), isNull);
      expect(await store.vinculoAtivo(), isFalse);
    });

    test('vínculo expirado devolve null e limpa os resíduos', () async {
      final store = _store();
      await store.salvar(
        token: 'dt-velho',
        cpcId: 'cpc-1',
        nome: 'Aparelho',
        expiraEm: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );

      expect(await store.lerAtivo(), isNull);
      expect(await store.vinculoAtivo(), isFalse);
      // O token vencido não pode ficar guardado no dispositivo.
      expect(await store.lerAtivo(), isNull);
    });

    test('dados incompletos (sem expiração/dono) são tratados como sem vínculo',
        () async {
      final store = _store({
        DeviceTokenStore.chaveToken: 'dt-sem-resto',
      });

      expect(await store.lerAtivo(), isNull);
      // E o resíduo é removido (fail-safe).
      expect(await store.lerAtivo(), isNull);
    });

    test('limpar remove todas as chaves', () async {
      final store = _store();
      await store.salvar(
        token: 'dt-x',
        cpcId: 'cpc-x',
        nome: 'X',
        expiraEm: DateTime.now().toUtc().add(const Duration(days: 1)),
      );

      await store.limpar();

      expect(await store.lerAtivo(), isNull);
      expect(await store.vinculoAtivo(), isFalse);
    });
  });
}
