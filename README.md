# Chronos Pulse App

<div align="center">

![Version](https://img.shields.io/badge/version-1.2.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2)
![License](https://img.shields.io/badge/license-MIT-green)

Front-end mobile e web unificado para o ecossistema **Chronos Pulse**:
- **Módulo Auth**: Login, cadastro público de empresas e persistência de sessão com refresh token.
- **Módulo CP Ponto**: Ponto eletrônico multi-tenant com autenticação JWT, ciclo de jornada inteligente, biometria/GPS e sincronização offline-first.
- **Módulo CP Estoque & Almoxarifado**: Gestão física e contábil de materiais, entradas com NFe/empenho, recálculo de Custo Médio Ponderado (PMP/MCASP) e requisições públicas.
- **Módulo Colaborador**: CRUD completo de colaboradores (listar, cadastrar, editar, excluir) com controle de acesso ao estoque.

</div>

---

## Sumário

- [Visão Geral e Funcionalidades](#visão-geral-e-funcionalidades)
- [Arquitetura Modular](#arquitetura-modular)
- [Autenticação e Sessão Persistente](#autenticação-e-sessão-persistente)
- [Cadastro Público de Empresas](#cadastro-público-de-empresas)
- [CRUD Completo de Colaboradores](#crud-completo-de-colaboradores)
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

- **Página Landing (Landing Page)**: Tela inicial pública com apresentação da plataforma e botão "Cadastrar Empresa" no hero e no CTA.
- **Cadastro Público de Empresas**: Formulário completo (CNPJ, Razão Social, Nome do Admin, CPF, Celular, Email, Senha) que cria tenant + admin + colaborador em uma chamada à API.
- **Login por CPF/Senha**: Campos iniciam vazios para evitar preenchimento automático indesejado. Suporte a alternância de tema (Dark/Light Mode).
- **Persistência de Sessão**: Tokens JWT (access + refresh) armazenados em `shared_preferences`; sessão restaurada automaticamente ao reabrir o app via `tryRestoreSession()`.
- **Refresh Token**: Renovação automática do access token ao iniciar o app usando o refresh token armazenado.
- **Ciclo Automático de Jornada**: Sequência inteligente (`ENTRADA` → `INTERVALO` → `RETORNO` → `SAIDA` → `ENTRADA`) sem seleção manual.
- **CRUD Completo de Colaboradores**:
  - **Listar**: Cards com dados, cargo, departamento e badge de acesso ao estoque.
  - **Cadastrar**: Formulário completo com campos obrigatórios e validação.
  - **Editar**: Diálogo com preenchimento automático dos dados atuais, toggle de acesso ao estoque.
  - **Excluir**: Confirmação antes de desativar (soft delete).
- **Espelho de Ponto & Exportação PDF**: Consulta mensal do demonstrativo de batidas com exportação formatada segundo Portaria MTP nº 671/2021.
- **Ajuste Manual com Justificativa Obrigatória**: 8 justificativas padronizadas para correção de horários.
- **Offline-First com Resiliência**: Registros persistidos localmente antes do envio; sincronização automática ao recuperar conexão.
- **Sincronização em Lote**: Envio manual ou automático de batidas acumuladas.
- **Biometria e GPS**: Validação biométrica (bypass em web) e captura de coordenadas geográficas.
- **Layout Responsivo**: Interface adaptada para web (centralizada para desktop) e telas móveis.

---

## Arquitetura Modular

O projeto segue arquitetura modular baseada em **Features** com separação clara de responsabilidades:

```
lib/
├── core/
│   ├── constants/       # Endpoints de Auth, Ponto, Estoque/Almoxarifado e Ping
│   ├── database/        # DatabaseHelper (SQLite nativo e Web Storage)
│   ├── hardware/        # HardwareService (Biometria local_auth e GPS)
│   └── network/         # DioClient com interceptor Bearer Token JWT
├── features/
│   ├── auth/            # Módulo de Autenticação e Sessão
│   │   ├── data/
│   │   │   ├── datasources/auth_remote_datasource.dart  # Login, cadastrar, refresh, me
│   │   │   └── repositories/auth_repository.dart         # Camada de domínio
│   │   └── presentation/
│   │       ├── providers/auth_provider.dart               # Gerenciamento de estado + sessão
│   │       └── screens/
│   │           ├── login_screen.dart                      # Tela de login
│   │           ├── cadastrar_empresa_screen.dart          # Cadastro público de empresa
│   │           └── auth_wrapper.dart                      # Roteamento baseado em sessão
│   ├── colaborador/    # Módulo de Gestão de Colaboradores
│   │   ├── data/
│   │   │   ├── datasources/colaborador_remote_datasource.dart  # CRUD completo
│   │   │   └── repositories/colaborador_repository.dart
│   │   └── presentation/
│   │       ├── providers/colaborador_provider.dart        # CRUD + filtros
│   │       └── screens/
│   │           ├── colaboradores_screen.dart              # Lista com cards + editar/excluir
│   │           ├── cadastrar_colaborador_screen.dart      # Formulário de cadastro
│   │           └── editar_colaborador_dialog.dart         # Diálogo de edição
│   ├── ponto/           # Módulo CP Ponto
│   │   ├── data/        # DataSources, Modelos e Repositório
│   │   └── presentation/# Telas de Batida, Histórico e PontoProvider
│   ├── estoque/         # Módulo CP Estoque & Almoxarifado
│   │   ├── data/        # Modelos, DTOs, DataSource e Repositório
│   │   └── presentation/# Saldos, Métricas, Entradas NFe, Saídas e Requisições
│   ├── landing/         # Página Landing (Tela Pública)
│   │   └── presentation/
│   │       └── screens/landing_screen.dart                # Hero + CTA
│   └── navigation/      # Shell de Navegação Adaptativa (Web NavigationRail / Mobile Bar)
└── main.dart            # Inicialização com MultiProvider + restauração de sessão
```

---

## Autenticação e Sessão Persistente

1. **Login**: O usuário informa CPF + senha → a API retorna `accessToken`, `refreshToken`, `role`, `cpcId`, `tenantId`, etc.
2. **Armazenamento**: Ambos os tokens são salvos em `shared_preferences`.
3. **Restauração**: Ao abrir o app, `AuthProvider.tryRestoreSession()` tenta usar o `refreshToken` para obter um novo `accessToken` válido.
4. **Requisições**: O `DioClient` injeta automaticamente `Authorization: Bearer <accessToken>` em todas as chamadas.
5. **Logout**: Limpa tokens do `shared_preferences` e redireciona para o login.
6. **Tempo de Sessão**: Monitoramento de inatividade (15 min) rearmado a cada atividade (toque, teclado e retomada do app) e limite absoluto de 8 horas desde o login; ao expirar, a sessão é encerrada e o usuário é informado na tela de login.

---

## Cadastro Público de Empresas

A tela `cadastrar_empresa_screen.dart` permite que qualquer pessoa cadastre sua empresa na plataforma:

1. Preenche CNPJ, Razão Social, Nome do Responsável, CPF, Celular, Email e Senha.
2. O backend cria automaticamente: **Tenant** + **CpcUsuario** (ADMIN_EMPRESA) + **Colaborador**.
3. O usuário é logado automaticamente (tokens retornados).
4. Botão "Cadastrar Empresa" disponível na Landing Page e no menu.

---

## CRUD Completo de Colaboradores

| Ação | Endpoint | Tela |
|---|---|---|
| **Listar** | `GET /api/v1/colaboradores` | `colaboradores_screen.dart` |
| **Cadastrar** | `POST /api/v1/colaboradores` | `cadastrar_colaborador_screen.dart` |
| **Editar** | `PUT /api/v1/colaboradores/{id}` | `editar_colaborador_dialog.dart` |
| **Excluir** | `DELETE /api/v1/colaboradores/{id}` | Confirmação no `colaboradores_screen.dart` |

Os botões de editar (ícone azul) e excluir (ícone vermelho) aparecem no canto inferior direito de cada card de colaborador. A edição abre um diálogo com os campos preenchidos e um toggle para acesso ao estoque. A exclusão exibe um `AlertDialog` de confirmação antes de desativar.

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
  - Suporte a CORS no backend.
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

| Perfil | CPF | Senha | Acesso |
|---|---|---|---|
| **Admin Empresa** | `11111111111` | `admin123` | Gestão de colaboradores e ponto |
| **Gestor RH** | `22222222222` | `admin123` | Gestão de colaboradores e ponto |
| **Colaborador** | `12345678901` | `senha123` | Registro de ponto online/offline |
| **Colaborador Almoxarife** | `98765432100` | `senha123` | Ponto + Estoque |

---

## Dependências de Terceiros

| Biblioteca | Versão | Licença | Uso |
|---|---|---|---|
| [dio](https://github.com/cfug/dio) | ^5.7.0 | MIT | Cliente HTTP e Interceptors JWT |
| [provider](https://github.com/rrousselGit/provider) | ^6.1.2 | MIT | Gerenciamento de Estado |
| [shared_preferences](https://github.com/flutter/packages/tree/main/packages/shared_preferences) | ^2.5.0 | BSD 3-Clause | Persistência de tokens JWT |
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
