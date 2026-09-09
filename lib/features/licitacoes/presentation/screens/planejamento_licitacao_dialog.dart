import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/licitacoes_models.dart';
import '../../data/models/planejamento_licitacao_models.dart';
import '../providers/licitacoes_provider.dart';

Future<void> exibirDialogPlanejamento(
    BuildContext context, LicitacaoModel licitacao) async {
  final provider = context.read<LicitacoesProvider>();
  await provider.carregarPlanejamento(licitacao.id);
  if (!context.mounted) return;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final watchProvider = dialogContext.watch<LicitacoesProvider>();
      final planejamento = watchProvider.planejamento(licitacao.id);

      return AlertDialog(
        title: Text('Planejamento · ${licitacao.numero}'),
        content: SizedBox(
          width: 640,
          child: planejamento == null
              ? const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _secaoEtp(context, licitacao, planejamento),
                      const SizedBox(height: 12),
                      _secaoTr(context, licitacao, planejamento),
                      const SizedBox(height: 12),
                      _secaoEdital(context, licitacao, planejamento),
                    ],
                  ),
                ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    },
  );
}

// ============================ SEÇÕES ============================

Widget _secaoEtp(BuildContext context, LicitacaoModel licitacao,
    PlanejamentoLicitacaoModel planejamento) {
  final etp = planejamento.etp;
  final podeEditar = etp == null || !etp.aprovado;

  return _DocumentoCard(
    titulo: '1. Estudo Técnico Preliminar (ETP)',
    status: etp?.statusLabel ?? 'Não elaborado',
    icone: Icons.search_outlined,
    cor: const Color(0xFF1565C0),
    subtitulos: etp == null
        ? const [Text('Documento inicial que descreve a necessidade, requisitos e a viabilidade da contratação.')]
        : [
            Text('Objeto: ${etp.objeto}'),
            if (etp.valorEstimado != null)
              Text('Valor estimado: ${_fmtValor(etp.valorEstimado!)}'),
            if (etp.conclusao.isNotEmpty) Text('Conclusão: ${etp.conclusao}'),
            if (etp.aprovado)
              Text(
                'Aprovado por ${etp.responsavel.isEmpty ? 'desconhecido' : etp.responsavel}.',
                style: const TextStyle(color: Color(0xFF2E7D32)),
              ),
          ],
    acoes: [
      if (podeEditar)
        FilledButton.tonalIcon(
          onPressed: () => _exibirFormEtp(context, licitacao, etp),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(etp == null ? 'Elaborar ETP' : 'Editar ETP'),
        ),
      if (etp != null && !etp.aprovado)
        OutlinedButton.icon(
          onPressed: () => _aprovarDocumento(context, licitacao, 'ETP',
              (responsavel) => context.read<LicitacoesProvider>().aprovarEtp(licitacao.id, responsavel)),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Aprovar'),
        ),
    ],
  );
}

Widget _secaoTr(BuildContext context, LicitacaoModel licitacao,
    PlanejamentoLicitacaoModel planejamento) {
  final tr = planejamento.tr;
  final etpOk = planejamento.etp?.aprovado ?? false;

  if (!etpOk) {
    return const _DocumentoCard(
      titulo: '2. Termo de Referência (TR)',
      status: 'Bloqueado',
      icone: Icons.description_outlined,
      cor: Colors.grey,
      subtitulos: [
        Text('Aprove o ETP para elaborar o Termo de Referência.'),
      ],
      acoes: [],
    );
  }

  final podeEditar = tr == null || !tr.aprovado;

  return _DocumentoCard(
    titulo: '2. Termo de Referência (TR)',
    status: tr?.statusLabel ?? 'Não elaborado',
    icone: Icons.description_outlined,
    cor: const Color(0xFF6A1B9A),
    subtitulos: tr == null
        ? const [Text('Detalha especificações, condições de fornecimento, obrigações e critérios de aceitação.')]
        : [
            Text('Especificações: ${tr.especificacoes}'),
            Text('Condições de fornecimento: ${tr.condicoesFornecimento}'),
            if (tr.prazosEntrega.isNotEmpty)
              Text('Prazos: ${tr.prazosEntrega}'),
            if (tr.aprovado)
              Text(
                'Aprovado por ${tr.responsavel.isEmpty ? 'desconhecido' : tr.responsavel}.',
                style: const TextStyle(color: Color(0xFF2E7D32)),
              ),
          ],
    acoes: [
      if (podeEditar)
        FilledButton.tonalIcon(
          onPressed: () => _exibirFormTr(context, licitacao, tr),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(tr == null ? 'Elaborar TR' : 'Editar TR'),
        ),
      if (tr != null && !tr.aprovado)
        OutlinedButton.icon(
          onPressed: () => _aprovarDocumento(context, licitacao, 'TR',
              (responsavel) => context.read<LicitacoesProvider>().aprovarTr(licitacao.id, responsavel)),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Aprovar'),
        ),
    ],
  );
}

Widget _secaoEdital(BuildContext context, LicitacaoModel licitacao,
    PlanejamentoLicitacaoModel planejamento) {
  final edital = planejamento.edital;
  final trOk = planejamento.tr?.aprovado ?? false;

  if (!trOk) {
    return const _DocumentoCard(
      titulo: '3. Edital',
      status: 'Bloqueado',
      icone: Icons.campaign_outlined,
      cor: Colors.grey,
      subtitulos: [
        Text('Aprove o Termo de Referência para elaborar o edital.'),
      ],
      acoes: [],
    );
  }

  final podeEditar = edital == null || !edital.publicado;

  return _DocumentoCard(
    titulo: '3. Edital',
    status: edital?.statusLabel ?? 'Não elaborado',
    icone: Icons.campaign_outlined,
    cor: const Color(0xFFEF6C00),
    subtitulos: edital == null
        ? const [Text('Reúne os dados da sessão pública, anexos e a publicação do certame.')]
        : [
            if (edital.numeroProcesso.isNotEmpty)
              Text('Processo: ${edital.numeroProcesso}'),
            if (edital.numeroEdital.isNotEmpty)
              Text('Edital n. ${edital.numeroEdital}'),
            if (edital.dataAberturaSessao != null && edital.dataAberturaSessao!.isNotEmpty)
              Text(
                  'Sessão: ${edital.dataSessaoFormatada}${edital.horarioAbertura != null ? ' às ${edital.horarioAbertura!.substring(0, edital.horarioAbertura!.length >= 5 ? 5 : edital.horarioAbertura!.length)}' : ''}'),
            if (edital.formaEntregaPropostas.isNotEmpty)
              Text('Entrega de propostas: ${edital.formaEntregaLabel}'),
          ],
    acoes: [
      if (podeEditar)
        FilledButton.tonalIcon(
          onPressed: () => _exibirFormEdital(context, licitacao, edital),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(edital == null ? 'Elaborar edital' : 'Editar edital'),
        ),
      if (edital != null && !edital.publicado)
        OutlinedButton.icon(
          onPressed: () => _publicarEdital(context, licitacao),
          icon: const Icon(Icons.campaign_outlined, size: 18),
          label: const Text('Publicar'),
        ),
    ],
  );
}

// ============================ FORMULÁRIOS ============================

Future<void> _exibirFormEtp(
    BuildContext context, LicitacaoModel licitacao, EtpModel? etp) async {
  final provider = context.read<LicitacoesProvider>();
  final form = GlobalKey<FormState>();
  final objeto = TextEditingController(text: etp?.objeto ?? '');
  final justificativa = TextEditingController(text: etp?.justificativa ?? '');
  final requisitos = TextEditingController(text: etp?.requisitos ?? '');
  final alternativas = TextEditingController(text: etp?.alternativas ?? '');
  final valorEstimado = TextEditingController(
      text: etp?.valorEstimado != null ? _fmtValorInput(etp!.valorEstimado!) : '');
  final riscos = TextEditingController(text: etp?.riscos ?? '');
  final conclusao = TextEditingController(text: etp?.conclusao ?? '');

  await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('${etp == null ? 'Elaborar' : 'Editar'} ETP · ${licitacao.numero}'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(objeto, 'Objeto do ETP*', maxLinhas: 2),
                _campo(justificativa, 'Justificativa*', maxLinhas: 3),
                _campo(requisitos, 'Requisitos*', maxLinhas: 3),
                _campo(alternativas, 'Alternativas estudadas', maxLinhas: 2),
                _campo(valorEstimado, 'Valor estimado (R\$)',
                    teclado: const TextInputType.numberWithOptions(decimal: true)),
                _campo(riscos, 'Riscos', maxLinhas: 3),
                _campo(conclusao, 'Conclusão', maxLinhas: 3),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (!form.currentState!.validate()) return;
            final ok = await provider.salvarEtp(
              licitacao.id,
              EtpDTO(
                objeto: objeto.text,
                justificativa: justificativa.text,
                requisitos: requisitos.text,
                alternativas: _vazioOuNull(alternativas.text),
                valorEstimado: _valoresDouble(valorEstimado.text),
                riscos: _vazioOuNull(riscos.text),
                conclusao: _vazioOuNull(conclusao.text),
              ),
            );
            if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok
                    ? 'ETP salvo.'
                    : provider.errorMessage ?? 'Falha ao salvar o ETP.')),
              );
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

Future<void> _exibirFormTr(
    BuildContext context, LicitacaoModel licitacao, TrModel? tr) async {
  final provider = context.read<LicitacoesProvider>();
  final form = GlobalKey<FormState>();
  final especificacoes = TextEditingController(text: tr?.especificacoes ?? '');
  final condicoes = TextEditingController(text: tr?.condicoesFornecimento ?? '');
  final obrigacoes = TextEditingController(text: tr?.obrigacoes ?? '');
  final criterios = TextEditingController(text: tr?.criteriosAceitacao ?? '');
  final prazos = TextEditingController(text: tr?.prazosEntrega ?? '');
  final garantia = TextEditingController(text: tr?.garantia ?? '');
  final pagamento = TextEditingController(text: tr?.formaPagamento ?? '');

  await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('${tr == null ? 'Elaborar' : 'Editar'} TR · ${licitacao.numero}'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(especificacoes, 'Especificações do objeto*', maxLinhas: 3),
                _campo(condicoes, 'Condições de fornecimento*', maxLinhas: 3),
                _campo(obrigacoes, 'Obrigações do fornecedor*', maxLinhas: 3),
                _campo(criterios, 'Critérios de aceitação*', maxLinhas: 3),
                _campo(prazos, 'Prazos de entrega*', maxLinhas: 2),
                _campo(garantia, 'Garantia', maxLinhas: 2),
                _campo(pagamento, 'Forma de pagamento', maxLinhas: 2),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (!form.currentState!.validate()) return;
            final ok = await provider.salvarTr(
              licitacao.id,
              TrDTO(
                especificacoes: especificacoes.text,
                condicoesFornecimento: condicoes.text,
                obrigacoes: obrigacoes.text,
                criteriosAceitacao: criterios.text,
                prazosEntrega: prazos.text,
                garantia: _vazioOuNull(garantia.text),
                formaPagamento: _vazioOuNull(pagamento.text),
              ),
            );
            if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok
                    ? 'Termo de Referência salvo.'
                    : provider.errorMessage ?? 'Falha ao salvar o TR.')),
              );
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

Future<void> _exibirFormEdital(
    BuildContext context, LicitacaoModel licitacao, EditalModel? edital) async {
  final provider = context.read<LicitacoesProvider>();
  final form = GlobalKey<FormState>();
  final numeroProcesso = TextEditingController(text: edital?.numeroProcesso ?? '');
  final numeroEdital = TextEditingController(text: edital?.numeroEdital ?? '');
  final localSessao = TextEditingController(text: edital?.localSessao ?? '');
  final horaAbertura =
      TextEditingController(text: _horaAmigavel(edital?.horarioAbertura));
  final anexos = TextEditingController(text: edital?.anexos ?? '');
  final observacoes = TextEditingController(text: edital?.observacoes ?? '');
  String? dataSessao = edital?.dataAberturaSessao;
  String formaEntrega = edital?.formaEntregaPropostas ?? '';
  bool showFormaEntrega = edital?.formaEntregaPropostas.isNotEmpty ?? false;

  await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text('${edital == null ? 'Elaborar' : 'Editar'} edital · ${licitacao.numero}'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _campo(numeroProcesso, 'Número do processo'),
                  _campo(numeroEdital, 'Número do edital'),
                  _campo(localSessao, 'Local da sessão'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Data de abertura da sessão',
                            hintText: dataSessao ?? 'Opcional - toque para selecionar',
                            suffixIcon: const Icon(Icons.event),
                          ),
                          onTap: () async {
                            final data = await showDatePicker(
                              context: dialogContext,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 730)),
                            );
                            if (data != null) {
                              setDialogState(() {
                                dataSessao =
                                    '${data.year.toString().padLeft(4, '0')}-'
                                    '${data.month.toString().padLeft(2, '0')}-'
                                    '${data.day.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: horaAbertura,
                          decoration: const InputDecoration(
                            labelText: 'Horário (HH:mm)',
                            hintText: '09:00',
                            isDense: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final ok = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(v.trim());
                            return ok ? null : 'Horário inválido';
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: showFormaEntrega && formaEntrega.isNotEmpty,
                        onChanged: (v) => setDialogState(() {
                          showFormaEntrega = v ?? false;
                          if (!showFormaEntrega) formaEntrega = '';
                        }),
                      ),
                      const Flexible(
                        child: Text('Informar forma de entrega das propostas'),
                      ),
                    ],
                  ),
                  if (showFormaEntrega)
                    DropdownButtonFormField<String>(
                      initialValue: formaEntrega.isEmpty ? 'ELETRONICA' : formaEntrega,
                      decoration: const InputDecoration(labelText: 'Forma de entrega'),
                      items: const [
                        DropdownMenuItem(value: 'ELETRONICA', child: Text('Eletrônica')),
                        DropdownMenuItem(value: 'PRESENCIAL', child: Text('Presencial')),
                      ],
                      onChanged: (v) => setDialogState(() => formaEntrega = v ?? ''),
                    ),
                  _campo(anexos, 'Anexos', maxLinhas: 3),
                  _campo(observacoes, 'Observações', maxLinhas: 3),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final ok = await provider.salvarEdital(
                licitacao.id,
                EditalDTO(
                  numeroProcesso: _vazioOuNull(numeroProcesso.text),
                  numeroEdital: _vazioOuNull(numeroEdital.text),
                  localSessao: _vazioOuNull(localSessao.text),
                  dataAberturaSessao: dataSessao,
                  horarioAbertura: _vazioOuNull(horaAbertura.text),
                  formaEntregaPropostas:
                      showFormaEntrega ? formaEntrega : null,
                  anexos: _vazioOuNull(anexos.text),
                  observacoes: _vazioOuNull(observacoes.text),
                ),
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok
                      ? 'Edital salvo.'
                      : provider.errorMessage ?? 'Falha ao salvar o edital.')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _aprovarDocumento(
  BuildContext context,
  LicitacaoModel licitacao,
  String sigla,
  Future<bool> Function(String responsavel) acao,
) async {
  final form = GlobalKey<FormState>();
  final responsavel = TextEditingController();

  final confirmou = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Aprovar $sigla · ${licitacao.numero}'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: form,
          child: TextFormField(
            controller: responsavel,
            decoration: const InputDecoration(
              labelText: 'Responsável pela aprovação*',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o responsável' : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!form.currentState!.validate()) return;
            Navigator.of(dialogContext).pop(true);
          },
          child: const Text('Aprovar'),
        ),
      ],
    ),
  );

  if (confirmou == true && context.mounted) {
    final ok = await acao(responsavel.text.trim());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ok ? '$sigla aprovado.' : 'Falha ao aprovar o $sigla.')),
      );
    }
  }
}

Future<void> _publicarEdital(
    BuildContext context, LicitacaoModel licitacao) async {
  final provider = context.read<LicitacoesProvider>();
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Publicar edital'),
      content: Text(
          'Publicar o edital da licitação ${licitacao.numero}? Isso marca o '
          'encerramento da fase de planejamento.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Não'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Publicar'),
        ),
      ],
    ),
  );

  if (confirmou == true && context.mounted) {
    final ok = await provider.publicarEdital(licitacao.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ok ? 'Edital publicado.' : 'Falha ao publicar o edital.')),
      );
    }
  }
}

// ============================ WIDGETS ============================

class _DocumentoCard extends StatelessWidget {
  final String titulo;
  final String status;
  final IconData icone;
  final Color cor;
  final List<Widget> subtitulos;
  final List<Widget> acoes;

  const _DocumentoCard({
    required this.titulo,
    required this.status,
    required this.icone,
    required this.cor,
    required this.subtitulos,
    required this.acoes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: cor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(status),
                  labelStyle: TextStyle(fontSize: 11, color: cor),
                  backgroundColor: cor.withValues(alpha: 0.10),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...subtitulos.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: DefaultTextStyle(
                  style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                  child: s,
                ),
              ),
            ),
            if (acoes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 4, children: acoes),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _campo(TextEditingController controller, String label,
    {int maxLinhas = 1, TextInputType? teclado}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      maxLines: maxLinhas,
      keyboardType: teclado,
      decoration: InputDecoration(labelText: label, isDense: true),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Informe este campo' : null,
    ),
  );
}

// ============================ UTILITÁRIOS ============================

String? _vazioOuNull(String valor) => valor.trim().isEmpty ? null : valor.trim();

double? _valoresDouble(String valor) {
  final limpo = valor.trim().replaceAll('.', '').replaceAll(',', '.');
  if (limpo.isEmpty) return null;
  return double.tryParse(limpo);
}

String _fmtValor(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

String _fmtValorInput(double valor) => valor.toStringAsFixed(2).replaceAll('.', ',');

String _horaAmigavel(String? hora) {
  if (hora == null || hora.isEmpty) return '';
  return hora.length >= 5 ? hora.substring(0, 5) : hora;
}