import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../presentation/providers/admin_auth_provider.dart';
import '../widgets/two_factor_setup_card.dart';

/// Setup forçado do 2FA — fluxo do first-run wizard (bootstrap) e do
/// login quando chronos.admin.two-factor-required=true e o 2FA ainda está
/// desabilitado. Passo 1: QR Code + TOTP. Passo 2: tela dedicada com os
/// 8 códigos de recuperação (só conclui após copiar/baixar).
class AdminSetup2FAScreen extends StatelessWidget {
  const AdminSetup2FAScreen({super.key});

  void _aoConfirmar(BuildContext context) {
    final adminAuth = context.read<AdminAuthProvider>();
    if (adminAuth.recoveryCodes.isNotEmpty) {
      context.go('/admin/auth/codigos-recuperacao');
    } else if (adminAuth.isAuthenticated) {
      context.go('/admin/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminAuth = context.watch<AdminAuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ativação obrigatória do 2FA'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.security, size: 48, color: colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Configure a autenticação em duas etapas',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A proteção 2FA é obrigatória para o Administrator. '
                        'Cadastre a conta no seu autenticador e confirme o '
                        'código para concluir o acesso. Em seguida, salve os '
                        '8 códigos de recuperação exibidos.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 20),
                      TwoFactorSetupCard(
                        onConfirmado: () async => _aoConfirmar(context),
                      ),
                      if (adminAuth.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          adminAuth.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: adminAuth.isAuthenticated
                            ? null
                            : () {
                                adminAuth.voltarParaLogin();
                                context.go('/admin/auth/login');
                              },
                        child: const Text('Usar outra conta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
