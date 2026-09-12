import 'dart:convert';
import 'dart:typed_data';

class UsuarioModel {
  final String token;
  final String? refreshToken;
  final String tipo;
  final String nome;
  final String email;
  final String? cpf;
  final String role;
  final String? tenantId;
  final String? tenantSlug;
  final String? colaboradorId;
  final String? cpcId;
  final bool acessoEstoque;
  final bool acessoPatrimonio;
  final bool acessoFrota;
  final bool acessoProtocolo;
  final String? foto;
  final List<String> modulos;

  UsuarioModel({
    required this.token,
    this.refreshToken,
    required this.tipo,
    required this.nome,
    required this.email,
    this.cpf,
    required this.role,
    this.tenantId,
    this.tenantSlug,
    this.colaboradorId,
    this.cpcId,
    this.acessoEstoque = false,
    this.acessoPatrimonio = false,
    this.acessoFrota = false,
    this.acessoProtocolo = false,
    this.foto,
    this.modulos = const [],
  });

  bool get isAdminPlataforma => role == 'ADMIN_PLATAFORMA';
  bool get isSuporte => role == 'SUPORTE_N1' || role == 'SUPORTE_N2';
  bool get isAdminEmpresa => role == 'ADMIN_EMPRESA';
  bool get isGestorRh => role == 'GESTOR_RH';
  bool get isColaborador => role == 'COLABORADOR';

  bool get isAdminOrRh => isAdminPlataforma || isAdminEmpresa || isGestorRh;
  bool get isGestorPlataforma => isAdminPlataforma || isSuporte;
  bool get temAcessoEstoque => isAdminOrRh || acessoEstoque;
  bool get temAcessoPatrimonio => isAdminOrRh || acessoPatrimonio;
  bool get temAcessoFrota => isAdminOrRh || acessoFrota;
  bool get temAcessoProtocolo => isAdminOrRh || acessoProtocolo;

  bool get temModuloPonto => isGestorPlataforma || _temModulo('PONTO');
  bool get temModuloRh => isGestorPlataforma || _temModulo('RECURSOS_HUMANOS');
  bool get temModuloEstoque => isGestorPlataforma || _temModulo('ESTOQUE');
  bool get temModuloCompras => isGestorPlataforma || _temModulo('COMPRAS');
  bool get temModuloLicitacoes => isGestorPlataforma || _temModulo('LICITACOES');
  bool get temModuloPatrimonio => isGestorPlataforma || _temModulo('PATRIMONIO');
  bool get temModuloFrota => isGestorPlataforma || _temModulo('FROTA');
  bool get temModuloProtocolo => isGestorPlataforma || _temModulo('PROTOCOLO');
  bool get temModuloTransparencia => isGestorPlataforma || _temModulo('TRANSPARENCIA');

  bool _temModulo(String codigo) => modulos.contains(codigo);

  bool get temFoto => foto != null && foto!.isNotEmpty;

  Uint8List get fotoBytes {
    if (!temFoto) return Uint8List(0);
    final partes = foto!.split(',');
    final base64 = partes.length > 1 ? partes[1] : partes[0];
    try {
      return base64Decode(base64);
    } catch (_) {
      return Uint8List(0);
    }
  }

  UsuarioModel copyWith({String? cpf, String? foto, List<String>? modulos}) {
    return UsuarioModel(
      token: token,
      refreshToken: refreshToken,
      tipo: tipo,
      nome: nome,
      email: email,
      cpf: cpf ?? this.cpf,
      role: role,
      tenantId: tenantId,
      tenantSlug: tenantSlug,
      colaboradorId: colaboradorId,
      cpcId: cpcId,
      acessoEstoque: acessoEstoque,
      acessoPatrimonio: acessoPatrimonio,
      acessoFrota: acessoFrota,
      acessoProtocolo: acessoProtocolo,
      foto: foto ?? this.foto,
      modulos: modulos ?? this.modulos,
    );
  }

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final rawModulos = json['modulos'];
    List<String> modulos = const [];
    if (rawModulos is List) {
      modulos = rawModulos.whereType<String>().toList();
    }
    return UsuarioModel(
      token: json['accessToken'] ?? json['token'] ?? '',
      refreshToken: json['refreshToken'],
      tipo: json['tipo'] ?? 'Bearer',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      cpf: json['cpf'] ?? json['sub'],
      role: json['role'] ?? '',
      tenantId: json['tenantId'],
      tenantSlug: json['tenantSlug'],
      colaboradorId: json['colaboradorId'] ?? json['cpcId'],
      cpcId: json['cpcId'],
      acessoEstoque: json['acessoEstoque'] ?? false,
      acessoPatrimonio: json['acessoPatrimonio'] ?? false,
      acessoFrota: json['acessoFrota'] ?? false,
      acessoProtocolo: json['acessoProtocolo'] ?? false,
      foto: json['foto'],
      modulos: modulos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'tipo': tipo,
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'role': role,
      'tenantId': tenantId,
      'tenantSlug': tenantSlug,
      'colaboradorId': colaboradorId,
      'cpcId': cpcId,
      'acessoEstoque': acessoEstoque,
      'acessoPatrimonio': acessoPatrimonio,
      'acessoFrota': acessoFrota,
      'acessoProtocolo': acessoProtocolo,
      'foto': foto,
      'modulos': modulos,
    };
  }
}
