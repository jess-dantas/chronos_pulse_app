import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/data/models/usuario_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../navigation/presentation/screens/main_shell.dart';
import '../../../ponto/presentation/providers/ponto_provider.dart';

/// Home do usuário logado (`/painel/home`).
///
/// Saudação + status do dia (marcações, sincronização e fila de aprovação do
/// RH) + atalhos para as áreas mais usadas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _ajustesPendentesRh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarFilaRh());
  }

  Future<void> _carregarFilaRh() async {
    final usuario = context.read<AuthProvider>().usuario;
    if (usuario == null || !usuario.isGestorRh) return;

    try {
      final pendentes =
          await context.read<PontoProvider>().listarAjustesPendentes();
      if (!mounted) return;
      setState(() {
        _ajustesPendentesRh =
            pendentes.where((r) => r.ajusteStatus == 'PENDENTE').length;
      });
    } catch (_) {
      // Sem fila disponível: o cartão simplesmente fica ausente.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ponto = context.watch<PontoProvider>();
    final usuario = auth.usuario;

    final nome = usuario == null
        ? '—'
        : (usuario.nome.isNotEmpty ? usuario.nome : usuario.role);
    final agora = DateTime.now();
    final hoje = DateFormat('EEEE, d ' "'de' " 'MMMM', 'pt_BR').format(agora);

    final deHoje = ponto.historico.where((r) {
      final d = r.dataHoraDispositivo.toLocal();
      return d.year == agora.year &&
          d.month == agora.month &&
          d.day == agora.day;
    }).toList()
      ..sort((a, b) => a.dataHoraDispositivo.compareTo(b.dataHoraDispositivo));

    final ultima = deHoje.isEmpty ? null : deHoje.last;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cabecalho(
                context,
                nome: nome,
                papel: usuario?.role ?? '—',
                hoje: hoje,
                fotoBytes: usuario?.temFoto == true ? usuario!.fotoBytes : null,
                avatarIcone:
                    usuario?.isAdminEmpresa == true ? Icons.business : null,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _cardStatus(
                    context,
                    titulo: 'Marcações de hoje',
                    valor: deHoje.length.toString(),
                    detalhe: ultima == null
                        ? 'Nenhuma marcação ainda'
                        : 'Última às ${DateFormat('HH:mm').format(ultima.dataHoraDispositivo.toLocal())}',
                    icone: Icons.fingerprint,
                    cor: Colors.green,
                  ),
                  _cardStatus(
                    context,
                    titulo: 'Sincronização',
                    valor: ponto.pendentesCount.toString(),
                    detalhe: ponto.isOnline
                        ? 'Online — tudo enviado'
                        : 'Offline — aguardando envio',
                    icone: ponto.isOnline ? Icons.cloud_done : Icons.cloud_off,
                    cor: ponto.isOnline ? Colors.blue : Colors.orange,
                  ),
                  if (_ajustesPendentesRh != null)
                    _cardStatus(
                      context,
                      titulo: 'Ajustes aguardando aprovação',
                      valor: _ajustesPendentesRh.toString(),
                      detalhe: _ajustesPendentesRh == 0
                          ? 'Nada na fila do RH'
                          : 'Toque para revisar a fila',
                      icone: Icons.how_to_reg_outlined,
                      cor: Colors.deepPurple,
                      onTap: usuario?.isGestorRh == true
                          ? () => context.go('/painel/aprovacao-ajustes')
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Atalhos',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _atalho(
                    context,
                    rotulo: 'Bater Ponto',
                    icone: Icons.fingerprint,
                    onTap: () => context.go('/painel/ponto'),
                  ),
                  _atalho(
                    context,
                    rotulo: 'Espelho de Ponto',
                    icone: Icons.receipt_long_outlined,
                    onTap: () => context.go('/painel/ponto?aba=espelho'),
                  ),
                  _atalho(
                    context,
                    rotulo: 'Perfil',
                    icone: Icons.person_outline,
                    onTap: () => context.push('/perfil'),
                  ),
                  if (usuario != null)
                    for (final modulo in _modulosUsuario(usuario))
                      _atalho(
                        context,
                        rotulo: MainShell.metadados[modulo]?.label ?? modulo,
                        icone: MainShell.metadados[modulo]?.icon ?? Icons.apps,
                        onTap: () => context.go('/painel/$modulo'),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Módulos do painel disponíveis para o usuário, sem repetir os atalhos fixos.
  Iterable<String> _modulosUsuario(UsuarioModel usuario) sync* {
    const fixos = {'home', 'ponto', 'privacidade'};
    for (final modulo in AppRouter.painelOrdem) {
      if (fixos.contains(modulo)) continue;
      if (AppRouter.podeModuloPainel(usuario, modulo)) yield modulo;
    }
  }

  Widget _cabecalho(
    BuildContext context, {
    required String nome,
    required String papel,
    required String hoje,
    required Uint8List? fotoBytes,
    IconData? avatarIcone,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            UserAvatar(
                nome: nome, raio: 30, fotoBytes: fotoBytes, icone: avatarIcone),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo, $nome',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${papel.replaceAll('ROLE_', '')} • $hoje',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardStatus(
    BuildContext context, {
    required String titulo,
    required String valor,
    required String detalhe,
    required IconData icone,
    required Color cor,
    VoidCallback? onTap,
  }) {
    final card = Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 230,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icone, color: cor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titulo,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                valor,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                detalhe,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
    return card;
  }

  Widget _atalho(
    BuildContext context, {
    required String rotulo,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 180,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone,
                    size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  rotulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
