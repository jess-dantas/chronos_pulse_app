import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/privacidade_provider.dart';

class PrivacidadeScreen extends StatefulWidget {
  const PrivacidadeScreen({super.key});

  @override
  State<PrivacidadeScreen> createState() => _PrivacidadeScreenState();
}

class _PrivacidadeScreenState extends State<PrivacidadeScreen> {
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PrivacidadeProvider>().carregarPolitica();
    });
  }

  void _mostrarSnack(String msg, {Color? cor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: cor ?? Colors.green.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _registrarConsentimento() async {
    setState(() => _processando = true);
    final erro = await context.read<PrivacidadeProvider>().registrarConsentimento();
    if (!mounted) return;
    setState(() => _processando = false);
    if (erro != null) {
      _mostrarSnack(erro, cor: Colors.red.shade700);
      return;
    }
    _mostrarSnack('Consentimento registrado com sucesso.');
  }

  Future<void> _exportarDados() async {
    setState(() => _processando = true);
    final provider = context.read<PrivacidadeProvider>();
    final erro = await provider.exportarMeusDados();
    if (!mounted) return;
    setState(() => _processando = false);
    if (erro != null) {
      _mostrarSnack(erro, cor: Colors.red.shade700);
      return;
    }
    final json = const JsonEncoder.withIndent('  ').convert(provider.meusDados);
    final destino = await FilePicker.saveFile(
      dialogTitle: 'Exportar meus dados (LGPD)',
      fileName: 'meus_dados_lgpd_${DateTime.now().toIso8601String().substring(0, 10)}.json',
      bytes: Uint8List.fromList(utf8.encode('\uFEFF$json')),
    );
    if (!mounted) return;
    _mostrarSnack(destino != null ? 'Arquivo exportado com sucesso.' : 'Exportação cancelada.');
  }

  Future<void> _apagarDados() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar meus dados?'),
        content: const Text(
          'Seus dados pessoais serão anonimizados (LGPD art. 18, VI) e sua conta será '
          'desativada. Esta ação não pode ser desfeita.\n\nRegistros operacionais e a '
          'trilha de auditoria são mantidos apenas por exigência legal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Anonimizar e desativar'),
          ),
        ],
      ),
    );
    if (confirma != true || !mounted) return;

    setState(() => _processando = true);
    final erro = await context.read<PrivacidadeProvider>().apagarMeusDados();
    if (!mounted) return;
    setState(() => _processando = false);
    if (erro != null) {
      _mostrarSnack(erro, cor: Colors.red.shade700);
      return;
    }
    if (!mounted) return;
    _mostrarSnack('Dados anonimizados. Encerrando a sessão...', cor: Colors.orange.shade700);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrivacidadeProvider>();
    final politica = provider.politica;
    final versao = politica?['versao']?.toString() ?? '—';
    final dataPublicacao = politica?['dataPublicacao']?.toString() ?? '—';
    final texto = politica?['texto']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Privacidade & LGPD'),
          ],
        ),
        centerTitle: true,
      ),
      body: provider.isLoading && politica == null
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null && politica == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.read<PrivacidadeProvider>().carregarPolitica(),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<PrivacidadeProvider>().carregarPolitica(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _CardSection(
                        icon: Icons.description_outlined,
                        title: 'Política de Privacidade',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Versão $versao · Publicada em $dataPublicacao',
                              style: TextStyle(
                                color: Colors.deepPurple.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              texto.isEmpty
                                  ? 'Política indisponível offline.'
                                  : texto,
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CardSection(
                        icon: Icons.fact_check_outlined,
                        title: 'Consentimento',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ao registrar o consentimento, você concorda de forma '
                              'expressa com o tratamento dos dados descritos na política. '
                              'O consentimento pode ser revogado a qualquer momento.',
                              style: TextStyle(fontSize: 13, height: 1.5),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _processando ? null : _registrarConsentimento,
                              icon: _processando
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text('Registrar consentimento (v$versao)'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CardSection(
                        icon: Icons.file_download_outlined,
                        title: 'Meus Dados (Portabilidade)',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Exporte em formato aberto (JSON) uma cópia legível de '
                              'máquina com os dados pessoais que a plataforma mantém '
                              'sobre você (LGPD art. 18, V).',
                              style: TextStyle(fontSize: 13, height: 1.5),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _processando ? null : _exportarDados,
                              icon: const Icon(Icons.download),
                              label: const Text('Exportar meus dados'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CardSection(
                        icon: Icons.delete_forever_outlined,
                        title: 'Encerrar tratamento (Anonimização)',
                        iconColor: Colors.red,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Solicite a eliminação dos seus dados pessoais (LGPD art. 18, '
                              'VI): nome, e-mails, celular e foto são removidos e a conta '
                              'desativada. Registros exigidos por lei (ex.: ponto eletrônico '
                              'e auditoria) são retidos pelo prazo legal.',
                              style: TextStyle(fontSize: 13, height: 1.5),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _processando ? null : _apagarDados,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade700),
                              ),
                              icon: const Icon(Icons.privacy_tip_outlined),
                              label: const Text('Apagar meus dados'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Encarregado (DPO): privacidade@chronos-pulse.com.br',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _CardSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Widget child;

  const _CardSection({
    required this.icon,
    required this.title,
    required this.child,
    this.iconColor = Colors.deepPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}