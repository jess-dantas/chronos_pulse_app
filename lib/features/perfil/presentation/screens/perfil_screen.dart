import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../../admin/presentation/providers/admin_auth_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Tela de profile (`/perfil`), acessível pelo toque no profile fixo
/// do rail (MainShell/AdminShell).
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final adminAuth = context.watch<AdminAuthProvider>();
    final usuario = auth.usuario;
    final ehAdminRoot = adminAuth.isAuthenticated;
    final admin = adminAuth.currentAdmin;

    final nome = ehAdminRoot
        ? ((admin?.nomeCompleto.isNotEmpty ?? false)
            ? admin!.nomeCompleto
            : 'Administrador')
        : (usuario?.nome.isNotEmpty ?? false)
            ? usuario!.nome
            : (usuario?.role ?? '—');
    final email = ehAdminRoot ? (admin?.email ?? '—') : (usuario?.email ?? '—');
    final papel = ehAdminRoot
        ? 'ADMIN_PLATAFORMA'
        : (usuario?.role ?? '—');
    final cpf = ehAdminRoot ? null : usuario?.cpf;
    final empresa = ehAdminRoot ? null : usuario?.tenantSlug;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                UserAvatar(
                  nome: nome,
                  raio: 40,
                  icone:
                      ehAdminRoot ? Icons.admin_panel_settings : null,
                ),
                const SizedBox(height: 12),
                Text(
                  nome,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Chip(
                  avatar: const Icon(Icons.badge_outlined, size: 16),
                  label: Text(papel),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('E-mail'),
                  subtitle: Text(email),
                ),
                if (cpf != null && cpf.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('CPF'),
                    subtitle: Text(cpf),
                  ),
                if (empresa != null && empresa.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: const Text('Empresa'),
                    subtitle: Text(empresa),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (usuario != null && usuario.isAdminEmpresa) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.deepPurple),
                title: const Text('Transferir titularidade'),
                subtitle: const Text(
                  'Passa a titularidade da empresa para outro colaborador '
                  'após confirmação de biometria, celular e e-mail corporativo.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/perfil/titularidade'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (!ehAdminRoot && usuario != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Alterar senha'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _abrirDialogoSenha(context, auth),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (ehAdminRoot)
            Card(
              child: ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Segurança (2FA)'),
                subtitle: const Text('Gerenciar autenticação em dois fatores'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/admin/seguranca'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _abrirDialogoSenha(
    BuildContext context,
    AuthProvider auth,
  ) async {
    final controladorAtual = TextEditingController();
    final controladorNova = TextEditingController();
    final controladorConfirmacao = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controladorAtual,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Informe a senha atual' : null,
              ),
              TextFormField(
                controller: controladorNova,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: (v) => (v == null || v.length < 8)
                    ? 'Mínimo de 8 caracteres'
                    : null,
              ),
              TextFormField(
                controller: controladorConfirmacao,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirmar nova senha'),
                validator: (v) => v != controladorNova.text
                    ? 'Senhas não conferem'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final ok = await auth.alterarSenha(
                senhaAtual: controladorAtual.text,
                novaSenha: controladorNova.text,
              );
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Senha alterada com sucesso.'
                          : (auth.errorMessage ?? 'Erro ao alterar a senha.'),
                    ),
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
