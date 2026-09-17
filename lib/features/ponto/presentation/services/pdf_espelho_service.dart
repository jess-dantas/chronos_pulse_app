import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../auth/data/models/usuario_model.dart';
import '../../data/models/espelho_relatorio_model.dart';
import '../../data/models/registro_ponto_model.dart';
import '../../domain/services/espelho_agrupador.dart';

class PdfEspelhoService {
  static const List<String> _nomeColunas = [
    'Entrada',
    'Intervalo',
    'Retorno',
    'Saída',
  ];
  static Future<void> exportarEspelhoPdf({
    required UsuarioModel usuario,
    required List<RegistroPontoModel> registros,
    required int mes,
    required int ano,
    EspelhoRelatorioModel? relatorio,
  }) async {
    final pdf = pw.Document();

    final nomeMes = DateFormat('MMMM yyyy', 'pt_BR').format(DateTime(ano, mes, 1)).toUpperCase();

    // Agrupa batidas por dia (1..31)
    final Map<int, List<RegistroPontoModel>> batidasPorDia = {};
    for (var r in registros) {
      final dia = r.dataHoraDispositivo.day;
      batidasPorDia.putIfAbsent(dia, () => []).add(r);
    }

    // Ordena registros dentro de cada dia
    batidasPorDia.forEach((dia, lista) {
      lista.sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));
    });

    final diasNoMes = DateTime(ano, mes + 1, 0).day;
    final List<List<String>> tableData = [];

    int totalMinutosMes = 0;
    int totalAjustesMes = 0;

    for (int d = 1; d <= diasNoMes; d++) {
      final dataAtual = DateTime(ano, mes, d);
      final diaSemana = DateFormat('EEE', 'pt_BR').format(dataAtual).toUpperCase();
      final dataFormatada = DateFormat('dd/MM').format(dataAtual);

      final batidas = batidasPorDia[d] ?? [];

      String e1 = '-', s1 = '-', e2 = '-', s2 = '-';
      final List<String> justificativas = [];

      // Ajustes sobrepõem a batida original na própria célula (novo valor com o
      // original entre parênteses); batidas de botão ocupam a coluna do tipo.
      final celulas = EspelhoAgrupador.colunasDoDia(batidas);
      final valores = [e1, s1, e2, s2];

      for (var i = 0; i < celulas.length && i < valores.length; i++) {
        final c = celulas[i];
        if (c == null) continue;
        final base = c.incluiOriginal && c.horaOriginal != null
            ? '${c.hora} (${c.horaOriginal})'
            : c.hora;
        valores[i] = c.ajuste ? '$base*' : base;
        if (c.ajuste && (c.justificativa ?? '').isNotEmpty) {
          totalAjustesMes++;
          justificativas.add('${_nomeColunas[i]}: ${c.justificativa}');
        }
      }
      e1 = valores[0];
      s1 = valores[1];
      e2 = valores[2];
      s2 = valores[3];

      // Calcula horas trabalhadas simples se houver marcações aos pares
      int minutosTrabalhadosDia = 0;
      if (batidas.length >= 2) {
        for (int i = 0; i < batidas.length - 1; i += 2) {
          final diff = batidas[i + 1].dataHoraDispositivo.difference(batidas[i].dataHoraDispositivo).inMinutes;
          if (diff > 0 && diff < 900) {
            minutosTrabalhadosDia += diff;
          }
        }
      }
      totalMinutosMes += minutosTrabalhadosDia;

      final horasDiaFormatadas = minutosTrabalhadosDia > 0
          ? '${(minutosTrabalhadosDia ~/ 60).toString().padLeft(2, '0')}:${(minutosTrabalhadosDia % 60).toString().padLeft(2, '0')}'
          : '-';

      tableData.add([
        '$dataFormatada ($diaSemana)',
        e1,
        s1,
        e2,
        s2,
        horasDiaFormatadas,
        justificativas.isNotEmpty ? justificativas.join('; ') : '',
      ]);
    }

    final totalHorasFormatadas =
        '${(totalMinutosMes ~/ 60).toString().padLeft(2, '0')}h ${(totalMinutosMes % 60).toString().padLeft(2, '0')}min';

    final empregadorNome = relatorio?.empregador?.nome;
    final empregadorCnpj = _formatarDocumento(relatorio?.empregador?.cnpj);
    final cargo = relatorio?.trabalhador?.cargo;
    final matricula = relatorio?.trabalhador?.matricula;
    final dataAdmissao = _formatarData(relatorio?.trabalhador?.dataAdmissao);
    final jornadaNome = relatorio?.jornadaContratual?.nome;
    final jornadaCarga = _formatarDuracaoMinutos(relatorio?.jornadaContratual?.cargaHorariaDiariaMinutos);
    final jornadaIntervalo =
        '${relatorio?.jornadaContratual?.intervaloMinimoMinutos ?? '—'} min';
    final dataEmissao = _formatarDataHora(relatorio?.dataEmissao);
    final periodoApurado = (relatorio != null && relatorio.periodo.inicio != null)
        ? '${_formatarData(relatorio.periodo.inicio)} a ${_formatarData(relatorio.periodo.fim)}'
        : null;
    final codigoVerificacao = relatorio?.codigoVerificacao;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Cabeçalho Oficial
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey700),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'CHRONOS PULSE - SISTEMA DE PONTO ELETRÔNICO',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                      ),
                      pw.Text(
                        'PORTARIA MTP Nº 671/2021',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'ESPELHO DE PONTO ELETRÔNICO INDIVIDUAL - $nomeMes',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.deepPurple),
                  ),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Colaborador: ${usuario.nome}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('CPF: ${usuario.cpf ?? '—'}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Perfil: ${usuario.role}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  // Art. 84, incisos I-IV: empregador, trabalhador (admissão e
                  // cargo), data de emissão e horário/jornada contratual.
                  if (relatorio != null) ...[
                    pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Empregador: ${_emEscapar(empregadorNome)}',
                            style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Text(
                          'CNPJ: ${_emEscapar(empregadorCnpj)}',
                          style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Cargo: ${_emEscapar(cargo)}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Matrícula: ${_emEscapar(matricula)}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Admissão: ${_emEscapar(dataAdmissao)}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    if (jornadaNome != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Jornada Contratual: $jornadaNome', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('Carga Horária: $jornadaCarga', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('Intervalo Mínimo: $jornadaIntervalo', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Período Apurado: ${_emEscapar(periodoApurado)}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Data de Emissão: ${_emEscapar(dataEmissao)}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Tabela de Marcações
            pw.TableHelper.fromTextArray(
              headers: [
                'Data / Dia',
                'Entrada',
                'Intervalo',
                'Retorno',
                'Saída',
                'Total Horas',
                'Ocorrências / Justificativas (*Ajuste)',
              ],
              data: tableData,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellAlignment: pw.Alignment.center,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                6: pw.Alignment.centerLeft,
              },
              // Colunas de horário permanecem com largura intrínseca (nunca
              // encolhem nem quebram linha, mesmo com "HH:mm (HH:mm)*"). A
              // coluna de Ocorrências/Justificativas absorve o espaço restante
              // e é a única que ajusta conforme o tamanho do texto.
              columnWidths: {6: const pw.FlexColumnWidth(1)},
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            ),
            pw.SizedBox(height: 12),

            // Resumo
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Total de Horas no Mês: $totalHorasFormatadas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  pw.Text('Ajustes Manuais com Justificativa: $totalAjustesMes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Campo de Assinaturas
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Divider(thickness: 0.8, color: PdfColors.grey700),
                      pw.Text('Assinatura do Colaborador', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(usuario.nome, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 40),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Divider(thickness: 0.8, color: PdfColors.grey700),
                      pw.Text('Gestão de RH / Fiscal de Ponto', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Visto e Aprovado', style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            if (codigoVerificacao != null && codigoVerificacao.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Código de Verificação (SHA-256): $codigoVerificacao',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
              ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Espelho_Ponto_${usuario.cpf ?? 'SEM_CPF'}_${mes}_$ano.pdf',
    );
  }

  static String _emEscapar(String? valor) => valor == null || valor.isEmpty ? '—' : valor;

  static String _formatarDocumento(String? doc) {
    if (doc == null || doc.length < 11) return _emEscapar(doc);
    final apenasDigitos = doc.replaceAll(RegExp(r'\D'), '');
    if (apenasDigitos.length == 11) {
      return '${apenasDigitos.substring(0, 3)}.${apenasDigitos.substring(3, 6)}.'
          '${apenasDigitos.substring(6, 9)}-${apenasDigitos.substring(9)}';
    }
    if (apenasDigitos.length == 14) {
      return '${apenasDigitos.substring(0, 2)}.${apenasDigitos.substring(2, 5)}.'
          '${apenasDigitos.substring(5, 8)}/${apenasDigitos.substring(8, 12)}-'
          '${apenasDigitos.substring(12)}';
    }
    return doc;
  }

  static String _formatarData(DateTime? data) {
    if (data == null) return _emEscapar(null);
    return DateFormat('dd/MM/yyyy').format(data);
  }

  static String _formatarDataHora(DateTime? data) {
    if (data == null) return _emEscapar(null);
    return DateFormat('dd/MM/yyyy HH:mm').format(data.toLocal());
  }

  static String _formatarDuracaoMinutos(int? minutos) {
    if (minutos == null || minutos <= 0) return '—';
    final h = (minutos ~/ 60).toString().padLeft(2, '0');
    final m = (minutos % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
