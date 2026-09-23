import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/admin_auth_provider.dart';

/// Card compartilhado de configuração do 2FA (QR/chave manual + código).
/// Usado pela tela de segurança (ativação opcional em dev) e pelo
/// wizard de setup forçado (bootstrap / chronos.admin.two-factor-required).
class TwoFactorSetupCard extends StatefulWidget {
  final Future<void> Function()? onConfirmado;

  const TwoFactorSetupCard({super.key, this.onConfirmado});

  @override
  State<TwoFactorSetupCard> createState() => _TwoFactorSetupCardState();
}

class _TwoFactorSetupCardState extends State<TwoFactorSetupCard> {
  final _codigoController = TextEditingController();
  bool _setupIniciado = false;
  bool _mostrarChaveManual = false;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    final ok = await context.read<AdminAuthProvider>().iniciarSetupTwoFactor();
    if (!mounted) return;
    if (ok) {
      setState(() => _setupIniciado = true);
    } else {
      _mostrarErro();
    }
  }

  Future<void> _confirmar() async {
    final codigo = _codigoController.text.trim();
    if (codigo.length != 6 || int.tryParse(codigo) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O código deve ter 6 dígitos'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final adminAuth = context.read<AdminAuthProvider>();
    final ok = await adminAuth.confirmarTwoFactor(codigo);
    if (!mounted) return;

    if (ok) {
      _codigoController.clear();
      setState(() {
        _setupIniciado = false;
        _mostrarChaveManual = false;
      });
      await widget.onConfirmado?.call();
    } else {
      _mostrarErro();
    }
  }

  void _mostrarErro() {
    final mensagem =
        context.read<AdminAuthProvider>().errorMessage ?? 'Erro na ativação.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
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
    final adminAuth = context.watch<AdminAuthProvider>();
    final isCarregando = adminAuth.isLoading;
    final colorScheme = Theme.of(context).colorScheme;

    if (!_setupIniciado) {
      return SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          onPressed: isCarregando ? null : _iniciar,
          icon: const Icon(Icons.shield_outlined),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          label: const Text(
            'Ativar 2FA',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final otpauthUri = adminAuth.twoFactorOtpauthUrl;
    final segredo = adminAuth.twoFactorSecret;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        if (otpauthUri != null && otpauthUri.isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: QrImageView(
                data: otpauthUri,
                size: 200,
                backgroundColor: Colors.white,
                key: const ValueKey('qr-setup-2fa'),
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
        if (_mostrarChaveManual && segredo != null) ...[
          _CampoCopiavel(
            rotulo: 'Chave manual',
            valor: segredo,
            onCopiar: _copiar,
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _codigoController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          decoration: InputDecoration(
            labelText: 'Código (6 dígitos)',
            counterText: '',
            prefixIcon: const Icon(Icons.pin_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onFieldSubmitted: (_) => _confirmar(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
