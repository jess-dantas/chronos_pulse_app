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

  /// Confirma a desativação do 2FA com um código TOTP do dispositivo atual.
  Future<void> _abrirDialogoDesativar() async {
    final adminAuth = context.read<AdminAuthProvider>();

    final codigo = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _DialogDesativarDoisFatores(),
    );

    if (codigo == null || !mounted) return;

    final sucesso = await adminAuth.desabilitarTwoFactor(codigo);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Verificação em duas etapas desativada.'
              : (adminAuth.errorMessage ?? 'Código inválido.'),
        ),
        backgroundColor: sucesso ? Colors.green : Colors.redAccent,
      ),
    );
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
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed:
                                  isCarregando ? null : _abrirDialogoDesativar,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.power_settings_new,
                                  size: 20),
                              label: const Text(
                                'Desativar 2FA',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Perdeu ou trocou o celular? Desative com um '
                              'código do aplicativo autenticador e ative '
                              'novamente no novo aparelho.',
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

/// Diálogo de confirmação da desativação do 2FA: pede um código TOTP de 6
/// dígitos e devolve via `Navigator.pop`. O [TextEditingController] vive no
/// State do diálogo (nunca é disposed enquanto o route anima).
class _DialogDesativarDoisFatores extends StatefulWidget {
  const _DialogDesativarDoisFatores();

  @override
  State<_DialogDesativarDoisFatores> createState() =>
      _DialogDesativarDoisFatoresState();
}

class _DialogDesativarDoisFatoresState extends State<_DialogDesativarDoisFatores> {
  final _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _confirmar() {
    final codigo = _controlador.text.trim();
    if (codigo.length == 6) Navigator.of(context).pop(codigo);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Desativar 2FA'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informe um código de 6 dígitos do seu aplicativo '
            'autenticador para confirmar a desativação.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controlador,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            autofillHints: const [AutofillHints.oneTimeCode],
            onSubmitted: (_) => _confirmar(),
            decoration: InputDecoration(
              labelText: 'Código (6 dígitos)',
              counterText: '',
              prefixIcon: const Icon(Icons.pin_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Desativar'),
        ),
      ],
    );
  }
}
