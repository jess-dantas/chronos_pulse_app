import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../providers/auth_provider.dart';

/// Etapa 2 do login 2FA-first: código TOTP de 6 dígitos (padrão) ou OTP de
/// 8 dígitos enviado por e-mail. Só existe enquanto o provider está em
/// `requiresTwoFactor` (tempToken de 5 minutos).
class TwoFactorLoginScreen extends StatefulWidget {
  const TwoFactorLoginScreen({super.key});

  @override
  State<TwoFactorLoginScreen> createState() => _TwoFactorLoginScreenState();
}

class _TwoFactorLoginScreenState extends State<TwoFactorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();

  /// `true` quando o usuário escolheu receber o código por e-mail (8 dígitos)
  /// em vez do app autenticador (6 dígitos).
  bool _porEmail = false;
  bool _enviandoCodigo = false;

  @override
  void initState() {
    super.initState();
    // Chegou sem a etapa 1 (refresh/route direto): volta para o login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (!auth.requiresTwoFactor) context.go('/login');
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigoPorEmail() async {
    final auth = context.read<AuthProvider>();
    setState(() => _enviandoCodigo = true);
    final erro = await auth.enviarCodigoEmailTwoFactor();
    if (!mounted) return;
    setState(() => _enviandoCodigo = false);
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() {
      _porEmail = true;
      _codigoController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código enviado para o seu e-mail.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _verificar() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final sucesso = _porEmail
        ? await auth.verificarCodigoEmailTwoFactor(_codigoController.text)
        : await auth.verificarTwoFactor(_codigoController.text);
    if (!mounted) return;
    if (!sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Código inválido.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    // Sucesso: o AppRouter redireciona para o painel (sessão autenticada).
  }

  void _voltar() {
    context.read<AuthProvider>().cancelarTwoFactor();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isCarregando = auth.isLoading || _enviandoCodigo;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: isCarregando ? null : _voltar,
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: themeProvider.isDarkMode ? 'Tema Claro' : 'Tema Escuro',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                          Icons.security,
                          size: 56,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Verificação em duas etapas',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _porEmail
                              ? 'Digite o código de 8 dígitos enviado para o seu e-mail.'
                              : 'Digite o código de 6 dígitos do seu aplicativo autenticador.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          key: const Key('two_factor_codigo_field'),
                          controller: _codigoController,
                          keyboardType: TextInputType.number,
                          maxLength: _porEmail ? 8 : 6,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: _porEmail
                                ? 'Código enviado por e-mail'
                                : 'Código do aplicativo',
                            counterText: '',
                            prefixIcon: const Icon(Icons.pin_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            final texto = (value ?? '').trim();
                            final esperado = _porEmail ? 8 : 6;
                            if (texto.isEmpty) {
                              return 'Informe o código';
                            }
                            if (texto.length != esperado ||
                                int.tryParse(texto) == null) {
                              return _porEmail
                                  ? 'O código deve conter 8 dígitos'
                                  : 'O código deve conter 6 dígitos';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _verificar(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            key: const Key('two_factor_verificar_button'),
                            onPressed: isCarregando ? null : _verificar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryAction(context),
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
                                    'Verificar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!_porEmail)
                          TextButton(
                            key: const Key('two_factor_por_email_button'),
                            onPressed:
                                isCarregando ? null : _enviarCodigoPorEmail,
                            child: _enviandoCodigo
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Receber código por e-mail'),
                          )
                        else
                          TextButton(
                            key: const Key('two_factor_reenviar_button'),
                            onPressed:
                                isCarregando ? null : _enviarCodigoPorEmail,
                            child: const Text('Reenviar código'),
                          ),
                        TextButton(
                          onPressed: isCarregando ? null : _voltar,
                          child: const Text('Voltar'),
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
