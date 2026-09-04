import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class AdminEmpresasScreen extends StatefulWidget {
  const AdminEmpresasScreen({super.key});

  @override
  State<AdminEmpresasScreen> createState() => _AdminEmpresasScreenState();
}

class _AdminEmpresasScreenState extends State<AdminEmpresasScreen> {
  final DioClient _dioClient = DioClient();
  List<Map<String, dynamic>> _empresas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregarEmpresas();
  }

  Future<void> _carregarEmpresas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _dioClient.dio.get('/empresas');
      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          _empresas = (response.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['message'] ?? 'Erro ao carregar empresas');
    } catch (e) {
      setState(() => _error = 'Erro ao carregar empresas');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Empresas (Tenants)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Atualizar',
                      onPressed: _carregarEmpresas,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_error!)),
                        ],
                      ),
                    ),
                  )
                else if (_empresas.isEmpty)
                  Card(
                    elevation: 0,
                    color: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.business_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'Nenhuma empresa cadastrada.',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _empresas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final e = _empresas[index];
                      final ativo = e['ativo'] == true;
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: const Icon(Icons.business, color: Colors.blue),
                          ),
                          title: Text(
                            e['nome'] ?? 'Sem nome',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'CNPJ: ${e['cnpj'] ?? '—'}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              if (e['responsavelNome'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Responsável: ${e['responsavelNome']}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                              if (e['responsavelEmail'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Email: ${e['responsavelEmail']}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (ativo ? Colors.green : Colors.red).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (ativo ? Colors.green : Colors.red).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              ativo ? 'ATIVO' : 'INATIVO',
                              style: TextStyle(
                                color: (ativo ? Colors.green : Colors.red).shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
