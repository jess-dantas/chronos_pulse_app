import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/security/biometria_preferences.dart';
import '../../../admin/presentation/providers/admin_auth_provider.dart';

/// Tela "Segurança" (`/perfil/seguranca`), compartilhada por colaborador e
/// admin root.
///
/// Concentra o bloqueio biométrico ao abrir o app (toggle, padrão ativado —
/// vale também para o gate admin) e a entrada para a gestão da autenticação
/// em duas etapas: o colaborador vai para `/perfil/2fa` e o admin root para
/// `/admin/seguranca`.
class PerfilSegurancaScreen extends StatelessWidget {
  const PerfilSegurancaScreen({super.key});

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
            ],
          ),
        ),
      ),
    );
  }
}
