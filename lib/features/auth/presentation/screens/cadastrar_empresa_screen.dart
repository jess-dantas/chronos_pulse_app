import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/cnpj_validator.dart';
import '../../../../core/utils/cpf_input_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CadastrarEmpresaScreen extends StatefulWidget {
  const CadastrarEmpresaScreen({super.key});

  @override
  State<CadastrarEmpresaScreen> createState() => _CadastrarEmpresaScreenState();
}

class _CadastrarEmpresaScreenState extends State<CadastrarEmpresaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cnpjController = TextEditingController();
  final _nomeEmpresaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _cnpjController.dispose();
    _nomeEmpresaController.dispose();
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _handleCadastro() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final sucesso = await authProvider.cadastrarEmpresa(
      cnpj: _cnpjController.text,
      nomeEmpresa: _nomeEmpresaController.text.trim(),
      responsavelNome: _nomeController.text.trim(),
      responsavelCpf: _cpfController.text,
      responsavelEmail: _emailController.text.trim(),
      responsavelCelular: _celularController.text.trim().isNotEmpty
          ? _celularController.text.trim()
          : null,
      responsavelSenha: _senhaController.text,
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
                              height: 70,
                              fit: BoxFit.contain,
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
                        const SizedBox(height: 24),

                        // Seção: Dados da Empresa
                        _buildSectionHeader(context, 'Dados da Empresa', Icons.business),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _cnpjController,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'CNPJ *',
                            hintText: '00.000.000/0001-00',
                            prefixIcon: const Icon(Icons.assignment_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o CNPJ';
                            }
                            if (CnpjValidator.normalizar(value).length != 14) {
                              return 'O CNPJ deve conter 14 caracteres';
                            }
                            if (!CnpjValidator.isValid(value)) {
                              return 'CNPJ inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _nomeEmpresaController,
                          decoration: InputDecoration(
                            labelText: 'Razão Social / Nome da Empresa *',
                            prefixIcon: const Icon(Icons.business_center),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o nome da empresa'
                              : null,
                        ),
                        const SizedBox(height: 24),

                        // Seção: Dados do Administrador
                        _buildSectionHeader(context, 'Dados do Administrador', Icons.admin_panel_settings),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _nomeController,
                          decoration: InputDecoration(
                            labelText: 'Nome Completo *',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o nome completo'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: TextFormField(
                                controller: _cpfController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [CpfInputFormatter()],
                                decoration: InputDecoration(
                                  labelText: 'CPF *',
                                  hintText: '000.000.000-00',
                                  prefixIcon: const Icon(Icons.credit_card),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Informe o CPF';
                                  }
                                  if (!CpfInputFormatter.isValidLength(value)) {
                                    return 'CPF deve ter 11 dígitos';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _celularController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Celular',
                                  hintText: '(00) 00000-0000',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'E-mail Corporativo *',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe o e-mail';
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Informe um e-mail válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _senhaController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Senha *',
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
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe a senha';
                            }
                            if (v.length < 6) {
                              return 'A senha deve ter no mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isCarregando ? null : _handleCadastro,
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
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
        ),
        const Expanded(child: Divider(indent: 12)),
      ],
    );
  }
}
