# Autenticação e Sessão

Fluxo baseado em `AuthProvider` (`features/auth/`) e `DioClient` (`core/network/`).

## Login

1. `POST /api/v1/auth/login` (CPF + senha).
2. O backend retorna `accessToken`, `refreshToken`, `role`, `tenantId`, `acessoEstoque` e **`modulos`** (`List<String>` com os códigos dos módulos ativos da empresa).
3. `AuthProvider._saveSession()` grava os tokens no **`SessionStorage`** (`flutter_secure_storage` no Android/iOS — Keystore/Keychain; fallback em SharedPreferences na Web) e o usuário/`modulos` em `shared_preferences`.

> O mesmo vale para `cadastrar-empresa` (login automático) e `refresh`.

## Restauração (`tryRestoreSession`)

Ao abrir o app, o provider:

1. Tenta restaurar os dados salvos (tokens + usuário + módulos).
2. Se houver `refreshToken`, chama `POST /api/v1/auth/refresh` para obter um novo `accessToken`.
3. Atualiza o usuário (incluindo os **módulos** retornados pelo refresh, que podem ter mudado no backend) e persiste novamente.
4. Em falha → `logout()` silencioso.

## Requisições autenticadas

`DioClient` injeta automaticamente `Authorization: Bearer <accessToken>` via interceptor. Em falha `401` (que não seja do próprio endpoint de refresh e com token presente), o interceptor:

1. Chama `onRefreshToken` (externo, configurado em `main.dart`) — que usa o `refreshToken` persistido, chama `POST /api/v1/auth/refresh`, grava os novos tokens no `SessionStorage` e atualiza a sessão em memória (`AuthProvider.restaurarSessaoAposRefresh`).
2. Em sucesso, repete a requisição original **uma única vez** (flag `_retry`), transparente para a UI.
3. Em falha do refresh → `AuthProvider.logout()` silencioso e mensagem de "acesso não autorizado".

Refresh concorrentes são agrupados (uma única chamada em andamento), evitando múltiplos `refresh` simultâneos.

## Logout

`_clearSession()` remove tokens do `SessionStorage`, usuário/módulos do `shared_preferences` e retorna à `LandingScreen`.

## Persistência

| Onde | Chave | Conteúdo |
|---|---|---|
| `SessionStorage` (secure) | `chronos_access_token` | Access token |
| `SessionStorage` (secure) | `chronos_refresh_token` | Refresh token |
| `shared_preferences` | `chronos_usuario` | Usuário (JSON) |
| `shared_preferences` | `chronos_modulos` | Lista de códigos de módulos ativos (salva/restaurada junto da sessão) |

## Tempo de sessão

- **Idle**: 15 minutos sem atividade (teclado, toque, retomada do app) → logout com aviso.
- **Absoluta**: 8 horas desde o login (garantida pelo backend na validade do refresh token).

## Módulos na sessão

A lista de módulos persiste para que o **menu seja montado de forma reativa** logo após o login/restauração, sem chamadas extras. A fonte de verdade do acesso, porém, é o backend (`ModuloInterceptor`) — o app apenas esconde itens não contratados.