import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/security/admin_device_token_store.dart';
import '../../../../core/security/biometria_preferences.dart';
import '../../../admin/presentation/providers/admin_auth_provider.dart';

/// Tela "Segurança" (`/perfil/seguranca`), compartilhada por colaborador e
/// admin root.
///
/// Concentra o bloqueio biométrico ao abrir o app (toggle, padrão ativado —
/// vale também para o gate admin), a entrada para a gestão da autenticação
/// em duas etapas (colaborador → `/perfil/2fa`, admin root →
/// `/admin/seguranca`) e, só para o admin root, o dispositivo confiável
/// (biometria-first): ativa/revoga o deviceToken usado no login por
/// biometria.
class PerfilSegurancaScreen extends StatefulWidget {
  /// Store injetável (testes); padrão: o singleton do app.
  final AdminDeviceTokenStore? deviceStore;

  const PerfilSegurancaScreen({super.key, this.deviceStore});

  @override
  State<PerfilSegurancaScreen> createState() => _PerfilSegurancaScreenState();
}

class _PerfilSegurancaScreenState extends State<PerfilSegurancaScreen> {
  late final AdminDeviceTokenStore _store =
      widget.deviceStore ?? AdminDeviceTokenStore.instancia;

  AdminDeviceCredencial? _credencial;
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _carregarCredencial();
  }

  Future<void> _carregarCredencial() async {
    final credencial = await _store.lerAtiva();
    if (mounted) setState(() => _credencial = credencial);
  }

  /// Ativa: POST /admin/auth/dispositivo → grava a credencial local.
  Future<void> _ativar() async {
    final adminAuth = context.read<AdminAuthProvider>();
    setState(() => _processando = true);

    final resultado = await adminAuth.vincularDispositivo();
    if (!mounted) return;

    if (resultado != null) {
      final token = resultado['deviceToken'] as String;
      final expiraEm =
          DateTime.parse(resultado['expiraEm'] as String).toUtc();
      final username = adminAuth.currentAdmin?.username ?? '';
      await _store.salvar(token: token, username: username, expiraEm: expiraEm);
      await _carregarCredencial();
      if (!mounted) return;
      setState(() => _processando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este dispositivo agora entra com a biometria, '
              'sem senha nem código.'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    setState(() => _processando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(adminAuth.errorMessage ?? 'Erro ao confiar no dispositivo.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  /// Revoga (com confirmação): DELETE → limpa a credencial local.
  Future<void> _revogar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revogar este dispositivo?'),
        content: const Text(
            'Este aparelho voltará a exigir senha (e código de verificação, '
            'se houver) no próximo login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revogar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final adminAuth = context.read<AdminAuthProvider>();
    setState(() => _processando = true);
    final ok = await adminAuth.revogarDispositivo();
    await _store.limpar();
    if (!mounted) return;
    await _carregarCredencial();
    if (!mounted) return;
    setState(() => _processando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Dispositivo revogado. Use senha ou código no próximo login.'
            : adminAuth.errorMessage ?? 'Erro ao revogar o dispositivo.'),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
      ),
    );
  }

  String _formatarExpiracao(DateTime expiraEm) {
    final local = expiraEm.toLocal();
    String dois(int v) => v.toString().padLeft(2, '0');
    return '${dois(local.day)}/${dois(local.month)}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final biometria = context.watch<BiometriaPreferences>();
    final adminAuth = context.watch<AdminAuthProvider>();
    final ehAdminRoot = adminAuth.isAuthenticated;

    return Scaffold(
      appBar: AppBar(title: const Text('Segurança')),
      // Largura máxima como no Perfil: o conteúdo não estica em telas
      // largas (web/desktop).
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Sem gate biométrico na web — só faz sentido no aplicativo.
              if (!kIsWeb) ...[
                Card(
                  child: SwitchListTile(
                    key: const Key('seguranca_biometria_switch'),
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('Exigir biometria ao abrir'),
                    subtitle: const Text(
                      'Pede a digital ou o rosto do aparelho quando você abre '
                      'o app com a sessão salva.',
                    ),
                    value: biometria.ativa,
                    onChanged: biometria.setAtiva,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Card(
                child: ListTile(
                  key: const Key('seguranca_two_factor_tile'),
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Autenticação em duas etapas'),
                  subtitle: const Text(
                    'Proteja seu acesso com um código de 6 dígitos',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: ehAdminRoot
                      ? () => context.go('/admin/seguranca')
                      : () => context.push('/perfil/2fa'),
                ),
              ),
              // Só o admin root tem dispositivo confiável (biometria-first).
              if (ehAdminRoot && !kIsWeb) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    key: const Key('seguranca_dispositivo_tile'),
                    leading: const Icon(Icons.fingerprint),
                    title: const Text('Confiar neste dispositivo'),
                    subtitle: Text(
                      _processando
                          ? 'Aguarde…'
                          : _credencial != null
                              ? 'Ativo até ${_formatarExpiracao(_credencial!.expiraEm)} — '
                                  'entre com a biometria, sem senha nem código'
                              : 'Entre no próximo acesso com a biometria, '
                                  'sem senha nem código',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _processando
                        ? null
                        : (_credencial != null ? _revogar : _ativar),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
