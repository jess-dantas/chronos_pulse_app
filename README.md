# Chronos Pulse App

<div align="center">

![Version](https://img.shields.io/badge/version-1.2.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2)
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
| Patrimônio Público | `PATRIMONIO` | `PatrimonioHomeScreen` |
| Gestão de Frota | `FROTA` | `FrotaHomeScreen` |
| Protocolo Eletrônico | `PROTOCOLO` | `ProtocoloHomeScreen` |

O painel **Admin Plataforma** (`AdminNavigationScreen`) também ganhou a tela **Módulos**, usada para ativar/desativar módulos por empresa.

---

## Início Rápido

```bash
# Web (com o backend em http://localhost:8080)
flutter run -d chrome
# ou servidor web em porta específica
flutter run -d web-server --web-port 3000

# Android (emulador ou dispositivo físico)
flutter run

# Análise estática e build de produção web
flutter analyze
flutter build web
```

### Configuração da API

Resolução automática em `lib/core/constants/api_constants.dart`:

| Plataforma | Endereço padrão |
|---|---|
| Web | `http://localhost:8080/api/v1` |
| Android (emulador) | `http://10.0.2.2:8080/api/v1` |
| Android (dispositivo físico) | `http://<IP_DA_MAQUINA>:8080/api/v1` |
| iOS / Desktop | `http://localhost:8080/api/v1` |

---

## Credenciais de Teste (tenant de demonstração com 6 módulos)

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