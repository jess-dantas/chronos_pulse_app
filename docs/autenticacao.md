# Autenticação e Sessão

Fluxo baseado em `AuthProvider` (`features/auth/`) e `DioClient` (`core/network/`).

## Login

1. `POST /api/v1/auth/login` (CPF + senha).
2. O backend retorna `accessToken`, `refreshToken`, `role`, `tenantId`, `acessoEstoque` e **`modulos`** (`List<String>` com os códigos dos módulos ativos da empresa).
3. `AuthProvider._saveSession()` grava os tokens, o usuário **e a lista de módulos** em `shared_preferences`.

> O mesmo vale para `cadastrar-empresa` (login automático) e `refresh`.

## Restauração (`tryRestoreSession`)

Ao abrir o app, o provider:

1. Tenta restaurar os dados salvos (tokens + usuário + módulos).
2. Se houver `refreshToken`, chama `POST /api/v1/auth/refresh` para obter um novo `accessToken`.
3. Atualiza o usuário (incluindo os **módulos** retornados pelo refresh, que podem ter mudado no backend) e persiste novamente.
4. Em falha → `logout()` silencioso.

## Requisições autenticadas

`DioClient` injeta automaticamente `Authorization: Bearer <accessToken>` via interceptor. Falha de `401` dispara o refresh antes de repetir a chamada.

## Logout

`_clearSession()` remove tokens, usuário e módulos do `shared_preferences` e retorna à `LandingScreen`.

## Persistência (`shared_preferences`)

| Chave | Conteúdo |
|---|---|
| `chronos_access_token` | Access token |
| `chronos_refresh_token` | Refresh token |
| `chronos_usuario` | Usuário (JSON) |
| `chronos_modulos` | Lista de códigos de módulos ativos (salva/restaurada junto da sessão) |

## Tempo de sessão

- **Idle**: 15 minutos sem atividade (teclado, toque, retomada do app) → logout com aviso.
- **Absoluta**: 8 horas desde o login (garantida pelo backend na validade do refresh token).

## Módulos na sessão

A lista de módulos persiste para que o **menu seja montado de forma reativa** logo após o login/restauração, sem chamadas extras. A fonte de verdade do acesso, porém, é o backend (`ModuloInterceptor`) — o app apenas esconde itens não contratados.