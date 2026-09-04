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
  final _telefoneController = TextEditingController();
  final _celularController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();

  final _endLogradouroController = TextEditingController();
  final _endNumeroController = TextEditingController();
  final _endComplementoController = TextEditingController();
  final _endBairroController = TextEditingController();
  final _endCidadeController = TextEditingController();
  final _endUfController = TextEditingController();
  final _endCepController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _cnpjController.dispose();
    _nomeEmpresaController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    _celularController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _senhaController.dispose();
    _endLogradouroController.dispose();
    _endNumeroController.dispose();
    _endComplementoController.dispose();
    _endBairroController.dispose();
    _endCidadeController.dispose();
    _endUfController.dispose();
    _endCepController.dispose();
    super.dispose();
  }

  String? _vazioOuNulo(TextEditingController controller) {
    final texto = controller.text.trim();
    return texto.isNotEmpty ? texto : null;
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
      responsavelTelefone: _vazioOuNulo(_telefoneController),
      responsavelCelular: _vazioOuNulo(_celularController),
      responsavelSenha: _senhaController.text,
      enderecoLogradouro: _vazioOuNulo(_endLogradouroController),
      enderecoNumero: _vazioOuNulo(_endNumeroController),
      enderecoComplemento: _vazioOuNulo(_endComplementoController),
      enderecoBairro: _vazioOuNulo(_endBairroController),
      enderecoCidade: _vazioOuNulo(_endCidadeController),
      enderecoUf: _vazioOuNulo(_endUfController),
      enderecoCep: _vazioOuNulo(_endCepController),
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

                        // Seção: Endereço
                        _buildSectionHeader(context, 'Endereço', Icons.location_on_outlined),
                        const SizedBox(height: 12),

                        _buildEnderecoFields(),
                        const SizedBox(height: 24),

                        // Seção: Dados do Administrador
                        _buildSectionHeader(
                          context,
                          'Dados do Administrador (responsável comercial)',
                          Icons.admin_panel_settings,
                        ),
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

                        TextFormField(
                          controller: _telefoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Telefone',
                            hintText: '(00) 0000-0000',
                            prefixIcon: const Icon(Icons.call_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
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
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'E-mail *',
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
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CpfInputFormatter()],
                          decoration: InputDecoration(
                            labelText: 'CPF (Login) *',
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

  Widget _buildEnderecoFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final emColuna = constraints.maxWidth < 520;

        if (emColuna) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCampoEndereco(
                controller: _endLogradouroController,
                label: 'Logradouro',
                hint: 'Rua, Avenida...',
                icon: Icons.signpost_outlined,
              ),
              const SizedBox(height: 12),
              _buildCampoEndereco(
                controller: _endNumeroController,
                label: 'Número',
                hint: 'Nº',
                icon: Icons.tag,
              ),
              const SizedBox(height: 12),
              _buildCampoEndereco(
                controller: _endComplementoController,
                label: 'Complemento',
                hint: 'Bloco, Apto, Andar...',
                icon: Icons.add_home_outlined,
              ),
              const SizedBox(height: 12),
              _buildCampoEndereco(
                controller: _endBairroController,
                label: 'Bairro',
                hint: 'Bairro',
                icon: Icons.location_city,
              ),
              const SizedBox(height: 12),
              _buildCampoEndereco(
                controller: _endCidadeController,
                label: 'Cidade',
                hint: 'Cidade',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              _buildCampoEndereco(
                controller: _endUfController,
                label: 'UF',
                hint: 'UF',
                icon: Icons.map_outlined,
              ),
              const SizedBox(height: 12),
              _buildCampoEndereco(
                controller: _endCepController,
                label: 'CEP',
                hint: '00000-000',
                icon: Icons.mail_outline,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCampoEndereco(
              controller: _endLogradouroController,
              label: 'Logradouro',
              hint: 'Rua, Avenida...',
              icon: Icons.signpost_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildCampoEndereco(
                    controller: _endNumeroController,
                    label: 'Número',
                    hint: 'Nº',
                    icon: Icons.tag,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: _buildCampoEndereco(
                    controller: _endComplementoController,
                    label: 'Complemento',
                    hint: 'Bloco, Apto, Andar...',
                    icon: Icons.add_home_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCampoEndereco(
              controller: _endBairroController,
              label: 'Bairro',
              hint: 'Bairro',
              icon: Icons.location_city,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildCampoEndereco(
                    controller: _endCidadeController,
                    label: 'Cidade',
                    hint: 'Cidade',
                    icon: Icons.location_on_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildCampoEndereco(
                    controller: _endUfController,
                    label: 'UF',
                    hint: 'UF',
                    icon: Icons.map_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildCampoEndereco(
                    controller: _endCepController,
                    label: 'CEP',
                    hint: '00000-000',
                    icon: Icons.mail_outline,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCampoEndereco({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
          ),
        ),
        const Expanded(child: Divider(indent: 12)),
      ],
    );
  }
}