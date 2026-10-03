import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/hardware/hardware_service.dart';
import '../../../../core/security/admin_device_token_store.dart';
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
  /// Injeções opcionais (testes): hardware biométrico e credencial do
  /// dispositivo confiável.
  final HardwareService? hardware;
  final AdminDeviceTokenStore? deviceStore;

  const AdminLoginScreen({super.key, this.hardware, this.deviceStore});

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

  /// 2FA-first: o campo de senha fica escondido até o usuário pedir.
  bool _mostrarSenha = false;

  /// Alternativa ao TOTP: OTP de 8 dígitos enviado por e-mail.
  bool _modoEmail = false;

  late final HardwareService _hw = widget.hardware ?? HardwareService();
  late final AdminDeviceTokenStore _deviceStore =
      widget.deviceStore ?? AdminDeviceTokenStore.instancia;

  /// Biometria-first (mobile only): dispositivo confiável vinculado +
  /// biometria do aparelho disponível. Controla o botão e o auto-prompt.
  bool _biometricoPronto = false;
  bool _biometriaEmAndamento = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mostra o link de primeiro acesso apenas se a tabela de
      // administrators estiver vazia (bootstrapAvailable).
      context.read<AdminAuthProvider>().carregarBootstrapStatus();
      if (!kIsWeb) _verificarDispositivoConfiavel();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _senhaController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  /// Biometria-first: com dispositivo confiável vinculado e biometria do
  /// aparelho disponível, oferece o botão e dispara o prompt automaticamente.
  /// Sem credencial/biometria nada muda — a tela segue o formulário normal.
  Future<void> _verificarDispositivoConfiavel() async {
    try {
      final credencial = await _deviceStore.lerAtiva();
      if (credencial == null || !mounted) return;
      final disponivel = await _hw.biometriaDisponivel();
      if (!disponivel || !mounted) return;
      setState(() {
        _biometricoPronto = true;
        _usernameController.text = credencial.username;
      });
      await _entrarComBiometria();
    } catch (_) {
      // Falha de leitura/biometria: segue o formulário normal.
    }
  }

  Future<void> _entrarComBiometria() async {
    if (_biometriaEmAndamento || !mounted) return;

    final credencial = await _deviceStore.lerAtiva();
    if (credencial == null) {
      if (mounted) setState(() => _biometricoPronto = false);
      return;
    }
    setState(() => _biometriaEmAndamento = true);

    bool autenticado;
    try {
      autenticado = await _hw
          .autenticarBiometria(motivo: 'Entre como ${credencial.username}')
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      autenticado = false;
    }

    // Cancelado/erro: volta para o formulário sem tocar na credencial
    // (a tentativa pode ser repetida pelo botão).
    if (!autenticado || !mounted) {
      if (mounted) setState(() => _biometriaEmAndamento = false);
      return;
    }

    final authProvider = context.read<AdminAuthProvider>();
    final sucesso = await authProvider.login(
      credencial.username,
      deviceToken: credencial.token,
    );
    if (!mounted) return;
    setState(() => _biometriaEmAndamento = false);

    // deviceToken recusado no servidor (expirado/revogado): o backend caiu
    // no fluxo normal — 2FA ou exigência de senha. A credencial está vencida,
    // é limpa e o usuário segue pelo método manual.
    if (authProvider.requiresTwoFactor) {
      await _deviceStore.limpar();
      if (!mounted) return;
      setState(() => _biometricoPronto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Dispositivo não reconhecido. Informe o código de verificação.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (!sucesso) {
      final erro = authProvider.errorMessage ?? 'Erro ao realizar login.';
      if (erro.contains('Senha é obrigatória')) {
        await _deviceStore.limpar();
        if (!mounted) return;
        setState(() {
          _biometricoPronto = false;
          _mostrarSenha = true;
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.redAccent),
      );
      return;
    }

    context.go('/admin/dashboard');
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AdminAuthProvider>();
    final sucesso = await authProvider.login(
      _usernameController.text.trim(),
      senha: _mostrarSenha ? _senhaController.text : null,
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

    final erro = authProvider.errorMessage ?? 'Erro ao realizar login.';
    if (erro.contains('Senha é obrigatória') && !_mostrarSenha) {
      // Conta sem 2FA: o backend exige senha — revela o campo na hora.
      setState(() => _mostrarSenha = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Informe a senha para continuar.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(erro),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _handleVerificarCodigo() async {
    if (!_codigoFormKey.currentState!.validate()) return;

    final authProvider = context.read<AdminAuthProvider>();
    final codigo = _codigoController.text.trim();
    final sucesso = _modoEmail
        ? await authProvider.verifyEmailCode(codigo)
        : await authProvider.verifyTwoFactor(codigo);

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

  /// Envia OTP de 8 dígitos por e-mail e troca o passo 2 para o modo e-mail.
  Future<void> _handleEnviarCodigoEmail() async {
    final authProvider = context.read<AdminAuthProvider>();
    final ok = await authProvider.enviarCodigoEmail();

    if (!mounted) return;

    if (ok) {
      setState(() {
        _modoEmail = true;
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
        content: Text(
          authProvider.errorMessage ?? 'Erro ao enviar o código por e-mail.',
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _usarGoogleAuthenticator() {
    setState(() {
      _modoEmail = false;
      _codigoController.clear();
    });
  }

  /// "Usar senha": volta ao passo 1 já com o campo de senha visível.
  void _usarSenha() {
    context.read<AdminAuthProvider>().voltarParaLogin();
    setState(() {
      _mostrarSenha = true;
      _modoEmail = false;
      _codigoController.clear();
    });
  }

  void _voltarLogin() {
    context.read<AdminAuthProvider>().voltarParaLogin();
    _codigoController.clear();
    setState(() {
      _mostrarSenha = false;
      _modoEmail = false;
    });
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
                                  maxLength: _modoEmail ? 8 : 6,
                                  autofillHints: const [AutofillHints.oneTimeCode],
                                  decoration: InputDecoration(
                                    labelText: _modoEmail
                                        ? 'Código enviado por e-mail '
                                            '(8 dígitos)'
                                        : 'Código (6 dígitos)',
                                    counterText: '',
                                    helperText: _modoEmail
                                        ? 'Verifique a caixa de entrada '
                                            'do e-mail cadastrado.'
                                        : 'Informe o código do Google '
                                            'Authenticator.',
                                    prefixIcon:
                                        const Icon(Icons.pin_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (value) {
                                    final codigo = value?.trim() ?? '';
                                    final tamanhoEsperado =
                                        _modoEmail ? 8 : 6;
                                    if (codigo.isEmpty) {
                                      return 'Informe o código de verificação';
                                    }
                                    if (codigo.length != tamanhoEsperado ||
                                        int.tryParse(codigo) == null) {
                                      return _modoEmail
                                          ? 'O código deve ter 8 dígitos'
                                          : 'O código deve ter 6 dígitos';
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
                                if (!_modoEmail)
                                  TextButton(
                                    onPressed: isCarregando
                                        ? null
                                        : _handleEnviarCodigoEmail,
                                    child: const Text(
                                      'Receber código por e-mail',
                                    ),
                                  ),
                                if (_modoEmail)
                                  TextButton(
                                    onPressed: isCarregando
                                        ? null
                                        : _usarGoogleAuthenticator,
                                    child: const Text(
                                      'Usar Google Authenticator',
                                    ),
                                  ),
                                TextButton(
                                  onPressed: isCarregando ? null : _usarSenha,
                                  child: const Text('Usar senha'),
                                ),
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
                        if (_mostrarSenha) ...[
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
                        ],
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
                        if (_biometricoPronto) ...[
                          OutlinedButton.icon(
                            key: const Key('admin_biometrico_button'),
                            icon: _biometriaEmAndamento
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.fingerprint, size: 20),
                            label: Text(
                              _biometriaEmAndamento
                                  ? 'Confirme sua biometria'
                                  : 'Entrar com biometria',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _biometriaEmAndamento || isCarregando
                                ? null
                                : _entrarComBiometria,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (!_mostrarSenha)
                          TextButton(
                            onPressed: isCarregando
                                ? null
                                : () => setState(() => _mostrarSenha = true),
                            child: const Text('Usar senha'),
                          ),
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
                        TextButton(
                          onPressed: isCarregando
                              ? null
                              : () =>
                                  context.go('/admin/auth/reset-senha'),
                          child: const Text('Esqueci minha senha'),
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
