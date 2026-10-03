# Autenticação e Sessão

Fluxo baseado em `AuthProvider` (`features/auth/`) e `DioClient` (`core/network/`). O Administrator (Admin Plataforma) usa um fluxo separado (`AdminAuthProvider`, `features/admin/`) — ver [Administrator (Admin Plataforma)](#administrator-admin-plataforma).

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

`_clearSession()` remove tokens do `SessionStorage`, usuário/módulos do `shared_preferences` e retorna à `LandingScreen`. Também usado ao concluir a transferência de titularidade (reforça o novo papel no próximo login).

## Persistência

| Onde | Chave | Conteúdo |
|---|---|---|
| `SessionStorage` (secure) | `chronos_access_token` | Access token |
| `SessionStorage` (secure) | `chronos_refresh_token` | Refresh token |
| `SessionStorage` (secure) | `chronos_device_token` + `chronos_device_*` | Vínculo de dispositivo (modo sem login, 7 dias) |
| `SessionStorage` (secure) | `chronos_device_2fa` | Se o dono do vínculo tem o 2FA — define a cobrança do código no modo |
| `SessionStorage` (secure) | `chronos_admin_device_*` | Dispositivo confiável do Administrator (deviceToken, 30 dias — biometria-first) |
| `shared_preferences` | `chronos_usuario` | Usuário (JSON) |
| `shared_preferences` | `chronos_modulos` | Lista de códigos de módulos ativos (salva/restaurada junto da sessão) |
| `shared_preferences` | `chronos_biometria_ativa` | Exigir biometria ao abrir (padrão ativado; tela Segurança) |

## Modo sem login (bater ponto sem login)

Rota pública `/ponto/dispositivo` (`ModoPontoScreen`), mobile only — o guard
valida, **nesta ordem**:

1. **Vínculo local** (`DeviceTokenStore`, 7 dias) — sem ele o modo nem começa;
2. **Biometria** do aparelho (`HardwareService`, timeout 8s);
3. **2FA** — só quando o dono tem a autenticação em duas etapas habilitada
   (flag `chronos_device_2fa`, gravada na ativação e sincronizada pelo
   `GET /device/status`): TOTP de 6 dígitos ou OTP de 8 dígitos por e-mail,
   validados pelo `POST /auth/device/verificar` com header `X-Device-Token`
   (`ModoPontoTwoFactorScreen`). **Offline o código não é pulado**: sem
   conexão a etapa bloqueia com orientação;
4. **Vínculo (confirmação)** — `GET /device/status` valida o token no
   servidor, sincroniza a flag de 2FA e detecta revogação (401 → limpa a
   store e mostra o aviso). Offline, o vínculo local segue valendo e a
   batida entra na fila de sincronização.

A ativação do vínculo (`ContingenciaGate` após o login, ou o tile do Perfil)
avisa o usuário dessa ordem a cada uso.

## Tempo de sessão

- **Idle**: 15 minutos sem atividade (teclado, toque, retomada do app) → logout com aviso.
- **Absoluta**: 8 horas desde o login (garantida pelo backend na validade do refresh token).

## Módulos na sessão

A lista de módulos persiste para que o **menu seja montado de forma reativa** logo após o login/restauração, sem chamadas extras. A fonte de verdade do acesso, porém, é o backend (`ModuloInterceptor`) — o app apenas esconde itens não contratados.

## Administrator (Admin Plataforma)

Sessão **separada** da do usuário de tenant (`AdminAuthProvider` + rota `/admin/auth/login`, tela "Login Administrator"):

1. `GET /admin/auth/bootstrap/status` → se `bootstrapAvailable: true` (tabela `admin_plataforma` vazia — first-run), a tela de login exibe o link **"Criar primeiro Administrator"** → `/admin/auth/bootstrap`.
2. `POST /admin/auth/bootstrap` (username ≤ 20, senha 8–100, nomeCompleto, email) → cria a conta e responde `requiresTwoFactor: true` + `setupRequired: true` + `tempToken` → rota **`/admin/auth/setup-2fa`** (setup **obrigatório**).
3. **Biometria-first (dispositivo confiável)**: o tile **"Confiar neste
   dispositivo"** (`/perfil/seguranca`, só admin root, não-web) chama
   `POST /admin/auth/dispositivo` → grava `{ deviceToken, username,
   expiraEm }` no `AdminDeviceTokenStore` (30 dias, sobrevive ao logout).
   Na tela de login, com credencial guardada e biometria do aparelho
   disponível, o **auto-prompt** (e o botão "Entrar com biometria")
   confirma a biometria e envia o `deviceToken` no
   `POST /admin/auth/login` — **pulando senha e 2FA**. Token
   recusado/expirado no servidor → a credencial local é limpa e o usuário
   cai no fluxo manual (2FA ou senha). Revogação:
   `DELETE /admin/auth/dispositivo` no mesmo tile.
4. `POST /admin/auth/login` (username ≤ 20 + senha 8–100) — **fora** de `/api/v1`. Respostas possíveis:
   - 2FA ativo: `requiresTwoFactor: true` + `tempToken` → tela de código (6 dígitos) → `POST /admin/auth/2fa/verify` troca o `tempToken` pelos tokens finais;
   - 2FA obrigatório mas desligado: `setupRequired: true` + `tempToken` → mesma rota de setup forçado;
   - sem 2FA (dev): tokens diretos.
   O login manual (senha/código) **nunca** envia `deviceToken` — só o tier da biometria.
5. Setup (`AdminSetup2FaScreen`): `POST /admin/auth/2fa/setup` → `POST /admin/auth/2fa/confirm` → **dialog com 8 códigos de recuperação** (`RecoveryCodesDialog`, exibido uma única vez — salvar!) → tokens finais → `/admin/dashboard`.
6. Perda de acesso 2FA: rota **`/admin/auth/recover`** → `POST /admin/auth/2fa/recover` (`username` + `senha` + `recoveryCode` `XXXXX-XXXXX`) → tokens + **8 novos** códigos exibidos no mesmo dialog.
7. O access token admin é guardado em memória no `DioClient` (`updateAdminToken`) — rotas `/admin/**` usam esse token; demais rotas usam o token da sessão regular.
8. Logout único: o botão de sessão (avatar + sair) no **rodapé** do rail do `AdminShell` (ou na barra de conta em layout narrow) encerra **as duas sessões** se estiverem ativas (admin root + usuário comum). O dispositivo confiável **sobrevive** ao logout (é para reentregar sem senha).

2FA e senha (`AdminSegurancaScreen` / `AdminAlterarSenhaScreen`):

- `GET /admin/auth/2fa/status` → `{ enabled }`
- `POST /admin/auth/2fa/setup` → `{ secret, otpauthUri }` (copiar segredo/link no app autenticador)
- `POST /admin/auth/2fa/confirm` `{ codigo }` → ativa e (no fluxo de bootstrap) entrega os tokens + recovery codes
- `POST /admin/auth/2fa/disable` `{ codigo }` → exige código TOTP válido para desativar (sempre permitido; com `chronos.admin.two-factor-required=true` o login seguinte volta a exigir setup)
- `POST /admin/auth/alterar-senha` `{ senhaAtual, novaSenha }`
- `POST /admin/auth/2fa/recover` `{ username, senha, recoveryCode }` — público, sem sessão

Rotas dedicadas do fluxo: `/admin/auth/bootstrap`, `/admin/auth/setup-2fa`, `/admin/auth/recover` (protegidas pelo redirect `startsWith('/admin/auth/')`, fora do shell de usuário).

## Perfil e transferência de titularidade

- Rota **`/perfil`** (rodapé do rail ou avatar): dados do usuário logado, alterar senha; para `ADMIN_EMPRESA` exibe o card **Transferir titularidade**.
- Rota **`/perfil/titularidade`** (`TransferirTitularidadeScreen`): wizard de 3 etapas (biometria → OTP celular → OTP e-mail). Protegida por redirect (`auth.usuario?.isAdminEmpresa`), senão volta para `/perfil`.
- Etapa 1 usa `local_auth` com timeout de 8s (no **Web** a biometria é confirmada automaticamente — limitação da plataforma, documentada na tela).
- Após **Concluir transferência** o app chama `auth.logout()` e navega para `/login` — o novo titular loga novamente com o novo papel.
- OTPs no dev (`chronos.mail.enabled=false`) são impressos no **console do backend**.