import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../presentation/providers/admin_auth_provider.dart';

/// Passo 2 do wizard de setup forçado do 2FA: exibe os 8 códigos de
/// recuperação (mostrados uma única vez) e só libera a conclusão após o
/// Administrator copiar/baixar e confirmar que salvou.
class AdminRecoveryCodesScreen extends StatefulWidget {
  const AdminRecoveryCodesScreen({super.key});

  @override
  State<AdminRecoveryCodesScreen> createState() =>
      _AdminRecoveryCodesScreenState();
}

class _AdminRecoveryCodesScreenState extends State<AdminRecoveryCodesScreen> {
  bool _liSalvei = false;

  Future<void> _copiarTodos(List<String> codigos) async {
    await Clipboard.setData(ClipboardData(text: codigos.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Códigos copiados para a área de transferência.'),
      ),
    );
  }

  Future<void> _baixarTxt(List<String> codigos) async {
    try {
      final bytes = utf8.encode(
        'Chronos Pulse - Códigos de recuperação (2FA)\n'
        'Salve este arquivo em local seguro. Cada código é de uso único.\n\n'
        '${codigos.join('\n')}\n',
      );
      await FilePicker.saveFile(
        dialogTitle: 'Salvar códigos de recuperação',
        fileName: 'chronos-pulse-recovery-codes.txt',
        bytes: Uint8List.fromList(bytes),
      );
    } catch (_) {
      // Plataformas sem suporte a saveFile (ex.: Android/iOS): sugere copiar.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Download não suportado nesta plataforma. Use "Copiar todos".',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _liSalvei = true);
  }

  void _concluir() {
    final adminAuth = context.read<AdminAuthProvider>();
    final autenticado = adminAuth.isAuthenticated;
    adminAuth.limparRecoveryCodes();
    context.go(autenticado ? '/admin/dashboard' : '/admin/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final adminAuth = context.watch<AdminAuthProvider>();
    final codigos = adminAuth.recoveryCodes;
    final colorScheme = Theme.of(context).colorScheme;

    if (codigos.isEmpty) {
      // Sem códigos (refresh/recarga da rota): não há o que exibir.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(adminAuth.isAuthenticated
            ? '/admin/dashboard'
            : '/admin/auth/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salve seus códigos de recuperação'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.password, size: 48, color: colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Passo 2 — Códigos de recuperação',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estes 8 códigos serão exibidos apenas uma vez. '
                        'Eles permitem acessar a conta caso perca o celular. '
                        'Salve-os em local seguro antes de concluir.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final codigo in codigos)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade400),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => _copiarTodos(codigos),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copiar todos'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _baixarTxt(codigos),
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Baixar .txt'),
                          ),
                        ],
                      ),
                      CheckboxListTile(
                        value: _liSalvei,
                        onChanged: (v) => setState(() => _liSalvei = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Li e salvei meus códigos de recuperação',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _liSalvei ? _concluir : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Concluir',
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
    );
  }
}
