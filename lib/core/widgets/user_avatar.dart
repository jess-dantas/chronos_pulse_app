import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Avatar com foto (quando disponível) e fallback para iniciais (2 letras).
/// Usado no MainShell, AdminShell e na tela de Perfil.
class UserAvatar extends StatelessWidget {
  final String nome;
  final double raio;
  final IconData? icone;
  final Uint8List? fotoBytes;

  const UserAvatar({
    super.key,
    required this.nome,
    this.raio = 16,
    this.icone,
    this.fotoBytes,
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

    final temFoto = fotoBytes != null && fotoBytes!.isNotEmpty;
    if (temFoto) {
      return CircleAvatar(
        radius: raio,
        backgroundColor: cor,
        foregroundImage: MemoryImage(fotoBytes!),
        child: icone != null
            ? Icon(icone, size: raio * 1.1, color: corFg)
            : Text(
                _iniciais,
                style: TextStyle(
                  color: corFg,
                  fontSize: raio * 0.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
      );
    }

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
