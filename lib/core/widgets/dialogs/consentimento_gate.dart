import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/privacidade/presentation/providers/privacidade_provider.dart';

/// Guard do Termo de Ciência (LGPD) — usado pelo MainShell.
///
/// Ao montar, consulta `GET /privacidade/consentimento/status`; se o aceite da
/// versão vigente estiver pendente (primeiro acesso ou política atualizada),
/// abre um modal bloqueante (`barrierDismissible: false`) que só é fechado
/// por "Ciente e de acordo" (POST consentimento) ou "Sair" (logout).
class ConsentimentoGate extends StatefulWidget {
  final Widget child;

  const ConsentimentoGate({super.key, required this.child});

  @override
  State<ConsentimentoGate> createState() => _ConsentimentoGateState();
}

class _ConsentimentoGateState extends State<ConsentimentoGate> {
  bool _verificado = false;
  bool _modalAberto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificar());
  }

  Future<void> _verificar() async {
    if (!mounted || _verificado) return;
    _verificado = true;

    final provider = context.read<PrivacidadeProvider>();
    await provider.carregarStatusConsentimento();
    if (!mounted || !provider.consentimentoPendente) return;

    _abrirModal();
  }

  void _abrirModal() {
    if (_modalAberto || !mounted) return;
    _modalAberto = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _TermoCienciaDialog(),
    ).whenComplete(() => _modalAberto = false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _TermoCienciaDialog extends StatefulWidget {
  const _TermoCienciaDialog();

  @override
  State<_TermoCienciaDialog> createState() => _TermoCienciaDialogState();
}

class _TermoCienciaDialogState extends State<_TermoCienciaDialog> {
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<PrivacidadeProvider>();
      if (provider.politica == null) provider.carregarPolitica();
    });
  }

  Future<void> _aceitar() async {
    final provider = context.read<PrivacidadeProvider>();
    setState(() => _processando = true);
    if (provider.politica == null) await provider.carregarPolitica();
    final erro = await provider.registrarConsentimento();
    if (!mounted) return;
    setState(() => _processando = false);
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.redAccent),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  void _sair() {
    Navigator.of(context).pop();
    if (!mounted) return;
    context.read<AuthProvider>().logout();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrivacidadeProvider>();
    final politica = provider.politica;
    final texto = politica?['texto']?.toString() ?? '';
    final versao = politica?['versao']?.toString() ?? '—';
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.gavel_outlined, color: Colors.deepPurple),
          SizedBox(width: 8),
          Expanded(child: Text('Termo de Ciência de Privacidade')),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Antes de registrar ponto, leia o termo abaixo. Ele informa '
                'como seus dados de jornada são tratados (LGPD e CLT / '
                'Portaria MTP 671/2021).',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              if (provider.isLoading && politica == null)
                const Center(child: CircularProgressIndicator())
              else if (texto.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    texto,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                )
              else
                Text(
                  provider.errorMessage ??
                      'A política será carregada em instantes…',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _processando ? null : _sair,
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.error,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          child: const Text('Sair'),
        ),
        FilledButton(
          onPressed: _processando || politica == null ? null : _aceitar,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          child: _processando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Ciente e de acordo (v$versao)'),
        ),
      ],
    );
  }
}
