# Chronos Pulse App • Suíte Integrada (Ponto & Almoxarifado)

<div align="center">

![Version](https://img.shields.io/badge/version-1.1.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2)
![License](https://img.shields.io/badge/license-MIT-green)

Front-end mobile e web unificado para o ecossistema **Chronos Pulse**:
- **Módulo CP Ponto**: Ponto eletrônico multi-tenant com autenticação JWT, ciclo de jornada inteligente, biometria/GPS e sincronização offline-first.
- **Módulo CP Estoque & Almoxarifado**: Gestão física e contábil de materiais, entradas com NFe/empenho, recálculo de Custo Médio Ponderado (PMP/MCASP) e requisições públicas.

</div>

---

## Sumário

- [Visão Geral e Funcionalidades](#visão-geral-e-funcionalidades)
- [Arquitetura Modular](#arquitetura-modular)
- [Autenticação e Multi-Tenant (JWT)](#autenticação-e-multi-tenant-jwt)
- [Ciclo Automático de Batidas](#ciclo-automático-de-batidas)
- [Compatibilidade Web e Mobile](#compatibilidade-web-e-mobile)
- [Pré-requisitos](#pré-requisitos)
- [Configuração da API](#configuração-da-api)
- [Executando a Aplicação](#executando-a-aplicação)
- [Credenciais de Teste](#credenciais-de-teste)
- [Dependências de Terceiros](#dependências-de-terceiros)
- [Licença](#licença)

---

## Visão Geral e Funcionalidades

- **Autenticação JWT por CPF/Senha**: Login integrado com extração segura de `colaboradorId`, `tenantId` e `role`.
- **Ciclo Automático de Jornada**: O aplicativo determina a sequência esperada (`ENTRADA` → `INTERVALO` → `RETORNO` → `SAIDA` → `ENTRADA`) sem exigir seleção manual.
- **Offline-First com Resiliência**: Os registros são persistidos localmente no banco SQLite / Web Storage antes do envio; caso a rede esteja indisponível, permanecem marcados para sincronização posterior.
- **Sincronização em Lote**: Botão de sincronização manual ou envio automático acumulado ao recuperar a conexão com o backend.
- **Biometria e GPS**: Validação biométrica no dispositivo (com bypass seguro em navegadores) e captura de coordenadas geográficas de alta precisão.
- **Layout Responsivo**: Interface adaptada com foco em Web (largura contida e centralizada para navegadores desktop) e telas móveis.

---

## Arquitetura Modular

O projeto segue arquitetura modular baseada em **Features** com separação clara de responsabilidades:

```
lib/
├── core/
│   ├── constants/       # Endpoints de Ponto, Estoque/Almoxarifado e Ping
│   ├── database/        # DatabaseHelper (SQLite nativo e Web Storage)
│   ├── hardware/        # HardwareService (Biometria local_auth e GPS)
│   └── network/         # DioClient com interceptor Bearer Token JWT
├── features/
│   ├── auth/            # Módulo de Autenticação e Sessão
│   │   ├── data/
│   │   └── presentation/
│   ├── ponto/           # Módulo CP Ponto
│   │   ├── data/        # DataSources, Modelos e Repositório
│   │   └── presentation/# Telas de Batida, Histórico e PontoProvider (Sensor & Auto-Sync)
│   ├── estoque/         # Módulo CP Estoque & Almoxarifado
│   │   ├── data/        # Modelos, DTOs, DataSource e Repositório
│   │   └── presentation/# Saldos, Métricas, Entradas NFe, Saídas e Requisições
│   └── navigation/      # Shell de Navegação Adaptativa (Web NavigationRail / Mobile Bar)
└── main.dart            # Inicialização com MultiProvider (Auth + Estoque + Ponto)
```

---

## Autenticação e Multi-Tenant (JWT)

Ao realizar o login via CPF e Senha:
1. A API retorna o token JWT `accessToken`, além da role e IDs de tenant e colaborador.
2. O `DioClient` injeta automaticamente o header `Authorization: Bearer <token>` em todas as requisições subsequentes.
3. Ao bater ponto, o backend extrai a identidade do colaborador e o tenant do próprio token, eliminando a necessidade de envio de dados sensíveis no corpo da requisição.

---

## Ciclo Automático de Batidas

O aplicativo calcula o próximo tipo de batida a partir do histórico do dia:

| Ordem | Tipo | Ação Exibida no Botão |
|---|---|---|
| 1ª Batida | `ENTRADA` | *Bater Entrada* |
| 2ª Batida | `INTERVALO` | *Bater Intervalo* |
| 3ª Batida | `RETORNO` | *Bater Retorno* |
| 4ª Batida | `SAIDA` | *Bater Saída* |
| 5ª+ Batida | `ENTRADA` | *Bater Entrada (Extra)* |

---

## Compatibilidade Web e Mobile

- **Web**:
  - Habilitado suporte a CORS no backend (`localhost:8080`).
  - Armazenamento em memória com cache para persistência durante a sessão.
  - Biometria ignorada com aprovação automática no browser.
  - Geolocalização consumida via API HTML5 do navegador.
- **Mobile (Android / iOS)**:
  - Persistência nativa via SQLite (`sqflite`).
  - Biometria física (digital / Face ID) via `local_auth`.
  - Captura de foto via câmera nativa (`camera`).

---

## Pré-requisitos

- **Flutter SDK**: 3.x+
- **Dart SDK**: 3.x+
- **Backend Chronos Pulse**: em execução em `http://localhost:8080`
- **Navegador Web** (Chrome / Edge / Firefox) ou Emulador / Dispositivo Android/iOS

---

## Configuração da API

O endereço da API é resolvido automaticamente em `lib/core/constants/api_constants.dart`:

| Plataforma | Endereço padrão |
|---|---|
| **Web** | `http://localhost:8080/api/v1` |
| **Android (Emulador)** | `http://10.0.2.2:8080/api/v1` |
| **Android (Dispositivo Físico)** | `http://<IP_DA_MAQUINA>:8080/api/v1` |
| **iOS / Desktop** | `http://localhost:8080/api/v1` |

---

## Executando a Aplicação

### Modo Web:
```bash
flutter run -d chrome
# ou para servidor web em porta específica:
flutter run -d web-server --web-port 3000
```
Acesse `http://localhost:3000` no seu navegador.

### Modo Android (Emulador ou Dispositivo Físico):
```bash
flutter run
```

---

## Credenciais de Teste

Utilize as contas criadas na carga inicial da base de dados:

| Perfil | CPF | Senha | Acesso |
|---|---|---|---|
| **Colaborador** | `12345678901` | `senha123` | Registro de ponto online/offline |
| **Gestor RH (Admin Empresa)** | `11111111111` | `admin123` | Gestão de colaboradores e ponto |
| **Admin Plataforma** | `00000000000` | `admin123` | Gestão de tenants |

---

## Dependências de Terceiros

| Biblioteca | Versão | Licença | Uso |
|---|---|---|---|
| [dio](https://github.com/cfug/dio) | ^5.7.0 | MIT | Cliente HTTP e Interceptors JWT |
| [provider](https://github.com/rrousselGit/provider) | ^6.1.2 | MIT | Gerenciamento de Estado |
| [local_auth](https://github.com/flutter/packages/tree/main/packages/local_auth) | ^2.3.0 | BSD 3-Clause | Autenticação Biométrica |
| [geolocator](https://github.com/Baseflow/flutter-geolocator) | ^13.0.0 | MIT | Captura de GPS |
| [camera](https://github.com/flutter/packages/tree/main/packages/camera) | ^0.12.0+2 | BSD 3-Clause | Câmera para validação facial no mobile |
| [sqflite](https://github.com/tekartik/sqflite) | ^2.4.0 | MIT | Banco de dados SQLite local offline |
| [sqflite_common_ffi_web](https://github.com/tekartik/sqflite) | ^0.4.0 | MIT | SQLite para Web |
| [intl](https://github.com/dart-lang/i18n) | ^0.20.0 | BSD 3-Clause | Formatação de data e hora em pt_BR |
| [uuid](https://github.com/Daegalus/dart-uuid) | ^4.5.1 | MIT | Geração de identificadores locais únicos |

---

## Licença

Copyright (c) 2026 Chronos Pulse. Distribuído sob a licença MIT.
