# Chronos Pulse App

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2)
![License](https://img.shields.io/badge/license-MIT-green)

Front-end mobile e web para o sistema Chronos Pulse — registro de ponto com suporte a biometria, GPS e sincronização offline.

</div>

---

## Índice

- [Funcionalidades](#funcionalidades)
- [Arquitetura](#arquitetura)
- [Pré-requisitos](#pré-requisitos)
- [Configuração](#configuração)
- [Executando](#executando)
- [Dependências de Terceiros](#dependências-de-terceiros)
- [Licença](#licença)

---

## Funcionalidades

- **Autenticação biométrica** — valida digital ou face antes de registrar o ponto
- **Captura de GPS** — registra latitude, longitude e precisão no momento da batida
- **Persistência offline** — salva registros localmente via SQLite quando sem conexão
- **Sincronização com o backend** — envia lote de registros para `POST /api/v1/pontos/sincronizar` ao recuperar conexão
- **Histórico do dia** — exibe os registros realizados na sessão atual

---

## Arquitetura

O projeto segue a separação por **features** com camadas de dados e apresentação isoladas.

```
lib/
├── core/
│   ├── constants/       # Configuração de endpoints (ApiConstants)
│   ├── database/        # DatabaseHelper — SQLite local
│   ├── hardware/        # HardwareService — biometria e GPS
│   └── network/         # DioClient — cliente HTTP
└── features/
    └── ponto/
        ├── data/
        │   ├── datasources/   # PontoLocalDataSource, PontoRemoteDataSource
        │   ├── models/        # RegistroPontoModel
        │   └── repositories/  # PontoRepository
        └── presentation/
            └── screens/       # HomePontoScreen
```

---

## Pré-requisitos

- Flutter 3.x
- Dart 3.x
- Android SDK (para build Android) ou Edge/Chrome (para build Web
- Backend [chronos-pulse](../chronos-pulse) em execução na porta `8080`

---

## Configuração

O endereço da API é resolvido automaticamente por plataforma em `lib/core/constants/api_constants.dart`:

| Plataforma | Endereço padrão |
|---|---|
| Web | `http://localhost:8080/api/v1` |
| Android Emulador | `http://10.0.2.2:8080/api/v1` |
| Android Dispositivo físico | `http://<IP_DA_MAQUINA>:8080/api/v1` |
| iOS / Desktop | `http://localhost:8080/api/v1` |

Para dispositivo físico, substitua `<IP_DA_MAQUINA>` pelo IP local da máquina que executa o backend. O celular e o computador devem estar na mesma rede Wi-Fi.

---

## Executando

**Android (dispositivo físico):**

```bash
flutter run -d <DEVICE_ID>
```

**Web:**

```bash
flutter run -d web-server --web-port 3000
```

Depois abra `http://localhost:3000` no navegador.

Para listar os dispositivos disponíveis:

```bash
flutter devices
```

---

## Fluxo de Registro de Ponto

Cada jornada completa exige 4 batidas nesta ordem:

| Sequência | Tipo | Descrição |
|---|---|---|
| 1 | `ENTRADA` | Início do expediente |
| 2 | `PAUSA_INICIO` | Saída para intervalo |
| 3 | `PAUSA_FIM` | Retorno do intervalo |
| 4 | `SAIDA` | Fim do expediente |

Ao pressionar o botão de confirmar:
1. Biometria é solicitada ao sistema operacional
2. GPS é capturado com precisão alta
3. Registro é salvo localmente no SQLite
4. Sincronização com o backend é tentada imediatamente
5. Em caso de falha de rede, o registro permanece pendente para sincronização posterior

---

## Dependências de Terceiros

| Biblioteca | Versão | Licença | Uso |
|---|---|---|---|
| [dio](https://github.com/cfug/dio) | ^5.7.0 | MIT | Cliente HTTP |
| [local_auth](https://github.com/flutter/packages/tree/main/packages/local_auth) | ^2.3.0 | BSD 3-Clause | Autenticação biométrica |
| [geolocator](https://github.com/Baseflow/flutter-geolocator) | ^13.0.0 | MIT | Captura de GPS |
| [camera](https://github.com/flutter/packages/tree/main/packages/camera) | ^0.12.0+2 | BSD 3-Clause | Acesso à câmera |
| [sqflite](https://github.com/tekartik/sqflite) | ^2.4.0 | MIT | Persistência SQLite nativa |
| [sqflite_common_ffi_web](https://github.com/tekartik/sqflite) | ^0.4.0 | MIT | Persistência SQLite na Web |
| [provider](https://github.com/rrousselGit/provider) | ^6.1.2 | MIT | Gerenciamento de estado |
| [uuid](https://github.com/Daegalus/dart-uuid) | ^4.5.1 | MIT | Geração de IDs locais |
| [intl](https://github.com/dart-lang/i18n) | ^0.20.0 | BSD 3-Clause | Formatação de datas |
| [path](https://github.com/dart-lang/path) | ^1.9.0 | BSD 3-Clause | Resolução de caminhos de arquivo |

---

## Licença

Copyright (c) 2025 Chronos Pulse

Distribuído sob a licença MIT. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.
