# Chronos Pulse App

<div align="center">

![Version](https://img.shields.io/badge/version-1.2.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2)
![Tests](https://img.shields.io/badge/tests-127%20verdes-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)

Front-end **web e mobile** unificado do ecossistema **Chronos Pulse** — SaaS multi-tenant de gestão pública. O menu é **dinâmico**: cada item aparece conforme os módulos contratados pela empresa (logada no login/perfil do backend).

</div>

---

## Módulos Acessíveis

| Módulo | Código | Tela |
|---|---|---|
| Ponto Eletrônico | `PONTO` | `HomePontoScreen` |
| Colaboradores (RH) | `RECURSOS_HUMANOS` | `ColaboradoresScreen` |
| Estoque & Almoxarifado | `ESTOQUE` | `EstoqueHomeScreen` |
| Compras & Fornecedores | `COMPRAS` | `ComprasHomeScreen` |
| Licitações & Contratações | `LICITACOES` | `LicitacoesHomeScreen` |
| Patrimônio Público | `PATRIMONIO` | `PatrimonioHomeScreen` |
| Gestão de Frota | `FROTA` | `FrotaHomeScreen` |
| Protocolo Eletrônico | `PROTOCOLO` | `ProtocoloHomeScreen` |
| Portal da Transparência & BI (LC 131/2009) | `TRANSPARENCIA` | `TransparenciaHomeScreen` |

O painel **Admin Plataforma** (`AdminNavigationScreen`) também ganhou a tela **Módulos**, usada para ativar/desativar módulos por empresa. **Privacidade & LGPD** e os ajustes de perfil ficam sempre disponíveis para usuários autenticados.

---

## Rotas (Flutter Web)

Navegação com **go_router** e URLs limpas em `path` (sem `#`). Áreas protegidas
redirecionam para a landing quando o usuário está deslogado; rotas de módulos
não contratados caem no primeiro módulo ativo do usuário.

| Rota | Tela |
|---|---|
| `/` | `LandingScreen` |
| `/login` | `LoginScreen` |
| `/cadastro` | `CadastrarEmpresaScreen` |
| `/recuperar-senha` | `RecuperarSenhaScreen` |
| `/painel/ponto` … `/painel/privacidade` | Módulos do painel (`MainShell`) |
| `/admin/dashboard` … `/admin/privacidade` | Área administrativa (`AdminShell`) |

Configurações centrais em `lib/core/router/app_router.dart` (ordem dos módulos,
permissões por rota e redirects) e os shells em
`lib/features/navigation/presentation/screens/`.

---

## Como subir o app

### Pré-requisitos

- **Flutter 3.x** com **Dart 3.x** instalados (`flutter doctor` sem pendências críticas)
- **Backend Chronos Pulse no ar** (seguir o README do projeto `chronos-pulse` — subida com/sem Docker)
- Para **web**: navegador Chrome (ou usar `web-server`)
- Para **Android**: emulador ou dispositivo físico com depuração habilitada

### Passo a passo

```bash
# 1. Instale as dependências
flutter pub get

# 2. (Recomendado) Valide o código antes de subir
flutter analyze

# 3. Suba o app
## Web (abre no Chrome automático)
flutter run -d chrome
## Web (servidor em porta específica, ex.: porta 3000)
flutter run -d web-server --web-port 3000
## Android (emulador ou dispositivo físico)
flutter run

# 4. Corra os testes (127 testes)
flutter test

# 5. Build de produção (web)
flutter build web
```

Para **web em produção** informe a URL da API em tempo de compilação (reproduzível):

```bash
flutter run -d web-server --web-port 3000 \
  --dart-define=API_URL=https://chronos-pulse.onrender.com/api/v1
flutter build web --dart-define=API_URL=https://chronos-pulse.onrender.com/api/v1
```

### Configuração da API

Resolução automática em `lib/core/constants/api_constants.dart` (prioridade: `--dart-define=API_URL` > release/web/plataforma):

| Plataforma | Endereço padrão |
|---|---|
| API via `--dart-define=API_URL` | sobrescreve tudo (recomendado em produção) |
| Release (web/móvel) sem `API_URL` | `https://chronos-pulse.onrender.com/api/v1` |
| Web (debug) | `http://localhost:8080/api/v1` |
| Android (emulador) | `http://10.0.2.2:8080/api/v1` |
| Android (dispositivo físico) | `http://<IP_DA_MAQUINA>:8080/api/v1` |
| iOS / Desktop | `http://localhost:8080/api/v1` |

> No emulador Android a API resolve em `10.0.2.2`; em dispositivo físico use o IP local da máquina
> (ex.: `--dart-define=API_URL=http://192.168.0.10:8080/api/v1`).

---

## Credenciais de Teste (tenant de demonstração com 9 módulos)

> As credenciais de acesso **privilegiado** (fundador da empresa e Admin Plataforma)
> **não ficam no repositório** — são entregues fora dos projetos (ver seção de acessos
> do time / gestor de segredos).

| Perfil | CPF | Senha |
|---|---|---|
| Admin Empresa | `11111111111` | `admin123` |
| Gestor RH | `22222222222` | `admin123` |
| Colaborador | `12345678901` | `senha123` |
| Colaborador Almoxarife | `98765432100` | `senha123` |

---

## Documentação

- [`docs/arquitetura.md`](docs/arquitetura.md) — Estrutura modular de features
- [`docs/autenticacao.md`](docs/autenticacao.md) — Sessão JWT, refresh e persistência dos módulos
- [`docs/modulos.md`](docs/modulos.md) — Gating do menu, getters `temModulo*` e como adicionar um novo módulo
- [`docs/api.md`](docs/api.md) — Endpoints consumidos pelo app

---

## Licença

MIT — consulte [LICENSE](LICENSE).