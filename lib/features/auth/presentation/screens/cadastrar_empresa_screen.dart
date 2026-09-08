import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/empresa_form_fields.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CadastrarEmpresaScreen extends StatefulWidget {
  const CadastrarEmpresaScreen({super.key});

  @override
  State<CadastrarEmpresaScreen> createState() => _CadastrarEmpresaScreenState();
}

class _CadastrarEmpresaScreenState extends State<CadastrarEmpresaScreen> {
  final _empresaFormFieldsKey = GlobalKey<EmpresaFormFieldsState>();

  Future<void> _handleCadastro() async {
    if (!(_empresaFormFieldsKey.currentState?.validate() ?? false)) return;

    final fields = _empresaFormFieldsKey.currentState!;
    final authProvider = context.read<AuthProvider>();
    final sucesso = await authProvider.cadastrarEmpresa(
      cnpj: fields.cnpj,
      nomeEmpresa: fields.nomeEmpresa,
      responsavelNome: fields.responsavelNome,
      responsavelCpf: fields.responsavelCpf ?? '',
      responsavelEmail: fields.responsavelEmail ?? '',
      responsavelTelefone: fields.responsavelTelefone,
      responsavelCelular: fields.responsavelCelular,
      responsavelSenha: fields.responsavelSenha ?? '',
      enderecoLogradouro: fields.enderecoLogradouro,
      enderecoNumero: fields.enderecoNumero,
      enderecoComplemento: fields.enderecoComplemento,
      enderecoBairro: fields.enderecoBairro,
      enderecoCidade: fields.enderecoCidade,
      enderecoUf: fields.enderecoUf,
      enderecoCep: fields.enderecoCep,
    );

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empresa cadastrada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (!sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Erro ao cadastrar empresa.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isCarregando = authProvider.isLoading;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Cadastro de Empresa'),
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
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 70,
                            fit: BoxFit.contain,
                            semanticLabel: 'Logo Chronos Pulse',
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fingerprint,
                                size: 36,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Criar sua empresa no Chronos Pulse',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preencha os dados da empresa e do administrador responsável.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      EmpresaFormFields(
                        key: _empresaFormFieldsKey,
                        mostrarCredenciaisResponsavel: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isCarregando ? null : _handleCadastro,
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
                                  'Cadastrar Empresa',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Já tem conta? Voltar ao Login'),
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