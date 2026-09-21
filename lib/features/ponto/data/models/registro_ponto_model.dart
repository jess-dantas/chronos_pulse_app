import 'package:uuid/uuid.dart';

class RegistroPontoModel {
  final String idLocal;
  final String? colaboradorId;
  final DateTime dataHoraDispositivo;
  final DateTime? dataHoraServidor;
  final String tipoRegistro; // "ENTRADA", "INTERVALO", "RETORNO", "SAIDA"
  final double latitude;
  final double longitude;
  final double precisaoGps;
  final String? fotoUrl;
  final String? hashLocal;
  final bool sincronizadoOffline;
  final bool ajusteManual;
  final String? justificativa;
  final String? observacao;
  final int? nsr;
  final int? nsrLogico;
  final String? ajusteStatus; // "PENDENTE", "APROVADO", "REJEITADO"
  final String? ajusteMotivoRejeicao;
  final String? aprovadoPor;
  final DateTime? aprovadoEm;

  RegistroPontoModel({
    required this.idLocal,
    this.colaboradorId,
    required this.dataHoraDispositivo,
    this.dataHoraServidor,
    required this.tipoRegistro,
    required this.latitude,
    required this.longitude,
    required this.precisaoGps,
    this.fotoUrl,
    this.hashLocal,
    this.sincronizadoOffline = false,
    this.ajusteManual = false,
    this.justificativa,
    this.observacao,
    this.nsr,
    this.nsrLogico,
    this.ajusteStatus,
    this.ajusteMotivoRejeicao,
    this.aprovadoPor,
    this.aprovadoEm,
  });

  RegistroPontoModel copyWith({
    DateTime? dataHoraServidor,
    bool? sincronizadoOffline,
    bool? ajusteManual,
    String? justificativa,
    String? observacao,
    int? nsrLogico,
    String? ajusteStatus,
    String? ajusteMotivoRejeicao,
    String? aprovadoPor,
    DateTime? aprovadoEm,
  }) {
    return RegistroPontoModel(
      idLocal: idLocal,
      colaboradorId: colaboradorId,
      dataHoraDispositivo: dataHoraDispositivo,
      dataHoraServidor: dataHoraServidor ?? this.dataHoraServidor,
      tipoRegistro: tipoRegistro,
      latitude: latitude,
      longitude: longitude,
      precisaoGps: precisaoGps,
      fotoUrl: fotoUrl,
      hashLocal: hashLocal,
      sincronizadoOffline: sincronizadoOffline ?? this.sincronizadoOffline,
      ajusteManual: ajusteManual ?? this.ajusteManual,
      justificativa: justificativa ?? this.justificativa,
      observacao: observacao ?? this.observacao,
      nsr: nsr,
      nsrLogico: nsrLogico ?? this.nsrLogico,
      ajusteStatus: ajusteStatus ?? this.ajusteStatus,
      ajusteMotivoRejeicao: ajusteMotivoRejeicao ?? this.ajusteMotivoRejeicao,
      aprovadoPor: aprovadoPor ?? this.aprovadoPor,
      aprovadoEm: aprovadoEm ?? this.aprovadoEm,
    );
  }

  /// Formato salvo localmente no SQLite / Web storage
  Map<String, dynamic> toJson() {
    return {
      'idLocal': idLocal,
      'colaboradorId': colaboradorId,
      'dataHoraDispositivo': dataHoraDispositivo.toIso8601String(),
      'dataHoraServidor': dataHoraServidor?.toIso8601String(),
      'tipoRegistro': tipoRegistro,
      'latitude': latitude,
      'longitude': longitude,
      'precisaoGps': precisaoGps,
      'fotoUrl': fotoUrl,
      'hashLocal': hashLocal,
      'sincronizadoOffline': sincronizadoOffline ? 1 : 0,
      'ajusteManual': ajusteManual ? 1 : 0,
      'justificativa': justificativa,
      'observacao': observacao,
      'nsr': nsr,
      'nsrLogico': nsrLogico,
      'ajusteStatus': ajusteStatus,
      'ajusteMotivoRejeicao': ajusteMotivoRejeicao,
      'aprovadoPor': aprovadoPor,
      'aprovadoEm': aprovadoEm?.toIso8601String(),
    };
  }

  /// Formato enviado para a API REST backend (/api/v1/pontos/sincronizar)
  Map<String, dynamic> toApiJson() {
    return {
      'idLocal': idLocal,
      'dataHoraDispositivo': dataHoraDispositivo.toUtc().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'precisaoGps': precisaoGps,
      'fotoUrl': fotoUrl,
      'hashLocal': hashLocal,
    };
  }

  factory RegistroPontoModel.fromJson(Map<String, dynamic> json) {
    DateTime parseData(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.parse(val.toString());
    }

    return RegistroPontoModel(
      idLocal: json['idLocal']?.toString() ?? json['id']?.toString() ?? const Uuid().v4(),
      colaboradorId: json['colaboradorId']?.toString(),
      dataHoraDispositivo: parseData(json['dataHoraDispositivo'] ?? json['dataHora']),
      dataHoraServidor: json['dataHoraServidor'] != null ? parseData(json['dataHoraServidor']) : null,
      tipoRegistro: json['tipoRegistro']?.toString() ?? 'ENTRADA',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      precisaoGps: (json['precisaoGps'] as num?)?.toDouble() ?? 0.0,
      fotoUrl: json['fotoUrl']?.toString(),
      hashLocal: json['hashLocal']?.toString() ?? json['hashIntegridade']?.toString(),
      sincronizadoOffline: (json['sincronizadoOffline'] == true || json['sincronizadoOffline'] == 1),
      ajusteManual: (json['ajusteManual'] == true || json['ajusteManual'] == 1),
      justificativa: json['justificativa']?.toString(),
      observacao: json['observacao']?.toString(),
      nsr: (json['nsr'] as num?)?.toInt(),
      nsrLogico: (json['nsrLogico'] as num?)?.toInt(),
      ajusteStatus: json['ajusteStatus']?.toString(),
      ajusteMotivoRejeicao: json['ajusteMotivoRejeicao']?.toString(),
      aprovadoPor: json['aprovadoPor']?.toString(),
      aprovadoEm: json['aprovadoEm'] != null ? parseData(json['aprovadoEm']) : null,
    );
  }
}
