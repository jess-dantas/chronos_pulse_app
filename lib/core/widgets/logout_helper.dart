import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/admin/presentation/providers/admin_auth_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'dialogs/confirm_logout_dialog.dart';

/// Confirma (via [ConfirmLogoutDialog]) e encerra a sessão ativa —
/// sessão de tenant e/ou sessão do Admin Plataforma.
///
/// Compartilhado pelos shells, pelo drawer mobile e pela tela de Perfil,
/// para que o fluxo de "Sair" seja idêntico em qualquer ponto do app.
Future<void> encerrarSessaoConfirmada(BuildContext context) async {
  final confirmado = await ConfirmLogoutDialog.show(context);
  if (confirmado != true || !context.mounted) return;

  final adminAuth = context.read<AdminAuthProvider>();
  final auth = context.read<AuthProvider>();

  if (adminAuth.isAuthenticated) adminAuth.logout();
  if (auth.isAuthenticated) auth.logout();
}
