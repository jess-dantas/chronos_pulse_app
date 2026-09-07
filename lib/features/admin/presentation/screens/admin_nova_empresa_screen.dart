import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empresa_form_fields.dart';
import '../providers/admin_provider.dart';

class AdminNovaEmpresaScreen extends StatefulWidget {
  const AdminNovaEmpresaScreen({super.key});

  @override
  State<AdminNovaEmpresaScreen> createState() => _AdminNovaEmpresaScreenState();
}

class _AdminNovaEmpresaScreenState extends State<AdminNovaEmpresaScreen> {
  final _empresaFormFieldsKey = GlobalKey<EmpresaFormFieldsState>();

  Future<void> _handleCadastro() async {
    if (!(_empresaFormFieldsKey.currentState?.validate() ?? false)) return;

    final fields = _empresaFormFieldsKey.currentState!;
    final adminProvider = context.read<AdminProvider>();
    final sucesso = await adminProvider.cadastrarEmpresa(
      cnpj: fields.cnpj,
      nome: fields.nomeEmpresa,
      responsavelNome: fields.responsavelNome,
      responsavelEmail: fields.responsavelEmail,
      responsavelTelefone: fields.responsavelTelefone,
      responsavelCelular: fields.responsavelCelular,
      enderecoLogradouro: fields.enderecoLogradouro,
      enderecoNumero: fields.enderecoNumero,
      enderecoComplemento: fields.enderecoComplemento,
      enderecoBairro: fields.enderecoBairro,
      enderecoCidade: fields.enderecoCidade,
      enderecoUf: fields.enderecoUf,
      enderecoCep: fields.enderecoCep,
    );

    if (!mounted) return;
    if (sucesso) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(adminProvider.errorMessage ?? 'Erro ao cadastrar empresa.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nova Empresa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.business_center,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cadastrar nova empresa',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Informe os dados da empresa, endereço e contato do responsável. '
                        'Os módulos Ponto e RH serão ativados automaticamente.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      EmpresaFormFields(
                        key: _empresaFormFieldsKey,
                        mostrarCredenciaisResponsavel: false,
                        tituloSecaoContato: 'Contato do Responsável',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: adminProvider.isLoading ? null : _handleCadastro,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAction(context),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: adminProvider.isLoading
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