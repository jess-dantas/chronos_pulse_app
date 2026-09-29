# Chronos Pulse App

<div align="center">

![Version](https://img.shields.io/badge/version-1.2.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2)
![Tests](https://img.shields.io/badge/tests-252%20verdes-brightgreen)
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

O painel **Admin Plataforma** (`AdminNavigationScreen`) também ganhou a tela **Módulos**, usada para ativar/desativar módulos por empresa. **Privacidade & LGPD** (painel do usuário) e os ajustes de perfil ficam sempre disponíveis para usuários autenticados — o Administrator (Admin Plataforma) **não** possui aba de Privacidade.

---

## Stack

- **Framework:** Flutter 3.x · Dart 3.x · `flutter_localizations` (app em pt-BR)
- **Roteamento:** `go_router` (URLs limpas, sem `#` no web)
- **Estado:** `provider`
- **HTTP:** `dio`
- **Persistência offline:** `sqflite` (SQLite) · `shared_preferences` · `flutter_secure_storage` (sessão/perfil)
- **Hardware:** `local_auth` (biometria) · `geolocator` (GPS) · `camera` · `mobile_scanner` (leitura QR)
- **Documentos:** `pdf` + `printing` (comprovante e espelho de ponto) · `file_picker`
- **2FA:** `qr_flutter` (QR Code do setup TOTP)
- **Utilitários:** `intl` (datas pt-BR) · `uuid` · `cupertino_icons`
- **Qualidade:** `flutter_lints` · `flutter_test` · `sqflite_common_ffi` (testes reais de migração SQLite no host)

---

## Documentação

- [`docs/infra.md`](docs/infra.md) — Rotas, subida do app, configuração da API e testes
- [`docs/arquitetura.md`](docs/arquitetura.md) — Estrutura modular de features
- [`docs/modulos.md`](docs/modulos.md) — Gating do menu, getters `temModulo*` e como adicionar um novo módulo
- [`docs/api.md`](docs/api.md) — Endpoints consumidos pelo app
- [`docs/autenticacao.md`](docs/autenticacao.md) — Sessão JWT, refresh e persistência dos módulos

## Licença

MIT — consulte [LICENSE](LICENSE).
