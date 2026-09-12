import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/router/app_router.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';

UsuarioModel _usuario({
  required String role,
  bool acessoEstoque = false,
  List<String> modulos = const [
    'PONTO',
    'RECURSOS_HUMANOS',
    'ESTOQUE',
    'COMPRAS',
    'LICITACOES',
    'PATRIMONIO',
    'FROTA',
    'PROTOCOLO',
    'TRANSPARENCIA',
  ],
}) {
  return UsuarioModel(
    token: 'token-x',
    tipo: 'Bearer',
    nome: 'Teste',
    email: 'teste@teste.com',
    cpf: '12345678901',
    role: role,
    tenantId: 'tenant-1',
    acessoEstoque: acessoEstoque,
    modulos: modulos,
  );
}

void main() {
  group('podeModuloPainel - gate por role (alinhado ao backend)', () {
    test('COLABORADOR padrão: apenas ponto e módulos de leitura básica', () {
      final u = _usuario(role: 'COLABORADOR');

      expect(AppRouter.podeModuloPainel(u, 'ponto'), isTrue);
      expect(AppRouter.podeModuloPainel(u, 'patrimonio'), isTrue);
      expect(AppRouter.podeModuloPainel(u, 'frota'), isTrue);
      expect(AppRouter.podeModuloPainel(u, 'protocolo'), isTrue);
      expect(AppRouter.podeModuloPainel(u, 'transparencia'), isTrue);
      expect(AppRouter.podeModuloPainel(u, 'privacidade'), isTrue);

      expect(AppRouter.podeModuloPainel(u, 'estoque'), isFalse);
      expect(AppRouter.podeModuloPainel(u, 'compras'), isFalse);
      expect(AppRouter.podeModuloPainel(u, 'licitacoes'), isFalse);
      expect(AppRouter.podeModuloPainel(u, 'colaboradores'), isFalse);
    });

    test('COLABORADOR almoxarife (acessoEstoque): ganha estoque/compras/licitações', () {
      final u = _usuario(role: 'COLABORADOR', acessoEstoque: true);

      expect(AppRouter.podeModuloPainel(u, 'ponto'), isTrue);
      expect(AppRouter.podeModuloPainel(u, 'estoque'), isTrue);
      expect(AppRouter.podeModuloPainel(u, 'compras'), isTrue);
      expect(AppRouter.podeModuloPainel(u, 'licitacoes'), isTrue);
      expect(AppRouter.podeModuloPainel(u, 'colaboradores'), isFalse);
    });

    test('ADMIN_EMPRESA/GESTOR_RH: acesso a todos os módulos do painel', () {
      for (final role in ['ADMIN_EMPRESA', 'GESTOR_RH']) {
        final u = _usuario(role: role);

        expect(AppRouter.podeModuloPainel(u, 'ponto'), isTrue);
        expect(AppRouter.podeModuloPainel(u, 'colaboradores'), isTrue);
        expect(AppRouter.podeModuloPainel(u, 'estoque'), isTrue);
        expect(AppRouter.podeModuloPainel(u, 'compras'), isTrue);
        expect(AppRouter.podeModuloPainel(u, 'licitacoes'), isTrue);
        expect(AppRouter.podeModuloPainel(u, 'patrimonio'), isTrue);
        expect(AppRouter.podeModuloPainel(u, 'frota'), isTrue);
        expect(AppRouter.podeModuloPainel(u, 'protocolo'), isTrue);
        expect(AppRouter.podeModuloPainel(u, 'transparencia'), isTrue);
      }
    });

    test('SUPORTE: não recebe módulos do painel de negócio', () {
      final u = _usuario(role: 'SUPORTE_N1');

      for (final modulo in [
        'ponto',
        'colaboradores',
        'estoque',
        'compras',
        'licitacoes',
        'patrimonio',
        'frota',
        'protocolo',
        'transparencia',
      ]) {
        expect(AppRouter.podeModuloPainel(u, modulo), isFalse,
            reason: 'SUPORTE não deve acessar o módulo $modulo');
      }
      expect(AppRouter.podeModuloPainel(u, 'privacidade'), isTrue);
    });

    test('Colaborador sem módulo contratado pelo tenant não vê o item', () {
      final u = _usuario(role: 'COLABORADOR', modulos: const ['PONTO']);

      expect(AppRouter.podeModuloPainel(u, 'ponto'), isTrue);
      expect(AppRouter.podeModuloPainel(u, 'patrimonio'), isFalse);
      expect(AppRouter.podeModuloPainel(u, 'estoque'), isFalse);
    });
  });
}