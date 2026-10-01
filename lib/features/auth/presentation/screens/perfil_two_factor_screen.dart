import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/auth_provider.dart';

/// Gestão do 2FA do colaborador (menu Segurança / perfil): status, ativação
/// via QR Code (TOTP) e desativação com código. Sem recovery codes (decisão).
class PerfilTwoFactorScreen extends StatefulWidget {
  const PerfilTwoFactorScreen({super.key});

  @override
  State<PerfilTwoFactorScreen> createState() => _PerfilTwoFactorScreenState();
}

class _PerfilTwoFactorScreenState extends State<PerfilTwoFactorScreen> {
  final _codigoController = TextEditingController();

  bool _carregando = true;
  bool? _enabled;

  /// Setup pendente (segredo gerado, ainda não confirmado).
  bool _setupIniciado = false;
  String? _secret;
  String? _otpauthUri;
  bool _mostrarChaveManual = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final auth = context.read<AuthProvider>();
    final status = await auth.carregarStatusTwoFactor();
    if (!mounted) return;
    setState(() {
      _enabled = status;
      _carregando = false;
    });
    if (status == null) {
      _mostrarErro(auth.errorMessage ?? 'Erro ao consultar o 2FA.');
    }
  }

  Future<void> _iniciarSetup() async {
    final auth = context.read<AuthProvider>();
    setState(() => _salvando = true);
    final setup = await auth.iniciarSetupTwoFactor();
    if (!mounted) return;
    setState(() => _salvando = false);
    if (setup == null) {
      _mostrarErro(auth.errorMessage ?? 'Erro na configuração do 2FA.');
      return;
    }
    setState(() {
      _setupIniciado = true;
      _secret = setup['secret'];
      _otpauthUri = setup['otpauthUri'];
      _mostrarChaveManual = false;
      _codigoController.clear();
    });
  }

  Future<void> _confirmar() async {
    final codigo = _codigoController.text.trim();
    if (codigo.length != 6 || int.tryParse(codigo) == null) {
      _mostrarErro('O código deve ter 6 dígitos');
      return;
    }
    final auth = context.read<AuthProvider>();
    setState(() => _salvando = true);
    final ok = await auth.confirmarTwoFactor(codigo);
    if (!mounted) return;
    setState(() => _salvando = false);
    if (!ok) {
      _mostrarErro(auth.errorMessage ?? 'Código inválido.');
      return;
    }
    setState(() {
      _enabled = true;
      _setupIniciado = false;
      _secret = null;
      _otpauthUri = null;
      _codigoController.clear();
    });
    _mostrarSucesso('Autenticação em duas etapas ativada.');
  }

  Future<void> _desabilitar() async {
    final codigo = _codigoController.text.trim();
    if (codigo.length != 6 || int.tryParse(codigo) == null) {
      _mostrarErro('O código deve ter 6 dígitos');
      return;
    }
    final auth = context.read<AuthProvider>();
    setState(() => _salvando = true);
    final ok = await auth.desabilitarTwoFactor(codigo);
    if (!mounted) return;
    setState(() => _salvando = false);
    if (!ok) {
      _mostrarErro(auth.errorMessage ?? 'Código inválido.');
      return;
    }
    setState(() {
      _enabled = false;
      _codigoController.clear();
    });
    _mostrarSucesso('Autenticação em duas etapas desativada.');
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
    );
  }

  void _mostrarSucesso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.green),
    );
  }

  Future<void> _copiar(String valor) async {
    await Clipboard.setData(ClipboardData(text: valor));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado para a área de transferência.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isCarregando = auth.isLoading || _salvando;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticação em duas etapas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _carregando
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _enabled == null
                          ? _semStatus()
                          : (_enabled! ? _corpoAtivo(isCarregando, colorScheme) : _corpoInativo(isCarregando, colorScheme)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _semStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.shield_outlined, size: 48),
        const SizedBox(height: 16),
        Text(
          'Não foi possível consultar o status do 2FA.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            setState(() => _carregando = true);
            _carregar();
          },
          child: const Text('Tentar novamente'),
        ),
      ],
    );
  }

  Widget _cabecalho() {
    return Column(
      children: [
        Icon(
          Icons.shield_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'Autenticação em duas etapas',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Depois de ativar, além da senha você precisará de um código de 6 '
          'dígitos do seu aplicativo autenticador (Google Authenticator, '
          'Authy, etc.) para entrar.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _campoCodigo({required VoidCallback onSubmitted, required bool ativo}) {
    return TextFormField(
      key: const Key('perfil_2fa_codigo_field'),
      controller: _codigoController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      autofillHints: const [AutofillHints.oneTimeCode],
      decoration: InputDecoration(
        labelText: ativo
            ? 'Código atual (6 dígitos)'
            : 'Código de 6 dígitos',
        counterText: '',
        prefixIcon: const Icon(Icons.pin_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onFieldSubmitted: (_) => onSubmitted(),
    );
  }

  Widget _corpoInativo(bool isCarregando, ColorScheme colorScheme) {
    if (!_setupIniciado) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalho(),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              key: const Key('perfil_2fa_ativar_button'),
              onPressed: isCarregando ? null : _iniciarSetup,
              icon: const Icon(Icons.shield_outlined),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: isCarregando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Ativar 2FA',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cabecalho(),
        Text(
          'Configure no seu aplicativo autenticador',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '1. Abra o app autenticador (Google Authenticator, Authy, etc.).\n'
          '2. Escaneie o QR Code abaixo.\n'
          '3. Digite o código de 6 dígitos gerado pelo app.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        if (_otpauthUri != null && _otpauthUri!.isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: QrImageView(
                data: _otpauthUri!,
                size: 200,
                backgroundColor: Colors.white,
                key: const ValueKey('qr-perfil-2fa'),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: TextButton.icon(
            onPressed: () =>
                setState(() => _mostrarChaveManual = !_mostrarChaveManual),
            icon: Icon(
              _mostrarChaveManual ? Icons.visibility_off : Icons.visibility,
              size: 16,
            ),
            label: Text(
              _mostrarChaveManual
                  ? 'Ocultar chave manual'
                  : 'Não consegue escanear? Exibir chave manual',
            ),
          ),
        ),
        if (_mostrarChaveManual && _secret != null) ...[
          _CampoCopiavel(
            rotulo: 'Chave manual',
            valor: _secret!,
            onCopiar: _copiar,
          ),
        ],
        const SizedBox(height: 16),
        _campoCodigo(onSubmitted: _confirmar, ativo: false),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            key: const Key('perfil_2fa_confirmar_button'),
            onPressed: isCarregando ? null : _confirmar,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
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
                    'Confirmar ativação',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: isCarregando
              ? null
              : () => setState(() {
                    _setupIniciado = false;
                    _secret = null;
                    _otpauthUri = null;
                    _codigoController.clear();
                  }),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _corpoAtivo(bool isCarregando, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cabecalho(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade400),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ativada neste dispositivo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Para desativar, confirme com um código do seu aplicativo autenticador.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _campoCodigo(onSubmitted: _desabilitar, ativo: true),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('perfil_2fa_desativar_button'),
          onPressed: isCarregando ? null : _desabilitar,
          icon: const Icon(Icons.shield_outlined),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          label: isCarregando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text(
                  'Desativar 2FA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}

class _CampoCopiavel extends StatelessWidget {
  final String rotulo;
  final String valor;
  final Future<void> Function(String) onCopiar;

  const _CampoCopiavel({
    required this.rotulo,
    required this.valor,
    required this.onCopiar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  valor,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copiar',
            onPressed: () => onCopiar(valor),
          ),
        ],
      ),
    );
  }
}
