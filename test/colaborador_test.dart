import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/colaborador/data/models/colaborador_model.dart';

void main() {
  group('UsuarioModel - Regras de Permissão por Perfil e Acesso a Estoque', () {
    test('Admin Plataforma deve ter acesso irrestrito', () {
      final user = UsuarioModel(
        token: 'token-admin',
        tipo: 'Bearer',
        nome: 'Super Admin',
        email: 'admin@chronos.com',
        role: 'ADMIN_PLATAFORMA',
        acessoEstoque: false,
      );

      expect(user.isAdminPlataforma, isTrue);
      expect(user.isAdminOrRh, isTrue);
      expect(user.temAcessoEstoque, isTrue);
    });

    test('Gestor RH deve ter acesso irrestrito ao colaborador e estoque', () {
      final user = UsuarioModel(
        token: 'token-rh',
        tipo: 'Bearer',
        nome: 'Gestor RH',
        email: 'rh@empresa.com',
        role: 'GESTOR_RH',
        acessoEstoque: false,
      );

      expect(user.isGestorRh, isTrue);
      expect(user.isAdminOrRh, isTrue);
      expect(user.temAcessoEstoque, isTrue);
    });

    test('Colaborador sem flag de estoque não deve ter acesso ao estoque', () {
      final user = UsuarioModel(
        token: 'token-colab',
        tipo: 'Bearer',
        nome: 'Colaborador Comum',
        email: 'colab@empresa.com',
        role: 'COLABORADOR',
        acessoEstoque: false,
      );

      expect(user.isColaborador, isTrue);
      expect(user.isAdminOrRh, isFalse);
      expect(user.temAcessoEstoque, isFalse);
    });

    test('Colaborador com flag de estoque ativa deve ter acesso ao estoque', () {
      final user = UsuarioModel(
        token: 'token-colab-estoque',
        tipo: 'Bearer',
        nome: 'Colaborador Almoxarife',
        email: 'almoxarife@empresa.com',
        role: 'COLABORADOR',
        acessoEstoque: true,
      );

      expect(user.isColaborador, isTrue);
      expect(user.isAdminOrRh, isFalse);
      expect(user.temAcessoEstoque, isTrue);
    });
  });

  group('ColaboradorModel - Serialização e Mapeamento', () {
    test('Deve deserializar JSON corretamente com flag de estoque', () {
      final json = {
        'id': 'colab-123',
        'cpcUsuarioId': 'user-123',
        'tenantId': 'tenant-123',
        'cpf': '12345678901',
        'nome': 'João Silva',
        'email': 'joao@empresa.com',
        'matricula': 'MAT-001',
        'cargo': 'Assistente',
        'departamento': 'Logística',
        'dataAdmissao': '2024-01-01',
        'dataNascimento': '1990-05-10',
        'acessoEstoque': true,
        'ativo': true,
      };

      final model = ColaboradorModel.fromJson(json);

      expect(model.id, 'colab-123');
      expect(model.nome, 'João Silva');
      expect(model.acessoEstoque, isTrue);
      expect(model.ativo, isTrue);
    });
  });
}
