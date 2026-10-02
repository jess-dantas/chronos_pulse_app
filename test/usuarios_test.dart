import 'package:flutter_test/flutter_test.dart';
import 'package:chronos_pulse_app/core/network/dio_client.dart';
import 'package:chronos_pulse_app/core/router/app_router.dart';
import 'package:chronos_pulse_app/features/auth/data/models/usuario_model.dart';
import 'package:chronos_pulse_app/features/usuarios/data/datasources/usuario_remote_datasource.dart';
import 'package:chronos_pulse_app/features/usuarios/data/models/usuario_conta_model.dart';
import 'package:chronos_pulse_app/features/usuarios/data/repositories/usuario_repository.dart';
import 'package:chronos_pulse_app/features/usuarios/presentation/providers/usuario_provider.dart';

class _FakeUsuarioDataSource extends UsuarioRemoteDataSource {
  _FakeUsuarioDataSource() : super(DioClient());

  List<UsuarioContaModel> contas = [
    UsuarioContaModel(
      id: 'u1',
      cpf: '22222222222',
      nome: 'Ana Gestora',
      email: 'ana@empresa.com',
      role: 'GESTOR_RH',
      ativo: true,
      criadoEm: '2026-01-01T00:00:00Z',
    ),
  ];
  bool falhar = false;
  String? cpfCriado;
  String? papelCriado;
  String? suspensoId;

  @override
  Future<List<UsuarioContaModel>> listar() async {
    if (falhar) throw Exception('rede indisponível');
    return List.of(contas);
  }

  @override
  Future<UsuarioContaModel> criar({
    required String cpf,
    required String nome,
    String? emailCorporativo,
    required String senha,
    required String papel,
  }) async {
    if (falhar) throw Exception('rede indisponível');
    cpfCriado = cpf;
    papelCriado = papel;
    final nova = UsuarioContaModel(
      id: 'novo',
      cpf: cpf,
      nome: nome,
      email: emailCorporativo ?? '',
      role: papel,
      ativo: true,
    );
    contas = [...contas, nova];
    return nova;
  }

  @override
  Future<void> suspender(String usuarioId) async {
    if (falhar) throw Exception('rede indisponível');
    suspensoId = usuarioId;
    contas = [
      for (final c in contas)
        c.id == usuarioId
            ? UsuarioContaModel(
                id: c.id,
                cpf: c.cpf,
                nome: c.nome,
                email: c.email,
                role: c.role,
                ativo: false,
                criadoEm: c.criadoEm,
              )
            : c,
    ];
  }
}

void main() {
  UsuarioProvider providerCom(_FakeUsuarioDataSource fake) =>
      UsuarioProvider(UsuarioRepository(remoteDataSource: fake));

  group('UsuarioContaModel.fromJson', () {
    test('mapeia os campos da resposta do backend', () {
      final model = UsuarioContaModel.fromJson({
        'id': 'abc',
        'cpf': '11111111111',
        'nome': 'Bruno',
        'email': 'bruno@empresa.com',
        'role': 'ADMIN_EMPRESA',
        'ativo': false,
        'criadoEm': '2026-02-02T10:00:00Z',
      });

      expect(model.id, 'abc');
      expect(model.cpf, '11111111111');
      expect(model.role, 'ADMIN_EMPRESA');
      expect(model.ativo, isFalse);
      expect(model.criadoEm, '2026-02-02T10:00:00Z');
    });
  });

  group('UsuarioProvider', () {
    test('carregarUsuarios preenche a lista', () async {
      final fake = _FakeUsuarioDataSource();
      final provider = providerCom(fake);

      await provider.carregarUsuarios();

      expect(provider.usuarios, hasLength(1));
      expect(provider.usuarios.first.nome, 'Ana Gestora');
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('criarUsuario cria e recarrega a lista', () async {
      final fake = _FakeUsuarioDataSource();
      final provider = providerCom(fake);

      final criado = await provider.criarUsuario(
        cpf: '33333333333',
        nome: 'Carlos',
        senha: 'S3nh@Forte',
        papel: 'GESTOR_RH',
      );

      expect(criado, isNotNull);
      expect(fake.cpfCriado, '33333333333');
      expect(fake.papelCriado, 'GESTOR_RH');
      expect(provider.usuarios, hasLength(2));
      expect(provider.errorMessage, isNull);
    });

    test('criarUsuario propaga erro do backend', () async {
      final fake = _FakeUsuarioDataSource()..falhar = true;
      final provider = providerCom(fake);

      final criado = await provider.criarUsuario(
        cpf: '33333333333',
        nome: 'Carlos',
        senha: 'S3nh@Forte',
        papel: 'GESTOR_RH',
      );

      expect(criado, isNull);
      expect(provider.errorMessage, contains('Erro ao criar usuário'));
      expect(provider.usuarios, isEmpty);
    });

    test('suspenderUsuario marca a conta como inativa', () async {
      final fake = _FakeUsuarioDataSource();
      final provider = providerCom(fake);
      await provider.carregarUsuarios();

      final sucesso = await provider.suspenderUsuario('u1');

      expect(sucesso, isTrue);
      expect(fake.suspensoId, 'u1');
      expect(provider.usuarios.first.ativo, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('suspenderUsuario propaga erro do backend', () async {
      final fake = _FakeUsuarioDataSource()..falhar = true;
      final provider = providerCom(fake);

      final sucesso = await provider.suspenderUsuario('u1');

      expect(sucesso, isFalse);
      expect(provider.errorMessage, contains('Erro ao suspender usuário'));
    });
  });

  group('Rota /painel/usuarios (gate por papel)', () {
    UsuarioModel usuario(String role) => UsuarioModel(
          token: 't',
          tipo: 'Bearer',
          nome: 'Teste',
          email: 't@e.com',
          role: role,
        );

    test('ADMIN_EMPRESA acessa', () {
      expect(AppRouter.podeModuloPainel(usuario('ADMIN_EMPRESA'), 'usuarios'),
          isTrue);
    });

    test('GESTOR_RH e COLABORADOR não acessam', () {
      expect(AppRouter.podeModuloPainel(usuario('GESTOR_RH'), 'usuarios'),
          isFalse);
      expect(AppRouter.podeModuloPainel(usuario('COLABORADOR'), 'usuarios'),
          isFalse);
      expect(AppRouter.podeModuloPainel(usuario('SUPORTE_N1'), 'usuarios'),
          isFalse);
    });

    test('usuarios entra na ordem do painel após colaboradores', () {
      final ordem = AppRouter.painelOrdem;
      expect(ordem.indexOf('usuarios'),
          ordem.indexOf('colaboradores') + 1);
    });
  });
}
