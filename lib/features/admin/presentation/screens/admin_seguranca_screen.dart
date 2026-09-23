import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_auth_provider.dart';
import '../widgets/recovery_codes_dialog.dart';
import '../widgets/two_factor_setup_card.dart';

class AdminSegurancaScreen extends StatefulWidget {
  const AdminSegurancaScreen({super.key});

  @override
  State<AdminSegurancaScreen> createState() => _AdminSegurancaScreenState();
}

class _AdminSegurancaScreenState extends State<AdminSegurancaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminAuthProvider>().carregarStatusTwoFactor();
    });
  }

  Future<void> _aoConfirmar() async {
    final adminAuth = context.read<AdminAuthProvider>();
    final codigos = adminAuth.recoveryCodes;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verificação em duas etapas ativada.'),
        backgroundColor: Colors.green,
      ),
    );

    if (codigos.isNotEmpty) {
      await mostrarCodigosRecuperacaoDialog(
        context,
        codigos: codigos,
      );
      adminAuth.limparRecoveryCodes();
    }

    if (!mounted) return;
    await adminAuth.carregarStatusTwoFactor();
  }

  @override
  Widget build(BuildContext context) {
    final adminAuth = context.watch<AdminAuthProvider>();
    final isCarregando = adminAuth.isLoading;
    final enabled = adminAuth.twoFactorEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Segurança',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.security,
                            size: 44, color: colorScheme.primary),
                        const SizedBox(height: 12),
                        Text(
                          'Verificação em duas etapas (2FA)',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (enabled == null && isCarregando)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                enabled == true
                                    ? Icons.check_circle
                                    : Icons.cancel_outlined,
                                color:
                                    enabled == true ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                enabled == true ? 'Ativa' : 'Desativada',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            enabled == true
                                ? 'Cada login exige um código do seu aplicativo autenticador.'
                                : 'Proteja sua conta com um código de 6 dígitos a cada login.',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                          ),
                          if (enabled == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              'A desativação não está disponível para o '
                              'Administrator da plataforma.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade500),
                            ),
                          ],
                        ],
                        if (adminAuth.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            adminAuth.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (enabled == false) ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: TwoFactorSetupCard(
                        onConfirmado: _aoConfirmar,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
