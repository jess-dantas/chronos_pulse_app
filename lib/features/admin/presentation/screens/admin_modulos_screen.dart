import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class AdminModulosScreen extends StatefulWidget {
  const AdminModulosScreen({super.key});

  @override
  State<AdminModulosScreen> createState() => _AdminModulosScreenState();
}

class _AdminModulosScreenState extends State<AdminModulosScreen> {
  String? _tenantIdSelecionado;
  Set<String> _selecionados = {};
  bool _carregandoModulos = false;
  bool _salvando = false;
  String? _mensagem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().carregarEmpresas();
      context.read<AdminProvider>().carregarCatalogoModulos();
    });
  }

  Future<void> _carregarModulosEmpresa(String tenantId) async {
    final provider = context.read<AdminProvider>();
    setState(() {
      _carregandoModulos = true;
      _mensagem = null;
    });
    try {
      final modulos = await provider.listarModulosEmpresa(tenantId);
      if (!mounted) return;
      setState(() {
        _selecionados = modulos.toSet();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagem = 'Erro ao carregar módulos: ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      if (mounted) {
        setState(() => _carregandoModulos = false);
      }
    }
  }

  Future<void> _salvar() async {
    final provider = context.read<AdminProvider>();
    setState(() {
      _salvando = true;
      _mensagem = null;
    });
    final ok = await provider.atualizarModulosEmpresa(_tenantIdSelecionado!, _selecionados.toList());
    if (!mounted) return;
    setState(() {
      _salvando = false;
      _mensagem = ok
          ? 'Módulos atualizados com sucesso.'
          : 'Erro ao salvar: ${provider.errorMessage ?? 'tente novamente.'}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final empresas = provider.empresas;
    final catalogo = provider.modulosCatalogo;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Módulos da Plataforma',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: Colors.deepPurple.withOpacity(0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.deepPurple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ative ou desative módulos por empresa (CNPJ). '
                            'Os módulos core (Ponto, RH e Estoque) são ativados automaticamente no cadastro de novas empresas.',
                            style: TextStyle(color: Colors.grey[800], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: _tenantIdSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Empresa',
                    prefixIcon: Icon(Icons.business_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: empresas.map((e) {
                    final nome = e['nome'] ?? 'Sem nome';
                    final cnpj = e['cnpj'];
                    return DropdownMenuItem<String?>(
                      value: e['id']?.toString(),
                      child: Text(cnpj != null ? '$nome ($cnpj)' : nome),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _tenantIdSelecionado = value;
                      _selecionados = {};
                      _mensagem = null;
                    });
                    _carregarModulosEmpresa(value);
                  },
                ),
                const SizedBox(height: 24),
                if (_mensagem != null)
                  Card(
                    color: (_mensagem!.contains('Erro') ? Colors.red : Colors.green).withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_mensagem!),
                    ),
                  ),
                if (_mensagem != null) const SizedBox(height: 16),
                if (_tenantIdSelecionado != null) ...[
                  Text(
                    'Módulos contratados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_carregandoModulos)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (catalogo.isEmpty && provider.errorMessage != null)
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(provider.errorMessage!),
                      ),
                    )
                  else
                    ...catalogo.map((modulo) => _ModuloTile(
                          codigo: modulo['codigo']?.toString() ?? '',
                          nome: modulo['nome']?.toString() ?? '',
                          descricao: modulo['descricao']?.toString(),
                          ativo: modulo['ativo'] == true,
                          selecionado: _selecionados.contains(modulo['codigo']?.toString()),
                          onChanged: (sel) {
                            setState(() {
                              if (sel) {
                                _selecionados.add(modulo['codigo']?.toString() ?? '');
                              } else {
                                _selecionados.remove(modulo['codigo']?.toString());
                              }
                              _mensagem = null;
                            });
                          },
                        )),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _salvando || _carregandoModulos ? null : _salvar,
                    icon: _salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_salvando ? 'Salvando...' : 'Salvar Módulos'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuloTile extends StatelessWidget {
  final String codigo;
  final String nome;
  final String? descricao;
  final bool ativo;
  final bool selecionado;
  final ValueChanged<bool> onChanged;

  const _ModuloTile({
    required this.codigo,
    required this.nome,
    this.descricao,
    required this.ativo,
    required this.selecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selecionado ? Colors.deepPurple.withOpacity(0.5) : Colors.grey.shade300,
        ),
      ),
      child: CheckboxListTile(
        value: selecionado,
        onChanged: ativo ? (v) => onChanged(v ?? false) : null,
        activeColor: Colors.deepPurple,
        secondary: Icon(
          Icons.widgets_outlined,
          color: ativo ? Colors.deepPurple : Colors.grey,
        ),
        title: Text(
          '$nome ${ativo ? '' : '(indisponível)'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: descricao != null && descricao!.isNotEmpty
            ? Text(descricao!, style: TextStyle(color: Colors.grey[600], fontSize: 12))
            : null,
      ),
    );
  }
}