import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../providers/admin_auth_provider.dart';

class AdminAuthScreen extends StatelessWidget {
  const AdminAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location == '/admin/auth/login') {
      return const AdminLoginScreen();
    } else if (location == '/admin/auth/logout') {
      return const AdminLogoutScreen();
    }

    return const SizedBox.shrink();
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _senhaController = TextEditingController();
  final _codigoController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mostra o link de primeiro acesso apenas se a tabela de
      // administrators estiver vazia (bootstrapAvailable).
      context.read<AdminAuthProvider>().carregarBootstrapStatus();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _senhaController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AdminAuthProvider>();
    final sucesso = await authProvider.login(
      _usernameController.text.trim(),
      _senhaController.text,
    );

    if (!mounted) return;

    if (sucesso) {
      if (authProvider.requiresTwoFactor) {
        if (authProvider.setupRequired) {
          // 2FA obrigatório e ainda desabilitado: wizard de setup.
          context.go('/admin/auth/setup-2fa');
          return;
        }
        // Aguarda o código do Google Authenticator.
        return;
      }
      context.go('/admin/dashboard');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? 'Erro ao realizar login.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _handleVerificarCodigo() async {
    if (!_codigoFormKey.currentState!.validate()) return;

    final authProvider = context.read<AdminAuthProvider>();
    final sucesso =
        await authProvider.verifyTwoFactor(_codigoController.text.trim());

    if (!mounted) return;

    if (sucesso) {
      context.go('/admin/dashboard');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? 'Código 2FA inválido.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _voltarLogin() {
    context.read<AdminAuthProvider>().voltarParaLogin();
    _codigoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AdminAuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isCarregando = authProvider.isLoading;
    final aguardandoCodigo = authProvider.requiresTwoFactor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: () => context.go('/'),
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
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 80,
                              fit: BoxFit.contain,
                              semanticLabel: 'Logo Chronos Pulse',
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.admin_panel_settings,
                                  size: 40,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Login Administrator',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          aguardandoCodigo
                              ? 'Verificação em duas etapas'
                              : 'Área restrita para administradores da plataforma',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 24),
                        if (aguardandoCodigo) ...[
                          Form(
                            key: _codigoFormKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _codigoController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  autofillHints: const [AutofillHints.oneTimeCode],
                                  decoration: InputDecoration(
                                    labelText: 'Código (6 dígitos)',
                                    counterText: '',
                                    helperText:
                                        'Informe o código do Google Authenticator.',
                                    prefixIcon:
                                        const Icon(Icons.pin_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (value) {
                                    final codigo = value?.trim() ?? '';
                                    if (codigo.isEmpty) {
                                      return 'Informe o código de verificação';
                                    }
                                    if (codigo.length != 6 ||
                                        int.tryParse(codigo) == null) {
                                      return 'O código deve ter 6 dígitos';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _handleVerificarCodigo(),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: isCarregando
                                        ? null
                                        : _handleVerificarCodigo,
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
                                            'Verificar código',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: isCarregando ? null : _voltarLogin,
                                  child: const Text('Usar outra conta'),
                                ),
                                TextButton(
                                  onPressed: isCarregando
                                      ? null
                                      : () => context.go(
                                          '/admin/auth/recover'),
                                  child: const Text(
                                    'Perdeu os códigos de recuperação?',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
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
                          validator: (value) {
                            final username = value?.trim() ?? '';
                            if (username.isEmpty) {
                              return 'Informe o usuário';
                            }
                            if (username.length > 20) {
                              return 'O usuário deve ter no máximo 20 caracteres';
                            }
                            return null;
                          },
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
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a senha';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isCarregando ? null : _handleLogin,
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
                                    'Entrar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (authProvider.bootstrapAvailable == true)
                          TextButton.icon(
                            onPressed: () =>
                                context.go('/admin/auth/bootstrap'),
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: const Text('Primeiro acesso? Provisionar '
                                'Administrator'),
                          ),
                        TextButton(
                          onPressed: () => context.go('/admin/auth/recover'),
                          child: const Text(
                            'Entrar com código de recuperação',
                          ),
                        ),
                        ],
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

class AdminLogoutScreen extends StatelessWidget {
  const AdminLogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminAuthProvider>().logout();
      context.go('/');
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Saindo...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
