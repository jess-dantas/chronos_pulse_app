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
  });

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
    );
  }
}
