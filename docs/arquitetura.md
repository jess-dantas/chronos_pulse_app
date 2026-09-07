# Arquitetura do App

Projeto Flutter organizado em **features** com forte separação de responsabilidades. Cada feature segue o padrão **Data → Domain → Presentation** (datasource → models → repository → provider → screens).

## Estrutura

```
lib/
├── core/
│   ├── constants/api_constants.dart    # Endpoints (por plataforma) e constantes de módulo
│   ├── database/                       # SQLite local (offline-first no ponto)
│   ├── hardware/                       # Biometria (local_auth) e GPS (geolocator)
│   ├── network/dio_client.dart         # Dio + interceptor Bearer JWT
│   └── theme/                          # Temas claro/escuro + persistência
├── features/
│   ├── auth/                           # Login, cadastro público, sessão e perfil
│   ├── colaborador/                    # CRUD de colaboradores (módulo RH)
│   ├── ponto/                          # Ponto eletrônico offline-first
│   ├── estoque/                        # Saldos PMP, entradas NFe, saídas, requisições
│   ├── patrimonio/                     # Patrimônio Público (listar + cadastrar bem)
│   ├── frota/                          # Veículos + abastecimentos (abas)
│   ├── protocolo/                      # Protocolo eletrônico (status em PATCH)
│   ├── admin/                          # Painel Admin Plataforma (empresas, contratos,
│   │                                   #   colaboradores, dashboard e Módulos)
│   ├── landing/                        # Landing page pública
│   └── navigation/                     # Shell adaptativo (Rail Web / Bar Mobile)
└── main.dart                           # MultiProvider + restauração de sessão
```

## Padrão de uma Feature (modelo: `patrimonio/`)

| Camada | Arquivo |
|---|---|
| Data source | `data/datasources/<feature>_remote_datasource.dart` — chamadas HTTP via `DioClient` |
| Modelo | `data/models/<feature>_models.dart` — `fromJson` para listas ou `content` de `Page` |
| Repositório | `data/repositories/<feature>_repository.dart` — delega ao datasource |
| Provider | `presentation/providers/<feature>_provider.dart` — estado com `ChangeNotifier` (loading, erro, dados) |
| Telas | `presentation/screens/<feature>_home_screen.dart` + `presentation/screens/dialogs/*.dart` |

Os providers são registrados em `main.dart` no `MultiProvider` e injetados via `context.read<T>()` / `context.watch<T>()`. As telas `Scaffold` próprias são colocadas como filhos do `IndexedStack` na navegação principal.

## Navegação

- `navigation/` decide entre **NavigationRail** (web/desktop, largura > 800px) e **NavigationBar** (mobile).
- Os itens são construídos **condicionalmente** pelos getters `temModulo*` do usuário (ver [`modulos.md`](modulos.md)).
- O índice atual é ajustado para `0` caso o item selecionado não exista mais (`safeIndex`).

## Inicialização

`main.dart`:

1. `initializeDateFormatting('pt_BR')` e carrega o tema salvo.
2. Instancia `DioClient` e **todos** os datasources/repositories/providers.
3. `MultiProvider` expõe theme, auth, colaborador, estoque, ponto, admin, patrimonio, frota e protocolo.
4. `AuthWrapper` redireciona: não autenticado → `LandingScreen`; plataforma → `AdminNavigationScreen`; demais → `MainNavigationScreen`.