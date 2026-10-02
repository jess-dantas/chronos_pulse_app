# Infraestrutura & Operação — Chronos Pulse App (Flutter)

Rotas, subida do app, configuração da API e testes.
Para o que é o software, seus módulos e a stack, ver o [`README.md`](../README.md).

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
| `/admin/dashboard` … `/admin/seguranca` | Área administrativa (`AdminShell`) |

Configurações centrais em `lib/core/router/app_router.dart` (ordem dos módulos,
permissões por rota e redirects) e os shells em
`lib/features/navigation/presentation/screens/`.

---

## Como subir o app

### Pré-requisitos

- **Flutter 3.x** com **Dart 3.x** instalados (`flutter doctor` sem pendências críticas)
- **Backend Chronos Pulse no ar** (seguir o `docs/infra.md` do projeto `chronos-pulse` — subida com/sem Docker)
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
## Android (emulador ou dispositivo físico) — exige --flavor (4 flavors)
flutter run --flavor clienteLocal        # aponta para o backend local
flutter run --flavor cliente             # aponta para o Render

# 4. Corra os testes (252 testes)
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

---

## Configuração da API

Resolução automática em `lib/core/constants/api_constants.dart` (prioridade: `--dart-define=API_URL` > release/web/plataforma):

| Plataforma | Endereço padrão |
|---|---|
| API via `--dart-define=API_URL` | sobrescreve tudo (recomendado em produção) |
| Release (web/móvel) sem `API_URL` | `https://chronos-pulse.onrender.com/api/v1` |
| Web (debug) | `http://localhost:3030/api/v1` |
| Android (emulador) | `http://10.0.2.2:3030/api/v1` |
| Android (dispositivo físico) | `http://<IP_DA_MAQUINA>:3030/api/v1` |
| iOS / Desktop | `http://localhost:3030/api/v1` |

> No emulador Android a API resolve em `10.0.2.2`; em dispositivo físico use o IP local da máquina
> (ex.: `--dart-define=API_URL=http://192.168.0.10:3030/api/v1`).

---

## Credenciais de Teste (tenant de demonstração com 9 módulos)

> As credenciais de demonstração estão concentradas em
> [`credenciais.md`](credenciais.md). As credenciais de acesso
> **privilegiado** (fundador da empresa e Admin Plataforma) **não são documentadas
> em texto plano no repositório** — são entregues fora do código (ver seção de
> acessos do time / gestor de segredos).

---

## Testes automatizados

```bash
flutter analyze   # sem issues
flutter test      # 252 testes, 0 falhas
```

---

## Gerar artefatos Android (APK)

O projeto tem **4 flavors** (`android/app/build.gradle.kts`), que geram apps
**instaláveis lado a lado** no mesmo aparelho:

| Flavor | applicationId | Ícone/Label | Cleartext (HTTP) | Uso |
|---|---|---|---|---|
| `cliente` | `…chronos_pulse_app` | Chronos Pulse | não | Produção (Render) — clientes |
| `clienteLocal` | `…chronos_pulse_app.local` | Chronos Pulse (local) | **sim** | Teste no notebook |
| `admin` | `…chronos_pulse_app.admin` | Chronos Pulse Admin | não | Produção (Render) — dono da plataforma |
| `adminLocal` | `…chronos_pulse_app.admin.local` | Chronos Pulse Admin (local) | **sim** | Teste no notebook |

Complemento `--dart-define`:

- `API_URL` — backend de destino (obrigatório nos locais; obrigatório na CI de produção).
- `APP_MODE` — `cliente` bloqueia as rotas `/admin/*` no app de clientes e o app
  **abre direto no `/login`** (sem carregar a landing; o botão voltar do login
  ainda leva a ela); `admin` limita o app à área `/admin` (login de cliente vira
  redirect); **sem o define o comportamento é o atual** (usado no web de
  produção, inalterado — home continua sendo a landing).
  Pares corretos: `cliente|clienteLocal → APP_MODE=cliente`; `admin|adminLocal → APP_MODE=admin`.

### Local — apontando para o backend no notebook (mesma rede Wi-Fi)

```powershell
# Backend no ar (WSL, docker) — sem -v para manter os dados do banco local
wsl -e bash -lc "cd /mnt/c/app/chronos-pulse && docker compose up -d"

# App cliente (testes de colaborador/gestor)
flutter build apk --release --flavor clienteLocal `
  --dart-define=API_URL=http://192.168.1.11:3030/api/v1 `
  --dart-define=APP_MODE=cliente

# App Admin (login /admin com 2FA)
flutter build apk --release --flavor adminLocal `
  --dart-define=API_URL=http://192.168.1.11:3030/api/v1 `
  --dart-define=APP_MODE=admin

# Instalar (substitua pelo IP do seu notebook — veja ipconfig)
adb install -r build\app\outputs\flutter-apk\app-clientelocal-release.apk
adb install -r build\app\outputs\flutter-apk\app-adminlocal-release.apk
```

> Os nomes dos APKs usam o flavor em **minúsculas** (`app-clientelocal-release.apk`).
> Troque `192.168.1.11` pelo IP do notebook na rede Wi-Fi se ele mudar.

### Produção — manualmente (idêntico ao que a CI gera)

```powershell
flutter build apk --release --flavor cliente `
  --dart-define=API_URL=https://chronos-pulse.onrender.com/api/v1 `
  --dart-define=APP_MODE=cliente

flutter build apk --release --flavor admin `
  --dart-define=API_URL=https://chronos-pulse.onrender.com/api/v1 `
  --dart-define=APP_MODE=admin
```

### Produção — automático (GitHub Actions)

- **Push em `main`** → workflow `deploy-prd.yml` publica o web no Vercel (como
  sempre) **e** gera os APKs `cliente` + `admin` assinados com o keystore de
  release, apontando para `secrets.RENDER_BACKEND_URL`. Baixe-os na página da
  execução do workflow → aba **Artifacts** (`chronos-pulse-android-<sha>`).
- **Google Drive**: o mesmo job `build-android-production` espelha os dois APKs
  na pasta `chronos_pulse_app` do Drive via OAuth2 (script
  `.github/scripts/gdrive-upload.sh`; folder ID no workflow). Validação manual:
  workflow `test-gdrive.yml` (`workflow_dispatch`) — temporário, removido após
  a primeira confirmação.
- PRs em `develop`/`main` → `ci.yml` valida analyze/testes e gera o APK do
  flavor `cliente` como artefato de conferência.
- **Keep-alive do Render**: ping periódico da API pelo **UptimeRobot**
  (monitor `804144234`) — fora do GitHub Actions, para não onerar o Actions
  com cron. (O workflow `keep-alive.yml` já existiu aqui e foi removido.)
- Secrets necessários no GitHub (já esperados pelo workflow):
  `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `RENDER_BACKEND_URL`,
  `GDRIVE_CLIENT_ID`, `GDRIVE_CLIENT_SECRET`, `GDRIVE_REFRESH_TOKEN`.
  ```powershell
  # gerar o valor do ANDROID_KEYSTORE_BASE64:
  [Convert]::ToBase64String([IO.File]::ReadAllBytes('C:\app\chronos_pulse_app\android\app\chronos-pulse-release.keystore'))
  ```

### iOS

Build/instalação de iOS exige **macOS + Xcode + conta Apple Developer** (não é
possível nesta máquina Windows). A CI já valida a compilação no job `build-ios`
(`--no-codesign`, sem upload de artefato). Quando houver um Mac: replicar os
flavors no Xcode (bundle id com sufixos `.admin`/`.local` + `CFBundleDisplayName`)
e usar `flutter build ipa --flavor <flavor> --dart-define=…`.

---

## Ambiente local (rede do backend)

Para o celular alcançar o backend do notebook na mesma rede Wi-Fi, esta máquina
usa um **portproxy + keepalive do WSL** configurados por tarefa agendada:

- Tarefa `ChronosPulse-Portproxy3030` (logon, elevada) → roda
  `C:\Users\<user>\.chronos-pulse\portproxy-3030.ps1`, que mantém o WSL vivo
  (`sleep infinity`) e aponta `0.0.0.0:3030 → <IP-do-WSL>:3030`.
- Regra de firewall `Chronos Pulse dev 3030` (perfil Privado) libera a porta na LAN.
- Se o backend não responder pela LAN, reexecute o script elevado (o IP do WSL
  pode mudar após reinícios):

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\<user>\.chronos-pulse\portproxy-3030.ps1
```

Verificação: `http://<IP-do-notebook>:3030/api/v1/auth/ping` deve retornar `{"status":"UP"}`.

> ⚠️ **Não use `docker compose down -v`** no dia a dia — `-v` apaga o volume do
> banco local e todos os dados de teste. Use apenas `docker compose up -d`.
