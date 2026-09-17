import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/repositories/lead_repository.dart';
import '../providers/leads_provider.dart';

class AdminLeadsScreen extends StatefulWidget {
  const AdminLeadsScreen({super.key});

  @override
  State<AdminLeadsScreen> createState() => _AdminLeadsScreenState();
}

class _AdminLeadsScreenState extends State<AdminLeadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadsProvider>().carregarLeads();
    });
  }

  Future<void> _recarregar() async {
    await context.read<LeadsProvider>().carregarLeads();
    if (mounted) {
      final provider = context.read<LeadsProvider>();
      if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${provider.errorMessage}')),
        );
      }
    }
  }

  Future<void> _mover(LeadEmpresaModel lead, String novoStatus) async {
    final provider = context.read<LeadsProvider>();
    final ok = await provider.mover(lead.id, novoStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ok
              ? '${lead.razaoSocial}: ${_rotulo(novoStatus)}.'
              : 'Erro ao atualizar: ${provider.errorMessage ?? 'tente novamente.'}'),
          backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
        ),
      );
  }

  String _rotulo(String status) {
    switch (status) {
      case 'NOVO':
        return 'Novo';
      case 'AGENDADO':
        return 'Agendado';
      case 'REUNIAO':
        return 'Reunião';
      case 'CONTRATADO':
        return 'Contratado';
      case 'DESCARTADO':
        return 'Descartado';
      default:
        return status;
    }
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'NOVO':
        return Colors.blue;
      case 'AGENDADO':
        return Colors.orange;
      case 'REUNIAO':
        return Colors.deepPurple;
      case 'CONTRATADO':
        return Colors.green;
      case 'DESCARTADO':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeadsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.isDark(context) ? null : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Acompanhamento de Leads',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _recarregar,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _recarregar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ResumoFunil(provider: provider),
                  if (provider.leads.isEmpty)
                    const _FunilVazio()
                  else
                    for (final status in LeadsProvider.ordemFunil)
                      ..._secaoStatus(provider, status),
                ],
              ),
            ),
    );
  }

  List<Widget> _secaoStatus(LeadsProvider provider, String status) {
    final itens = provider.leadsDoStatus(status);
    if (itens.isEmpty) return const [];

    return [
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _corStatus(status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_rotulo(status).toUpperCase()} (${itens.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _corStatus(status),
              ),
            ),
            const Spacer(),
            Text(
              'Total: ${provider.leads.length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      ...itens.map((lead) => _LeadCard(
            lead: lead,
            onSelecionarStatus: (novo) => _mover(lead, novo),
          )),
    ];
  }
}

class _ResumoFunil extends StatelessWidget {
  final LeadsProvider provider;

  const _ResumoFunil({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.lilasSurface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: AppTheme.onLilasSurface(context)),
                const SizedBox(width: 8),
                Text(
                  'Funil de vendas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onLilasSurface(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in LeadsProvider.ordemFunil)
                  _ChipStatus(
                    status: status,
                    total: provider.totalDoStatus(status),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipStatus extends StatelessWidget {
  final String status;
  final int total;

  const _ChipStatus({required this.status, required this.total});

  @override
  Widget build(BuildContext context) {
    const rotulos = {
      'NOVO': 'Novo',
      'AGENDADO': 'Agendado',
      'REUNIAO': 'Reunião',
      'CONTRATADO': 'Contratado',
      'DESCARTADO': 'Descartado',
    };
    return Chip(
      label: Text('${rotulos[status]} · $total'),
      backgroundColor: Colors.white.withValues(alpha: 0.7),
      side: BorderSide(color: _cor(status)),
      labelStyle: TextStyle(fontSize: 12, color: _cor(status)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Color _cor(String status) {
    switch (status) {
      case 'NOVO':
        return Colors.blue;
      case 'AGENDADO':
        return Colors.orange;
      case 'REUNIAO':
        return Colors.deepPurple;
      case 'CONTRATADO':
        return Colors.green;
      case 'DESCARTADO':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}

class _LeadCard extends StatelessWidget {
  final LeadEmpresaModel lead;
  final void Function(String novoStatus) onSelecionarStatus;

  const _LeadCard({required this.lead, required this.onSelecionarStatus});

  @override
  Widget build(BuildContext context) {
    final dataFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    lead.razaoSocial,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                _statusBadge(lead.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatarCnpj(lead.cnpj),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            _linhaInfo(Icons.person_outline, lead.contatoNome),
            if (lead.contatoEmail.isNotEmpty)
              _linhaInfo(Icons.email_outlined, lead.contatoEmail),
            if (lead.contatoCelular?.isNotEmpty == true)
              _linhaInfo(Icons.phone_outlined, lead.contatoCelular!),
            if (lead.cidadeUf.isNotEmpty)
              _linhaInfo(Icons.location_on_outlined, lead.cidadeUf),
            _linhaInfo(Icons.schedule, 'Recebido em ${dataFormat.format(lead.criadoEm)}'),
            if (lead.observacao?.isNotEmpty == true)
              _linhaInfo(Icons.notes, lead.observacao!, maxLines: 4),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: lead.status,
                  icon: const Icon(Icons.arrow_drop_down),
                  isDense: true,
                  items: [
                    for (final status in LeadsProvider.ordemFunil)
                      DropdownMenuItem(
                        value: status,
                        child: Text(_rotuloItem(status),
                            style: const TextStyle(fontSize: 13)),
                      ),
                  ],
                  onChanged: (novo) {
                    if (novo != null && novo != lead.status) {
                      onSelecionarStatus(novo);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final cor = switch (status) {
      'NOVO' => Colors.blue,
      'AGENDADO' => Colors.orange,
      'REUNIAO' => Colors.deepPurple,
      'CONTRATADO' => Colors.green,
      'DESCARTADO' => Colors.grey,
      _ => Colors.blueGrey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _rotuloItem(status),
        style: TextStyle(
          color: cor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _rotuloItem(String status) {
    switch (status) {
      case 'NOVO':
        return 'Novo';
      case 'AGENDADO':
        return 'Agendado';
      case 'REUNIAO':
        return 'Reunião';
      case 'CONTRATADO':
        return 'Contratado';
      case 'DESCARTADO':
        return 'Descartado';
      default:
        return status;
    }
  }

  String _formatarCnpj(String cnpj) {
    final somenteDigitos = cnpj.replaceAll(RegExp(r'\D'), '');
    if (somenteDigitos.length != 14) return cnpj;
    return '${somenteDigitos.substring(0, 2)}.${somenteDigitos.substring(2, 5)}.'
        '${somenteDigitos.substring(5, 8)}/${somenteDigitos.substring(8, 12)}-'
        '${somenteDigitos.substring(12)}';
  }

  Widget _linhaInfo(IconData icon, String texto, {int maxLines = 2}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FunilVazio extends StatelessWidget {
  const _FunilVazio();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.mail_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text('Nenhum lead cadastrado ainda.'),
          const SizedBox(height: 4),
          Text(
            'Os cadastros feitos no onboarding comercial aparecem aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}