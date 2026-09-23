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

- `AppRouter.painelOrdem` — ordem fixa dos 11 destinos (`ponto`, `aprovacao-ajustes`, `colaboradores`, `estoque`, `compras`, `licitacoes`, `patrimonio`, `frota`, `protocolo`, `transparencia`, `privacidade`).
- `AppRouter.podeModuloPainel(usuario, slug)` — gating por rota.
- `MainShell` (`lib/features/navigation/presentation/screens/main_shell.dart`) monta a lista escondendo/removendo itens não liberados; o índice selecionado é ajustado com `posicaoAtual`/`safeIndex` para nunca apontar para item removido. Ícones do rail em tamanho **20** e labels **11px** (mais compactos). O **bloco de perfil + logout** ficam no **rodapé** do `NavigationRail` (desktop) ou na barra de conta abaixo da `NavigationBar` (narrow); tocar no perfil navega para **`/perfil`** (`context.push('/perfil')`), no mobile → `Navigator.push` para a mesma tela. Mesma disposição no `AdminShell`.

| Ordem | Item (`slug`) | Condição (`podeModuloPainel`) |
|---|---|---|
| 1 | Ponto | (`isAdminOrRh` ∥ `isColaborador`) ∧ módulo `PONTO` |
| 2 | Aprovação Ajustes | `isAdminOrRh` ∧ módulo `PONTO` |
| 3 | Colaboradores | `isAdminOrRh` ∧ módulo `RECURSOS_HUMANOS` |
| 4 | Estoque | `temAcessoEstoque` ∧ módulo `ESTOQUE` |
| 5 | Compras | `temAcessoEstoque` ∧ módulo `COMPRAS` |
| 6 | Licitações | `temAcessoEstoque` ∧ módulo `LICITACOES` |
| 7 | Patrimônio | (`isAdminOrRh` ∥ `isColaborador`) ∧ módulo `PATRIMONIO` |
| 8 | Frota | (`isAdminOrRh` ∥ `isColaborador`) ∧ módulo `FROTA` |
| 9 | Protocolo | (`isAdminOrRh` ∥ `isColaborador`) ∧ módulo `PROTOCOLO` |
| 10 | Transparência | (`isAdminOrRh` ∥ `isColaborador` ∥ `acessoEstoque`) ∧ módulo `TRANSPARENCIA` |
| 11 | Privacidade (LGPD) | sempre (`true`) |

> **Perfil / titularidade:** o bloco de perfil no rodapé do rail abre **`/perfil`** (rota própria, fora do `painelOrdem`); o redirect do `AppRouter` usa `location.startsWith('/perfil')` — autenticado → `null` (admin root ou usuário), `/perfil/titularidade` exige `isAdminEmpresa`. Não há tela própria de histórico — datas de admissão/desligamento já vêm no payload do colaborador (`data_admissao`/`data_desligamento`/`ativo`).

> O gating é **role + módulo associado ao usuário** (`usuario_modulo`), alinhado ao backend/`rbac.md` — **não** há herança automática por papel no cliente: um colaborador com o módulo `ESTOQUE` ativo no tenant só vê Estoque/Compras/Licitações se tiver `acessoEstoque` (almoxarife); `SUPORTE_N1/N2` não recebe módulos do painel de negócio (apenas Privacidade); o **Admin Empresa recebe todos os módulos contratados associados no 1º consentimento LGPD** (backend). Rotas de módulos não liberados redirecionam para a **primeira rota acessível** (`primeiraRotaPainel`).

> **Admin Plataforma:** `AppRouter.adminOrdem` (`dashboard`, `leads`, `empresas`, `contratos`, `modulos`, `senha`, `seguranca`) **não** inclui `privacidade` — o Administrator não vê aba de Privacidade no `AdminShell` (escopo LGPD dele é sem CPF/tenant; o `ConsentimentoGate` também fica de fora).

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