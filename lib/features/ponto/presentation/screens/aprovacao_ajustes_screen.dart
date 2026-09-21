import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/registro_ponto_model.dart';
import '../providers/ponto_provider.dart';

class AprovacaoAjustesScreen extends StatefulWidget {
  const AprovacaoAjustesScreen({super.key});

  @override
  State<AprovacaoAjustesScreen> createState() => _AprovacaoAjustesScreenState();
}

class _AprovacaoAjustesScreenState extends State<AprovacaoAjustesScreen> {
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarAjustesPendentes();
  }

  Future<void> _carregarAjustesPendentes() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final provider = context.read<PontoProvider>();
      await provider.listarAjustesPendentes();
      if (mounted) setState(() => _carregando = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = 'Erro ao carregar ajustes pendentes: $e';
        });
      }
    }
  }

  Future<void> _aprovarAjuste(RegistroPontoModel ajuste) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Aprovação'),
        content: Text(
          'Deseja aprovar este ajuste de ponto?\n\n'
          'Colaborador: ${ajuste.colaboradorId}\n'
          'Data/Hora: ${DateFormat('dd/MM/yyyy HH:mm').format(ajuste.dataHoraDispositivo.toLocal())}\n'
          'Tipo: ${ajuste.tipoRegistro}\n'
          'Justificativa: ${ajuste.justificativa}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    try {
      final provider = context.read<PontoProvider>();
      final resultado = await provider.aprovarAjuste(ajuste.idLocal);

      if (!mounted) return;

      if (resultado != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajuste aprovado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarAjustesPendentes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao aprovar ajuste.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aprovar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejeitarAjuste(RegistroPontoModel ajuste) async {
    final motivoController = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeitar Ajuste'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deseja rejeitar este ajuste de ponto?\n\n'
              'Colaborador: ${ajuste.colaboradorId}\n'
              'Data/Hora: ${DateFormat('dd/MM/yyyy HH:mm').format(ajuste.dataHoraDispositivo.toLocal())}\n'
              'Tipo: ${ajuste.tipoRegistro}\n'
              'Justificativa: ${ajuste.justificativa}',
            ),
            const SizedBox(height: 16),
            const Text('Motivo da rejeição (obrigatório):'),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                hintText: 'Digite o motivo da rejeição...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (motivoController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, motivoController.text.trim());
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (motivo == null || motivo.trim().isEmpty || !mounted) return;

    try {
      final provider = context.read<PontoProvider>();
      final resultado = await provider.rejeitarAjuste(ajuste.idLocal, motivo.trim());

      if (!mounted) return;

      if (resultado != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajuste rejeitado.'),
            backgroundColor: Colors.orange,
          ),
        );
        _carregarAjustesPendentes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao rejeitar ajuste.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao rejeitar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pontoProvider = context.watch<PontoProvider>();
    final ajustesPendentes = pontoProvider.espelho
        .where((r) => r.ajusteManual && r.ajusteStatus == 'PENDENTE')
        .toList();

    if (_carregando) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.approval, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('Aprovação de Ajustes'),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_erro != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.approval, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('Aprovação de Ajustes'),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(_erro!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _carregarAjustesPendentes,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.approval, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Aprovação de Ajustes de Ponto'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregarAjustesPendentes,
          ),
        ],
      ),
      body: ajustesPendentes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum ajuste pendente de aprovação',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _carregarAjustesPendentes,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: ajustesPendentes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ajuste = ajustesPendentes[index];
                  return _AjusteCard(
                    ajuste: ajuste,
                    onAprovar: () => _aprovarAjuste(ajuste),
                    onRejeitar: () => _rejeitarAjuste(ajuste),
                  );
                },
              ),
            ),
    );
  }
}

class _AjusteCard extends StatelessWidget {
  final RegistroPontoModel ajuste;
  final VoidCallback onAprovar;
  final VoidCallback onRejeitar;

  const _AjusteCard({
    required this.ajuste,
    required this.onAprovar,
    required this.onRejeitar,
  });

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(ajuste.dataHoraDispositivo.toLocal());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PENDENTE',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'NSR Lógico: #${ajuste.nsrLogico ?? ajuste.nsr ?? '—'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Colaborador: ${ajuste.colaboradorId?.substring(0, 8) ?? '—'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Data/Hora: $dataFormatada'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.touch_app_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Tipo: ${ajuste.tipoRegistro}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.fact_check_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Justificativa:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(ajuste.justificativa ?? '—'),
                    ],
                  ),
                ),
              ],
            ),
            if (ajuste.observacao != null && ajuste.observacao!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Observação:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(ajuste.observacao!),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onRejeitar,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rejeitar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onAprovar,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aprovar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}