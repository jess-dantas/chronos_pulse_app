import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/security/device_token_store.dart';
import '../../../../core/widgets/dialogs/confirm_logout_dialog.dart';
import '../../../../core/widgets/logout_helper.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../admin/presentation/providers/admin_auth_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Tela de profile (`/perfil`), acessível pelo toque no profile fixo
/// do rail (MainShell/AdminShell) e pela dock mobile.
///
/// Concentra os dados do usuário, a troca de foto e a saída da sessão.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  /// Vínculo de dispositivo (modo ponto sem login) — só mobile.
  VinculoDispositivo? _vinculo;
  bool _processandoVinculo = false;

  @override
  void initState() {
    super.initState();
    _carregarVinculo();
  }

  Future<void> _carregarVinculo() async {
    if (kIsWeb) return;
    final vinculo = await DeviceTokenStore.instancia.lerAtivo();
    if (mounted) setState(() => _vinculo = vinculo);
  }

  Future<void> _ativarVinculo() async {
    final auth = context.read<AuthProvider>();
    final nome = auth.usuario?.nome.isNotEmpty == true
        ? auth.usuario!.nome
        : 'Dispositivo móvel';
    setState(() => _processandoVinculo = true);
    final expiraEm = await auth.ativarVinculoDispositivo(deviceName: nome);
    if (!mounted) return;
    setState(() => _processandoVinculo = false);
    if (expiraEm != null) {
      await _carregarVinculo();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Dispositivo vinculado! Agora você pode bater ponto sem login '
              'por 7 dias, com biometria.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Erro ao ativar o dispositivo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _desativarVinculo() async {
    final auth = context.read<AuthProvider>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desativar bater ponto sem login?'),
        content: const Text(
          'Os vínculos de dispositivo desta conta serão revogados no servidor. '
          'Para voltar a bater ponto sem login será preciso ativar novamente '
          'com sua sessão aberta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _processandoVinculo = true);
    final ok = await auth.desativarVinculoDispositivo();
    if (!mounted) return;
    setState(() {
      _processandoVinculo = false;
      _vinculo = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Bater ponto sem login desativado.'
            : (auth.errorMessage ?? 'Erro ao desativar o dispositivo.')),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
      ),
    );
    if (ok) await _carregarVinculo();
  }

  /// Troca a foto de perfil (máx. 512KB) via `POST /auth/me/foto`.
  Future<void> _selecionarFoto() async {
    final arquivo = await FilePicker.pickFile(type: FileType.image);
    if (arquivo == null) return;

    final bytes = await arquivo.readAsBytes();
    if (bytes.isEmpty) return;

    if (bytes.length > 512 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A imagem deve ter no máximo 512KB.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final sucesso = await authProvider.enviarFoto(bytes, arquivo.name);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Foto de perfil atualizada.'
              : authProvider.errorMessage ?? 'Erro ao atualizar a foto.',
        ),
        backgroundColor: sucesso ? Colors.green : Colors.redAccent,
      ),
    );
  }

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
    // A foto só existe para sessão de tenant (`POST /auth/me/foto`).
    final podeTrocarFoto = usuario != null;
    final fotoBytes = usuario?.temFoto == true ? usuario!.fotoBytes : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      // Largura máxima como na Home de Ponto: o conteúdo não estica em telas
      // largas (web/desktop).
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
          Center(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(
                      nome: nome,
                      raio: 40,
                      fotoBytes: fotoBytes,
                      icone:
                          ehAdminRoot ? Icons.admin_panel_settings : null,
                    ),
                    if (podeTrocarFoto)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Tooltip(
                          message: 'Alterar foto de perfil',
                          child: InkWell(
                            onTap: _selecionarFoto,
                            customBorder: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.photo_camera,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (podeTrocarFoto) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: _selecionarFoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 16),
                    label: const Text('Alterar foto'),
                  ),
                ],
                const SizedBox(height: 4),
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
            Card(
              child: ListTile(
                key: const Key('perfil_seguranca_tile'),
                leading: const Icon(Icons.security_outlined),
                title: const Text('Segurança'),
                subtitle: const Text(
                  'Biometria ao abrir o app e autenticação em duas etapas',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/perfil/seguranca'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Modo "bater ponto sem login" (vínculo de dispositivo, 7 dias).
          // Só faz sentido no app mobile: a Web mantém o login obrigatório.
          if (!kIsWeb && !ehAdminRoot && usuario != null) ...[
            Card(
              child: _processandoVinculo
                  ? const ListTile(
                      leading: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      title: Text('Processando vínculo...'),
                    )
                  : _vinculo != null
                      ? ListTile(
                          leading: const Icon(Icons.smartphone,
                              color: Colors.green),
                          title: const Text('Bater ponto sem login'),
                          subtitle: Text(
                            'Ativo até ${DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR').format(_vinculo!.expiraEm.toLocal())}'
                            '${_vinculo!.nome.isNotEmpty ? ' · ${_vinculo!.nome}' : ''}',
                          ),
                          trailing: TextButton(
                            onPressed: _desativarVinculo,
                            child: const Text(
                              'Desativar',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        )
                      : ListTile(
                          leading: const Icon(Icons.smartphone_outlined),
                          title: const Text('Bater ponto sem login'),
                          subtitle: const Text(
                            'Vincule este aparelho por 7 dias para registrar '
                            'ponto com biometria (e o código do 2FA, se '
                            'ativado), mesmo sem sessão aberta.',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _ativarVinculo,
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
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Sair',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Encerrar a sessão neste dispositivo'),
              onTap: () => encerrarSessaoConfirmada(context),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirDialogoSenha(
    BuildContext context,
    AuthProvider auth,
  ) async {
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
              final confirmado = await ConfirmLogoutDialog.show(
                dialogContext,
                title: 'Certeza de alterar senha?',
                message: 'A nova senha passa a valer nos próximos acessos. '
                    'Confira antes de confirmar.',
                confirmText: 'Alterar',
                cancelText: 'Desistir',
              );
              if (confirmado != true) return;
              if (!dialogContext.mounted) return;
              final ok = await auth.alterarSenha(
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
