# Módulos (Gating do Menu)

O app reflete a **modularidade do SaaS** no cliente: o item de menu de cada módulo só aparece se a empresa o contratou.

## Getter `temModulo*` (UsuarioModel)

`lib/features/auth/data/models/usuario_model.dart`:

```dart
bool get temModuloPonto     => isGestorPlataforma || modulos.contains('PONTO');
bool get temModuloRh        => isGestorPlataforma || modulos.contains('RECURSOS_HUMANOS');
bool get temModuloEstoque   => isGestorPlataforma || modulos.contains('ESTOQUE');
bool get temModuloPatrimonio=> isGestorPlataforma || modulos.contains('PATRIMONIO');
bool get temModuloFrota     => isGestorPlataforma || modulos.contains('FROTA');
bool get temModuloProtocolo => isGestorPlataforma || modulos.contains('PROTOCOLO');
```

- `isGestorPlataforma` (Admin/Suporte) **sempre** vê todos os módulos.
- A lista `modulos` vem do login/refresh/perfil e fica persistida (chave `chronos_modulos`).

## Montagem do Menu (`main_navigation_screen.dart`)

A ordem é fixa; cada item é adicionado sob condição:

| Ordem | Item | Condição |
|---|---|---|
| 1 | Ponto | `usuario.temModuloPonto` |
| 2 | Colaboradores | `usuario.isAdminOrRh && usuario.temModuloRh` |
| 3 | Estoque | `usuario.temModuloEstoque` |
| 4 | Patrimônio | `usuario.temModuloPatrimonio` |
| 5 | Frota | `usuario.temModuloFrota` |
| 6 | Protocolo | `usuario.temModuloProtocolo` |

> Colaboradores só veem "Colaboradores" se tiverem perfil de gestão **e** o módulo RH ativo. O índice selecionado é ajustado com `safeIndex` para nunca apontar para item removido.

## Painel Admin Plataforma → Módulos

`AdminNavigationScreen` exibe o item **Módulos** (`AdminModulosScreen`), que lista as empresas e permite **ativar/desativar** módulos, chamando:

- `GET /api/v1/admin/modulos` → catálogo
- `GET /api/v1/admin/empresas/{tenantId}/modulos` → ativos da empresa
- `PUT /api/v1/admin/empresas/{tenantId}/modulos` → salvar seleção

Estruturado em `features/admin/`: métodos `listarCatalogoModulos`, `listarModulosEmpresa` e `atualizarModulosEmpresa` (datasource → repository → `AdminProvider`).

> Após alterar módulos, a empresa precisa **refazer o login** (ou aguardar o refresh) para que o app receba a nova lista.

## Adicionar um Novo Módulo no App

1. **Backend**: criar o módulo e ativá-lo para a empresa (ver `docs/modulos-saas.md` no backend).
2. **Modelo**: adicionar `bool get temModuloNovo => isGestorPlataforma || modulos.contains('NOVO_MODULO');` em `usuario_model.dart`.
3. **Feature**: criar a pasta `features/novo_modulo/` seguindo o padrão patrimonio (datasource → models → repository → provider → screens/dialogs).
4. **main.dart**: registrar o provider no `MultiProvider`.
5. **Menu**: adicionar o `_NavigationItem` com a condição `usuario.temModuloNovo` em `main_navigation_screen.dart`.
6. Rodar `flutter analyze` e `flutter build web`.