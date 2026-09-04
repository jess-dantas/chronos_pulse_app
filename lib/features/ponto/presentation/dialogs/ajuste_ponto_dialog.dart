import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/registro_ponto_model.dart';
import '../../domain/constants/justificativas_ponto.dart';
import '../providers/ponto_provider.dart';

class AjustePontoDialog extends StatefulWidget {
  final DateTime? dataInicial;
  final List<RegistroPontoModel> todosRegistros;

  const AjustePontoDialog({
    super.key,
    this.dataInicial,
    this.todosRegistros = const [],
  });

  @override
  State<AjustePontoDialog> createState() => _AjustePontoDialogState();
}

class _AjustePontoDialogState extends State<AjustePontoDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _dataSelecionada;
  late TimeOfDay _horaSelecionada;
  late String _tipoRegistro;
  String? _justificativaSelecionada;
  final TextEditingController _observacaoController = TextEditingController();
  bool _isEnviando = false;

  @override
  void initState() {
    super.initState();
    _dataSelecionada = widget.dataInicial ?? DateTime.now();
    _horaSelecionada = TimeOfDay.now();
    _tipoRegistro = _determinarProximoTipoParaData(_dataSelecionada);
  }

  String _determinarProximoTipo(List<RegistroPontoModel> registros) {
    final total = registros.length;
    switch (total % 4) {
      case 0:
        return 'ENTRADA';
      case 1:
        return 'INTERVALO';
      case 2:
        return 'RETORNO';
      case 3:
        return 'SAIDA';
      default:
        return 'ENTRADA';
    }
  }

  String _determinarProximoTipoParaData(DateTime data) {
    final registrosDoDia = widget.todosRegistros.where((r) {
      final d = r.dataHoraDispositivo.toLocal();
      return d.year == data.year && d.month == data.month && d.day == data.day;
    }).toList();
    return _determinarProximoTipo(registrosDoDia);
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _dataSelecionada = picked;
        _tipoRegistro = _determinarProximoTipoParaData(picked);
      });
    }
  }

  Future<void> _selecionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaSelecionada,
    );
    if (picked != null) {
      setState(() => _horaSelecionada = picked);
    }
  }

  Future<void> _salvarAjuste() async {
    if (!_formKey.currentState!.validate()) return;
    if (_justificativaSelecionada == null || _justificativaSelecionada!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma justificativa obrigatória.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isEnviando = true);

    final dataHoraCompleta = DateTime(
      _dataSelecionada.year,
      _dataSelecionada.month,
      _dataSelecionada.day,
      _horaSelecionada.hour,
      _horaSelecionada.minute,
    );

    final pontoProvider = context.read<PontoProvider>();

    try {
      final sucesso = await pontoProvider.ajustarPontoManual(
        dataHora: dataHoraCompleta,
        tipoRegistro: _tipoRegistro,
        justificativa: _justificativaSelecionada!,
        observacao: _observacaoController.text.trim().isNotEmpty ? _observacaoController.text.trim() : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sucesso
                  ? 'Ajuste manual registrado com sucesso!'
                  : 'Ajuste salvo localmente. Aguardando sincronização.',
            ),
            backgroundColor: sucesso ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar ajuste: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.edit_calendar, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ajuste Manual de Ponto',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Inclusão ou correção de marcação de ponto',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Linha com Seletores de Data e Hora
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selecionarData,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Data da Marcação',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.calendar_today, size: 20),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_dataSelecionada),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _selecionarHora,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Horário',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.access_time, size: 20),
                            ),
                            child: Text(
                              _horaSelecionada.format(context),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tipo de Marcação
                  DropdownButtonFormField<String>(
                    value: _tipoRegistro,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Marcação *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.touch_app_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada (Início de Jornada)')),
                      DropdownMenuItem(value: 'INTERVALO', child: Text('Intervalo (Saída para Almoço)')),
                      DropdownMenuItem(value: 'RETORNO', child: Text('Retorno (Volta do Intervalo)')),
                      DropdownMenuItem(value: 'SAIDA', child: Text('Saída (Fim de Jornada)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _tipoRegistro = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Combo Obrigatório com as 8 Justificativas Padronizadas
                  DropdownButtonFormField<String>(
                    value: _justificativaSelecionada,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Justificativa Legal * (Obrigatória)',
                      hintText: 'Selecione o motivo do ajuste',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.fact_check_outlined),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Selecione a justificativa' : null,
                    items: JustificativasPonto.lista.map((j) {
                      return DropdownMenuItem<String>(
                        value: j.titulo,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              j.titulo,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              j.descricao,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (context) {
                      return JustificativasPonto.lista.map((j) {
                        return Text(
                          j.titulo,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        );
                      }).toList();
                    },
                    onChanged: (val) {
                      setState(() => _justificativaSelecionada = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Observação Complementar
                  TextFormField(
                    controller: _observacaoController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Observação Complementar (Opcional)',
                      hintText: 'Detalhes adicionais para o RH...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botões de Ação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isEnviando ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isEnviando ? null : _salvarAjuste,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isEnviando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: const Text('Salvar Ajuste'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
