import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Diálogo único de exibição dos 8 códigos de recuperação do Administrator.
/// Os códigos são mostrados apenas uma vez (retorno do confirm 2FA ou do
/// login por recuperação) e devem ser salvos pelo usuário.
Future<void> mostrarCodigosRecuperacaoDialog(
  BuildContext context, {
  required List<String> codigos,
  String titulo = 'Códigos de recuperação',
  VoidCallback? onFechar,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _CodigosRecuperacaoDialog(
      titulo: titulo,
      codigos: codigos,
      onFechar: onFechar,
    ),
  );
}

class _CodigosRecuperacaoDialog extends StatelessWidget {
  final String titulo;
  final List<String> codigos;
  final VoidCallback? onFechar;

  const _CodigosRecuperacaoDialog({
    required this.titulo,
    required this.codigos,
    this.onFechar,
  });

  Future<void> _copiarTodos(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: codigos.join('\n')));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Códigos copiados para a área de transferência.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Salve estes códigos em local seguro. Cada código pode ser '
              'usado uma única vez e eles NÃO serão exibidos novamente.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final codigo in codigos)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        codigo,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _copiarTodos(context),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar todos'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onFechar?.call();
          },
          child: const Text('Já salvei'),
        ),
      ],
    );
  }
}
