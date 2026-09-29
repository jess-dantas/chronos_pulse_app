import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/fila_ajuste_model.dart';
import '../providers/ponto_provider.dart';

/// Fila consolidada do gestor RH: pendentes do tenant com nome do colaborador
/// e as marcações do próprio dia (contexto do espelho) para aprovar/recusar
/// sem sair da tela.
class AprovacaoAjustesScreen extends StatefulWidget {
  const AprovacaoAjustesScreen({super.key});

  @override
  State<AprovacaoAjustesScreen> createState() => _AprovacaoAjustesScreenState();
}

class _AprovacaoAjustesScreenState extends State<AprovacaoAjustesScreen> {
  bool _carregando = true;
  String? _erro;
  List<FilaAjusteModel> _fila = const [];

  @override
  void initState() {
    super.initState();
    _carregarFila();
  }

  Future<void> _carregarFila() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final provider = context.read<PontoProvider>();
      final fila = await provider.listarFilaAjustes();
      if (mounted) {
        setState(() {
          _fila = fila;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = 'Erro ao carregar fila de ajustes: $e';
        });
      }
    }
  }

  Future<void> _aprovarAjuste(FilaAjusteModel ajuste) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Aprovação'),
        content: Text(_detalhesAjuste(ajuste)),
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
      final resultado = await provider.aprovarAjuste(ajuste.registroId);

      if (!mounted) return;

      if (resultado != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajuste aprovado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _carregarFila();
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

  Future<void> _rejeitarAjuste(FilaAjusteModel ajuste) async {
    final motivoController = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeitar Ajuste'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_detalhesAjuste(ajuste)),
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
      final resultado = await provider.rejeitarAjuste(ajuste.registroId, motivo.trim());

      if (!mounted) return;

      if (resultado != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajuste rejeitado.'),
            backgroundColor: Colors.orange,
          ),
        );
        _carregarFila();
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

  String _detalhesAjuste(FilaAjusteModel ajuste) {
    return 'Deseja continuar com esta ação?\n\n'
        'Colaborador: ${ajuste.nomeExibicao}\n'
        'Data/Hora: ${DateFormat('dd/MM/yyyy HH:mm').format(ajuste.dataHoraDispositivo.toLocal())}\n'
        'Tipo: ${ajuste.tipoRegistro}\n'
        'Justificativa: ${ajuste.justificativa ?? '—'}';
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
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
          onPressed: _carregarFila,
        ),
      ],
    );

    if (_carregando) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_erro != null) {
      return Scaffold(
        appBar: appBar,
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
                  onPressed: _carregarFila,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: _fila.isEmpty
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
              onRefresh: _carregarFila,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _fila.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ajuste = _fila[index];
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
  final FilaAjusteModel ajuste;
  final VoidCallback onAprovar;
  final VoidCallback onRejeitar;

  const _AjusteCard({
    required this.ajuste,
    required this.onAprovar,
    required this.onRejeitar,
  });

  @override
  Widget build(BuildContext context) {
    final dataFormatada =
        DateFormat('dd/MM/yyyy HH:mm').format(ajuste.dataHoraDispositivo.toLocal());

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
                const Icon(Icons.person, size: 18, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ajuste.nomeExibicao,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Data/Hora do ajuste: $dataFormatada'),
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
            if (ajuste.marcacoesDoDia.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Marcações do dia:', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ajuste.marcacoesDoDia.map((m) {
                  final hora = DateFormat('HH:mm').format(m.dataHora.toLocal());
                  return Chip(
                    avatar: Icon(
                      m.ajuste ? Icons.edit_calendar : Icons.punch_clock,
                      size: 16,
                      color: m.ajuste ? Colors.orange : Colors.deepPurple,
                    ),
                    label: Text(
                      '$hora ${m.tipoRegistro}${m.ajuste ? ' (ajuste)' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: m.ajuste
                        ? Colors.orange.withValues(alpha: 0.12)
                        : Colors.deepPurple.withValues(alpha: 0.08),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
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
