# Módulos (Gating do Menu)

O app reflete a **modularidade do SaaS** no cliente: o item de menu de cada módulo só aparece se a empresa o contratou (ou se o usuário é **Admin Plataforma/Suporte**, que têm acesso irrestrito a tudo).

## Getter `temModulo*` (UsuarioModel)

`lib/features/auth/data/models/usuario_model.dart`:

```dart
bool get temModuloPonto         => isGestorPlataforma || _temModulo('PONTO');
bool get temModuloRh            => isGestorPlataforma || _temModulo('RECURSOS_HUMANOS');
bool get temModuloEstoque       => isGestorPlataforma || _temModulo('ESTOQUE');
bool get temModuloCompras       => isGestorPlataforma || _temModulo('COMPRAS');
bool get temModuloLicitacoes    => isGestorPlataforma || _temModulo('LICITACOES');
bool get temModuloPatrimonio    => isGestorPlataforma || _temModulo('PATRIMONIO');
bool get temModuloFrota         => isGestorPlataforma || _temModulo('FROTA');
bool get temModuloProtocolo     => isGestorPlataforma || _temModulo('PROTOCOLO');
bool get temModuloTransparencia => isGestorPlataforma || _temModulo('TRANSPARENCIA');
```

- `isGestorPlataforma` (`ADMIN_PLATAFORMA`, `SUPORTE_N1`, `SUPORTE_N2`) **sempre** vê todos os módulos — é o acesso irrestrito do Admin Plataforma.
- `isAdminOrRh` (`ADMIN_PLATAFORMA`, `ADMIN_EMPRESA`, `GESTOR_RH`) libera ações de gestão (ex.: tela Colaboradores).
- A lista `modulos` vem do login/refresh/perfil e fica persistida (chave `chronos_modulos`).

## Montagem do Menu (web/desktop: `NavigationRail` à esquerda; mobile: `NavigationBar` inferior)

Centralizado em `lib/core/router/app_router.dart`:

- `AppRouter.painelOrdem` — ordem fixa dos 10 destinos.
- `AppRouter.podeModuloPainel(usuario, slug)` — gating por rota.
- `MainShell` (`lib/features/navigation/presentation/screens/main_shell.dart`) monta a lista escondendo/removendo itens não liberados; o índice selecionado é ajustado com `posicaoAtual`/`safeIndex` para nunca apontar para item removido.

| Ordem | Item (`slug`) | Condição |
|---|---|---|
| 1 | Ponto | `temModuloPonto` |
| 2 | Colaboradores | `isAdminOrRh && temModuloRh` |
| 3 | Estoque | `temModuloEstoque` |
| 4 | Compras | `temModuloCompras` |
| 5 | Licitações | `temModuloLicitacoes` |
| 6 | Patrimônio | `temModuloPatrimonio` |
| 7 | Frota | `temModuloFrota` |
| 8 | Protocolo | `temModuloProtocolo` |
| 9 | Transparência | `temModuloTransparencia` |
| 10 | Privacidade (LGPD) | sempre (`true`) |

> Rotas de módulos não contratados redirecionam para a **primeira rota acessível** (`primeiraRotaPainel`). Colaboradores só veem "Colaboradores" se tiverem perfil de gestão **e** o módulo RH ativo.

## Painel Admin Plataforma → Módulos

`AdminShell` exibe o item **Módulos** (`AdminModulosScreen`), que lista as empresas e permite **ativar/desativar** módulos, chamando:

- `GET /api/v1/admin/modulos` → catálogo
- `GET /api/v1/admin/empresas/{tenantId}/modulos` → ativos da empresa
- `PUT /api/v1/admin/empresas/{tenantId}/modulos` → salvar seleção

Estruturado em `features/admin/`: métodos `listarCatalogoModulos`, `listarModulosEmpresa` e `atualizarModulosEmpresa` (datasource → repository → `AdminProvider`).

> Após alterar módulos, a empresa precisa **refazer o login** (ou aguardar o refresh) para que o app receba a nova lista.

## Adicionar um Novo Módulo no App

1. **Backend**: criar o módulo e ativá-lo para a empresa (ver `docs/modulos-saas.md` no backend).
2. **Modelo**: adicionar `bool get temModuloNovo => isGestorPlataforma || _temModulo('NOVO_MODULO');` em `usuario_model.dart`.
3. **Feature**: criar a pasta `features/novo_modulo/` seguindo o padrão patrimônio (datasource → models → repository → provider → screens/dialogs).
4. **main.dart**: registrar o provider no `MultiProvider`.
5. **Rotas/menu**: adicionar o `slug` em `painelOrdem` (e, se necessário, criar a branch do `StatefulShellRoute`), a condição em `podeModuloPainel` e o metadado (label/ícones) em `MainShell._metadados`.
6. Rodar `flutter analyze` e `flutter test`.