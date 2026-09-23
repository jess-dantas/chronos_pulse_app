import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../presentation/providers/admin_auth_provider.dart';
import '../widgets/recovery_codes_dialog.dart';

/// Login alternativo do Administrator usando um dos 8 códigos de
/// recuperação (perda do autenticador). Devolve um novo conjunto de
/// códigos após o sucesso.
class AdminRecoverScreen extends StatefulWidget {
  const AdminRecoverScreen({super.key});

  @override
  State<AdminRecoverScreen> createState() => _AdminRecoverScreenState();
}

class _AdminRecoverScreenState extends State<AdminRecoverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _senhaController = TextEditingController();
  final _codigoController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _senhaController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _handleRecuperar() async {
    if (!_formKey.currentState!.validate()) return;

    final adminAuth = context.read<AdminAuthProvider>();
    final ok = await adminAuth.recuperar(
      username: _usernameController.text.trim(),
      senha: _senhaController.text,
      recoveryCode: _codigoController.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      final novos = adminAuth.recoveryCodes;
      if (novos.isNotEmpty) {
        await mostrarCodigosRecuperacaoDialog(
          context,
          codigos: novos,
          titulo: 'Novos códigos de recuperação',
        );
        adminAuth.limparRecoveryCodes();
      }
      if (!mounted) return;
      context.go('/admin/dashboard');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(adminAuth.errorMessage ?? 'Código de recuperação inválido.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminAuth = context.watch<AdminAuthProvider>();
    final isCarregando = adminAuth.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar acesso'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: () {
            context.read<AdminAuthProvider>().voltarParaLogin();
            context.go('/admin/auth/login');
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.password_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Entrar com código de recuperação',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use um dos 8 códigos salvos quando ativou o 2FA. '
                          'Após entrar, um novo conjunto de códigos será gerado.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _usernameController,
                          maxLength: 20,
                          autofillHints: const [AutofillHints.username],
                          decoration: InputDecoration(
                            labelText: 'Usuário',
                            counterText: '',
                            prefixIcon:
                                const Icon(Icons.admin_panel_settings),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Informe o usuário'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _senhaController,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Informe a senha'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _codigoController,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Código de recuperação (XXXXX-XXXXX)',
                            prefixIcon: const Icon(Icons.vpn_key_outlined),
                            helperText: 'Ex.: ABCDE-FGHIJ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            final limpo = (value ?? '')
                                .replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
                            if (limpo.isEmpty) {
                              return 'Informe o código de recuperação';
                            }
                            if (limpo.length != 10) {
                              return 'O código deve ter 10 caracteres';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleRecuperar(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                isCarregando ? null : _handleRecuperar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppTheme.primaryAction(context),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isCarregando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Recuperar acesso',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
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
