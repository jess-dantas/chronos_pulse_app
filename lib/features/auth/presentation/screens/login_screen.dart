import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/hardware/hardware_service.dart';
import '../../../../core/network/conexao_service.dart';
import '../../../../core/security/device_token_store.dart';
import '../../../../core/security/login_biometrico_store.dart';
import '../../../../core/telemetry/telemetry_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/cpf_input_formatter.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  /// Injeções opcionais (testes): diagnóstico de conexão, store do vínculo,
  /// hardware biométrico e credencial do login por biometria.
  final ConexaoService? conexao;
  final DeviceTokenStore? store;
  final HardwareService? hardware;
  final LoginBiometricoStore? loginBiometrico;

  const LoginScreen({
    super.key,
    this.conexao,
    this.store,
    this.hardware,
    this.loginBiometrico,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _obscurePassword = true;

  /// Modo "bater ponto sem login" (mobile only): só aparece quando o
  /// aparelho tem vínculo de dispositivo ativo (7 dias).
  bool _vinculoAtivo = false;

  /// Login por biometria (mobile only): credencial guardada + biometria do
  /// aparelho disponível. Controla o botão e o auto-prompt da tela.
  bool _biometricoPronto = false;
  bool _biometriaEmAndamento = false;

  late final ConexaoService _conexao = widget.conexao ?? ConexaoService();
  late final DeviceTokenStore _store =
      widget.store ?? DeviceTokenStore.instancia;
  late final HardwareService _hw = widget.hardware ?? HardwareService();
  late final LoginBiometricoStore _loginBiometrico =
      widget.loginBiometrico ?? LoginBiometricoStore.instancia;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _store.vinculoAtivo().then((ativo) {
        if (mounted) setState(() => _vinculoAtivo = ativo);
      });
      // Sem conexão: avisa com o toast "Sem conexão!" (o login não vai
      // funcionar). O redirecionamento para a contingência acontece na
      // home de ponto — aqui o usuário escolheu logar, não o contrário.
      _verificarConexao();
      _verificarLoginBiometrico();
    }
  }

  /// Biometria-first: com credencial guardada e biometria do aparelho
  /// disponível, oferece o botão e dispara o prompt automaticamente. Sem
  /// credencial/biometria nada muda — a tela segue o formulário normal.
  Future<void> _verificarLoginBiometrico() async {
    try {
      final temCredencial = await _loginBiometrico.possuiCredencial();
      if (!temCredencial || !mounted) return;
      final disponivel = await _hw.biometriaDisponivel();
      if (!disponivel || !mounted) return;
      setState(() => _biometricoPronto = true);
      await _entrarComBiometria();
    } catch (_) {
      // Falha de leitura/biometria: segue o formulário de senha.
    }
  }

  Future<void> _entrarComBiometria() async {
    if (_biometriaEmAndamento || !mounted) return;
    setState(() => _biometriaEmAndamento = true);

    bool autenticado;
    try {
      autenticado = await _hw
          .autenticarBiometria()
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      autenticado = false;
    }

    // Cancelado/erro: volta para o formulário sem tocar em credencial nem
    // vínculo (a tentativa pode ser repetida pelo botão).
    if (!autenticado || !mounted) {
      if (mounted) setState(() => _biometriaEmAndamento = false);
      return;
    }

    final cpf = await _loginBiometrico.lerCpf();
    final senha = await _loginBiometrico.lerSenha();
    if (cpf == null || senha == null || !mounted) {
      if (mounted) setState(() => _biometriaEmAndamento = false);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final sucesso = await authProvider.login(cpf, senha);
    if (!mounted) return;
    setState(() => _biometriaEmAndamento = false);

    if (!sucesso) {
      // Credencial velha (senha trocada) ou offline: mantém a credencial —
      // o próximo login por senha a corrige (ou a rede volta e o replay
      // funciona). O usuário cai no formulário normal.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              authProvider.errorMessage ?? 'Erro ao realizar login.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    await _aposLogin(cpf);
  }

  Future<void> _verificarConexao() async {
    final diagnostico = await _conexao.diagnosticar(store: _store);
    if (!mounted || diagnostico == DiagnosticoConexao.online) return;
    ConexaoService.avisarSemConexao(context);
    context.telemetria?.registrar(
      tipo: TipoEventoTelemetria.conexaoOffline,
      modulo: 'AUTH',
      mensagem: 'Sem conexão na tela de login',
      detalhe: diagnostico.name,
    );
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final cpfLimpo = CpfInputFormatter.clean(_cpfController.text);
    final sucesso = await authProvider.login(
      cpfLimpo,
      _senhaController.text,
    );

    // Após o login, o AppRouter redireciona automaticamente o usuário
    // autenticado para o painel (ou área administrativa).
    if (!sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Erro ao realizar login.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (sucesso && mounted) await _aposLogin(cpfLimpo);
  }

  /// Pós-login comum (formulário e biometria): se o CPF logado difere do
  /// dono do vínculo de dispositivo ativo, o vínculo antigo é invalidado
  /// (outro dono no aparelho → novo primeiro acesso na contingência) e o
  /// roteador segue para o 2FA quando exigido.
  Future<void> _aposLogin(String cpfDigitado) async {
    await _sincronizarVinculoComCpf(cpfDigitado);
    if (!mounted) return;

    // 2FA-first: o backend parou na etapa 1 (requiresTwoFactor) — pede o
    // código TOTP/OTP por e-mail na tela dedicada.
    if (context.read<AuthProvider>().requiresTwoFactor) {
      context.push('/login/2fa');
    }
  }

  Future<void> _sincronizarVinculoComCpf(String cpfDigitado) async {
    if (kIsWeb) return;
    try {
      final vinculo = await _store.lerAtivo();
      // Vínculo sem cpf gravado (antigo) também é invalidado: dono
      // desconhecido não pode sobreviver a um login de outro CPF.
      if (vinculo != null && vinculo.cpf != cpfDigitado) {
        await _store.limpar();
        if (mounted) setState(() => _vinculoAtivo = false);
      }
    } catch (_) {
      // Best-effort: falha do armazenamento não bloqueia o login.
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isCarregando = authProvider.isLoading;

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
                        // Logo / Header
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 80,
                              fit: BoxFit.contain,
                              semanticLabel: 'Logo Chronos Pulse',
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.fingerprint,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chronos Pulse',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 24),

                        // Campo CPF
                        TextFormField(
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            CpfInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: 'CPF',
                            hintText: '000.000.000-00',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o CPF';
                            }
                            if (!CpfInputFormatter.isValidLength(value)) {
                              return 'O CPF deve conter 11 dígitos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo Senha
                        TextFormField(
                          controller: _senhaController,
                          obscureText: _obscurePassword,
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

                        // Botão Entrar
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isCarregando ? null : _handleLogin,
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
                                    'Logar',
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
                            key: const Key('login_biometrico_button'),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _biometriaEmAndamento
                                ? null
                                : _entrarComBiometria,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_vinculoAtivo) ...[
                          OutlinedButton.icon(
                            key: const Key('login_modo_dispositivo_button'),
                            icon: const Icon(Icons.fingerprint, size: 20),
                            label: const Text(
                              'Bater ponto sem login',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => context.push('/ponto/dispositivo'),
                          ),
                          const SizedBox(height: 8),
                        ],
                        TextButton(
                          onPressed: () {
                            context.go('/recuperar-senha');
                          },
                          child: const Text('Esqueci minha senha'),
                        ),
                        TextButton(
                          key: const Key('login_cadastro_empresa_button'),
                          onPressed: () {
                            context.go('/cadastro');
                          },
                          child: const Text('Não tem acesso? Cadastre sua empresa'),
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
