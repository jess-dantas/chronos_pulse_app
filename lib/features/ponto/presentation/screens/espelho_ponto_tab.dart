import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/registro_ponto_model.dart';
import '../dialogs/ajuste_ponto_dialog.dart';
import '../providers/ponto_provider.dart';
import '../services/pdf_espelho_service.dart';

class EspelhoPontoTab extends StatefulWidget {
  const EspelhoPontoTab({super.key});

  @override
  State<EspelhoPontoTab> createState() => _EspelhoPontoTabState();
}

class _EspelhoPontoTabState extends State<EspelhoPontoTab> {
  final Map<String, String> _nomesTipos = {
    'ENTRADA': 'Entrada',
    'INTERVALO': 'Intervalo',
    'RETORNO': 'Retorno',
    'SAIDA': 'Saída',
  };

  Color _obterCorTipo(String tipo) {
    switch (tipo) {
      case 'ENTRADA':
        return Colors.green;
      case 'INTERVALO':
        return Colors.orange;
      case 'RETORNO':
        return Colors.blue;
      case 'SAIDA':
        return Colors.redAccent;
      default:
        return Colors.deepPurple;
    }
  }

  void _abrirDialogAjuste([DateTime? dataInicial]) {
    final pontoProvider = context.read<PontoProvider>();

    // Combina espelho (mes selecionado) com o histórico de hoje (registros locais
    // recentes que ainda podem não constar no espelho remoto), sem duplicar.
    final chaves = <String>{};
    final registros = <RegistroPontoModel>[];
    for (final r in [...pontoProvider.espelho, ...pontoProvider.historico]) {
      final local = r.dataHoraDispositivo.toLocal();
      final chave =
          '${r.tipoRegistro}|${DateTime(local.year, local.month, local.day, local.hour, local.minute).toIso8601String()}';
      if (chaves.add(chave)) registros.add(r);
    }

    showDialog(
      context: context,
      builder: (context) => AjustePontoDialog(
        dataInicial: dataInicial,
        todosRegistros: registros,
      ),
    );
  }

  Future<void> _exportarPdf(PontoProvider pontoProvider) async {
    final authProvider = context.read<AuthProvider>();
    final usuario = authProvider.usuario;
    if (usuario == null) return;

    try {
      await PdfEspelhoService.exportarEspelhoPdf(
        usuario: usuario,
        registros: pontoProvider.espelho,
        mes: pontoProvider.mesSelecionado,
        ano: pontoProvider.anoSelecionado,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pontoProvider = context.watch<PontoProvider>();
    final mes = pontoProvider.mesSelecionado;
    final ano = pontoProvider.anoSelecionado;

    final registros = pontoProvider.espelho;

    // Agrupa batidas por dia
    final Map<int, List<RegistroPontoModel>> batidasPorDia = {};
    for (var r in registros) {
      if (r.dataHoraDispositivo.month == mes && r.dataHoraDispositivo.year == ano) {
        final dia = r.dataHoraDispositivo.day;
        batidasPorDia.putIfAbsent(dia, () => []).add(r);
      }
    }

    batidasPorDia.forEach((dia, lista) {
      lista.sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));
    });

    final diasNoMes = DateTime(ano, mes + 1, 0).day;
    int totalMinutosMes = 0;
    int totalAjustesMes = 0;

    for (int d = 1; d <= diasNoMes; d++) {
      final batidas = batidasPorDia[d] ?? [];
      for (var b in batidas) {
        if (b.ajusteManual) totalAjustesMes++;
      }
      if (batidas.length >= 2) {
        for (int i = 0; i < batidas.length - 1; i += 2) {
          final diff = batidas[i + 1].dataHoraDispositivo.difference(batidas[i].dataHoraDispositivo).inMinutes;
          if (diff > 0 && diff < 900) {
            totalMinutosMes += diff;
          }
        }
      }
    }

    final totalHorasStr =
        '${(totalMinutosMes ~/ 60).toString().padLeft(2, '0')}h ${(totalMinutosMes % 60).toString().padLeft(2, '0')}m';

    final mesesNomes = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de Controles: Seletores e Botões de Ação
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      // Seletor de Período
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: mes,
                            underline: const SizedBox(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                            items: List.generate(12, (index) {
                              return DropdownMenuItem(
                                value: index + 1,
                                child: Text(mesesNomes[index]),
                              );
                            }),
                            onChanged: (novoMes) {
                              if (novoMes != null) {
                                pontoProvider.alterarPeriodoEspelho(novoMes, ano);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: ano,
                            underline: const SizedBox(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                            items: [2024, 2025, 2026, 2027].map((a) {
                              return DropdownMenuItem(
                                value: a,
                                child: Text(a.toString()),
                              );
                            }).toList(),
                            onChanged: (novoAno) {
                              if (novoAno != null) {
                                pontoProvider.alterarPeriodoEspelho(mes, novoAno);
                              }
                            },
                          ),
                        ],
                      ),

                      // Botões: Ajustar Ponto & Exportar PDF
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _abrirDialogAjuste(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            icon: const Icon(Icons.edit_calendar, size: 18),
                            label: const Text('Solicitar Ajuste'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: pontoProvider.carregandoEspelho ? null : () => _exportarPdf(pontoProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            icon: const Icon(Icons.picture_as_pdf, size: 18),
                            label: const Text('Exportar PDF'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cards de Resumo
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Horas Trabalhadas', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            Text(totalHorasStr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ajustes Manuais', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            Text(
                              totalAjustesMes.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: totalAjustesMes > 0 ? Colors.orange.shade800 : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dias com Registro', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            Text(
                              batidasPorDia.keys.length.toString(),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Listagem Dia a Dia do Espelho
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Demonstrativo de Marcações do Mês',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (pontoProvider.carregandoEspelho)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: diasNoMes,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final dia = index + 1;
                          final data = DateTime(ano, mes, dia);
                          final diaSemana = DateFormat('EEE', 'pt_BR').format(data).toUpperCase();
                          final isFimDeSemana = data.weekday == DateTime.saturday || data.weekday == DateTime.sunday;
                          final batidas = batidasPorDia[dia] ?? [];

                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            color: isFimDeSemana ? Theme.of(context).colorScheme.surface.withOpacity(0.4) : null,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Coluna Data & Dia da Semana
                                SizedBox(
                                  width: 80,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('dd/MM').format(data),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isFimDeSemana ? Colors.grey[600] : null,
                                        ),
                                      ),
                                      Text(
                                        diaSemana,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isFimDeSemana ? Colors.grey[500] : Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Marcações do Dia
                                Expanded(
                                  child: batidas.isEmpty
                                      ? Text(
                                          isFimDeSemana ? 'Final de Semana' : 'Sem marcações registradas',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        )
                                      : Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: batidas.map((b) {
                                            final hora = DateFormat('HH:mm').format(b.dataHoraDispositivo.toLocal());
                                            final cor = _obterCorTipo(b.tipoRegistro);
                                            final isAjuste = b.ajusteManual;

                                            return Tooltip(
                                              message: isAjuste
                                                  ? 'Ajuste Manual: ${b.justificativa ?? "Sem justificativa"}${b.observacao != null ? " (${b.observacao})" : ""}'
                                                  : '${_nomesTipos[b.tipoRegistro] ?? b.tipoRegistro} às $hora',
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: cor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isAjuste ? Colors.deepPurple : cor.withOpacity(0.4),
                                                    width: isAjuste ? 1.5 : 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (isAjuste) ...[
                                                      const Icon(Icons.edit_note, size: 14, color: Colors.deepPurple),
                                                      const SizedBox(width: 4),
                                                    ],
                                                    Text(
                                                      '${_nomesTipos[b.tipoRegistro] ?? b.tipoRegistro}: $hora',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: isAjuste ? Colors.deepPurple : cor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                ),

                                // Botão rápido para adicionar ajuste nesta data
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  tooltip: 'Inserir ajuste neste dia',
                                  color: Theme.of(context).colorScheme.primary,
                                  onPressed: () => _abrirDialogAjuste(data),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
