import 'package:flutter/material.dart';

/// Avatar com iniciais (2 letras) e fallback para ícone.
/// Usado no MainShell e AdminShell para representar o usuário logado.
class UserAvatar extends StatelessWidget {
  final String nome;
  final double raio;
  final IconData? icone;

  const UserAvatar({
    super.key,
    required this.nome,
    this.raio = 16,
    this.icone,
  });

  String get _iniciais {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;
    final corFg = Theme.of(context).colorScheme.onPrimary;

    if (icone != null) {
      return CircleAvatar(
        radius: raio,
        backgroundColor: cor,
        child: Icon(icone, size: raio * 1.1, color: corFg),
      );
    }

    return CircleAvatar(
      radius: raio,
      backgroundColor: cor,
      child: Text(
        _iniciais,
        style: TextStyle(
          color: corFg,
          fontSize: raio * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
