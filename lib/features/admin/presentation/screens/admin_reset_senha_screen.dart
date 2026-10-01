import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/admin_auth_provider.dart';

/// Reset de senha do Administrator por OTP de 8 dígitos enviado ao e-mail
/// cadastrado — cobre perda de 2FA/recovery codes sem exigir sessão.
/// Passo 1: envia o código; passo 2: valida e redefine a nova senha.
class AdminResetSenhaScreen extends StatefulWidget {
  const AdminResetSenhaScreen({super.key});

  @override
  State<AdminResetSenhaScreen> createState() => _AdminResetSenhaScreenState();
}

class _AdminResetSenhaScreenState extends State<AdminResetSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _codigoController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _etapa2 = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _codigoController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final adminAuth = context.read<AdminAuthProvider>();
    final ok = await adminAuth.resetSenhaEnviar(_usernameController.text);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _etapa2 = true;
        _codigoController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código enviado para o e-mail cadastrado.'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(adminAuth.errorMessage ?? 'Erro ao enviar o código.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _reenviarCodigo() async {
    final adminAuth = context.read<AdminAuthProvider>();
    final ok = await adminAuth.resetSenhaEnviar(_usernameController.text);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      ok
          ? const SnackBar(
              content: Text('Código reenviado para o e-mail cadastrado.'),
              backgroundColor: Colors.green,
            )
          : SnackBar(
              content:
                  Text(adminAuth.errorMessage ?? 'Erro ao enviar o código.'),
              backgroundColor: Colors.redAccent,
            ),
    );
  }

  Future<void> _redefinirSenha() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final adminAuth = context.read<AdminAuthProvider>();
    final ok = await adminAuth.resetSenhaVerificar(
      username: _usernameController.text,
      codigo: _codigoController.text.trim(),
      novaSenha: _novaSenhaController.text,
    );
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha redefinida com sucesso. Faça login com a '
              'nova senha.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/admin/auth/login');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(adminAuth.errorMessage ?? 'Erro ao redefinir a senha.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _voltarLogin() {
    context.read<AdminAuthProvider>().voltarParaLogin();
    context.go('/admin/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final adminAuth = context.watch<AdminAuthProvider>();
    final isCarregando = adminAuth.isLoading;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar senha'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: _voltarLogin,
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
                          Icons.lock_reset_outlined,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _etapa2
                              ? 'Digite o código recebido'
                              : 'Recuperação de senha',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _etapa2
                              ? 'Enviamos um código de 8 dígitos para o '
                                  'e-mail cadastrado. Ele expira em 15 minutos.'
                              : 'Informe seu usuário para receber um código '
                                  'de recuperação por e-mail. Não é preciso '
                                  'ter o 2FA em mãos.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _usernameController,
                          enabled: !_etapa2,
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
                        if (_etapa2) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _codigoController,
                            keyboardType: TextInputType.number,
                            maxLength: 8,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                            ),
                            autofillHints: const [AutofillHints.oneTimeCode],
                            decoration: InputDecoration(
                              labelText: 'Código de recuperação',
                              counterText: '',
                              prefixIcon: const Icon(Icons.password),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              final codigo = value?.trim() ?? '';
                              if (codigo.isEmpty) {
                                return 'Informe o código recebido por e-mail';
                              }
                              if (codigo.length != 8 ||
                                  int.tryParse(codigo) == null) {
                                return 'O código deve ter 8 dígitos';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _novaSenhaController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Nova senha',
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe a nova senha';
                              }
                              if (value.length < 8) {
                                return 'A senha deve ter no mínimo 8 caracteres';
                              }
                              if (value.length > 100) {
                                return 'A senha deve ter no máximo 100 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmarSenhaController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Confirmar nova senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirme a nova senha';
                              }
                              if (value != _novaSenhaController.text) {
                                return 'As senhas não coincidem';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isCarregando
                                ? null
                                : (_etapa2 ? _redefinirSenha : _enviarCodigo),
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
                                : Text(
                                    _etapa2 ? 'Redefinir senha' : 'Enviar código',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        if (_etapa2) ...[
                          TextButton(
                            onPressed:
                                isCarregando ? null : _reenviarCodigo,
                            child: const Text('Reenviar código'),
                          ),
                        ],
                        TextButton(
                          onPressed: isCarregando ? null : _voltarLogin,
                          child: const Text('Voltar ao login'),
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
