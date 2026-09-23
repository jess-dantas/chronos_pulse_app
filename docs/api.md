# Endpoints Consumidos pelo App

Constant base: `lib/core/constants/api_constants.dart`. Todas as rotas são sob `baseUrl = /api/v1`, autenticadas com `Authorization: Bearer <accessToken>` (exceto onde indicado). A autenticação Admin Plataforma (`/admin/auth/*`) fica **fora** de `/api/v1` — o datasource monta a URL base removendo o sufixo `/api/v1`.

## Públicos (Auth)

| Método | Rota | Uso |
|---|---|---|
| `POST` | `/auth/login` | Login CPF/senha |
| `POST` | `/auth/cadastrar-empresa` | (legado) Cadastro público de empresa |
| `POST` | `/leads/empresas` | Wizard 3 etapas — **lead comercial** (sem conta/CPF/senha) |
| `POST` | `/auth/refresh` | Renovar access token |
| `GET` | `/auth/ping` | Health-check |
| `GET` | `/auth/me` | Perfil do usuário logado |

## Admin Auth (fora de `/api/v1`)

| Método | Rota | Uso | Acesso |
|---|---|---|---|
| `POST` | `/admin/auth/login` | `AdminAuthScreen` — "Login Administrator": username/senha → `accessToken`, ou `requiresTwoFactor` + `tempToken`, ou `setupRequired` + `tempToken` (2FA obrigatório desligado) | público |
| `GET` | `/admin/auth/bootstrap/status` | Link "Criar primeiro Administrator" quando `bootstrapAvailable: true` | público |
| `POST` | `/admin/auth/bootstrap` | `AdminBootstrapScreen` — cria a 1ª conta e retorna `setupRequired` + `tempToken` | público |
| `POST` | `/admin/auth/2fa/verify` | Troca `tempToken` pelos tokens finais (código 6 dígitos) | público |
| `POST` | `/admin/auth/2fa/recover` | `AdminRecoverScreen` — `{ username, senha, recoveryCode }` → tokens + 8 novos códigos | público |
| `POST` | `/admin/auth/logout` | Logout do Administrator (best-effort) | público |
| `GET` | `/admin/auth/2fa/status` | `AdminSegurancaScreen` — `{ enabled }` | `ADMIN_PLATAFORMA` |
| `POST` | `/admin/auth/2fa/setup` | Gera segredo → `{ secret, otpauthUri }` | `ADMIN_PLATAFORMA` |
| `POST` | `/admin/auth/2fa/confirm` | `{ codigo }` — ativa o 2FA (no bootstrap também entrega tokens + `recoveryCodes`) | `ADMIN_PLATAFORMA` |
| `POST` | `/admin/auth/2fa/disable` | `{ codigo }` — desativa o 2FA (**403** quando obrigatório) | `ADMIN_PLATAFORMA` |
| `POST` | `/admin/auth/alterar-senha` | `{ senhaAtual, novaSenha }` (8–100) | `ADMIN_PLATAFORMA` |

Datasource: `AdminAuthRemoteDataSource` (monta a URL base removendo o sufixo `/api/v1`). Widgets: `RecoveryCodesDialog` (8 códigos `XXXXX-XXXXX`, exibição única), `TwoFactorSetupCard` (fluxo de setup).

## Admin Plataforma

| Método | Rota | Feature/Tela |
|---|---|---|
| `GET` | `/admin/modulos` | `AdminModulosScreen` — catálogo |
| `GET` | `/admin/empresas/{tenantId}/modulos` | Módulos ativos da empresa |
| `PUT` | `/admin/empresas/{tenantId}/modulos` | Salvar ativação |
| `GET` | `/admin/empresas` | Lista de empresas (painel e tela de módulos) |
| (vários) | `/admin/*` | Dashboard, contratos e leads |

## Colaboradores (módulo RH)

| Método | Rota |
|---|---|
| `GET` | `/colaboradores` |
| `POST` | `/colaboradores` — aceita `celular` opcional |
| `PUT` | `/colaboradores/{id}` — `celular` só muda se informado |
| `DELETE` | `/colaboradores/{id}` |
| `GET` | `/usuarios/{usuarioId}/modulos?tenantId=` — módulos associados ao usuário (edição) |
| `PUT` | `/usuarios/{usuarioId}/modulos` — grava `{ tenantId, codigos }` (edição/cadastro de colaborador) |

`ColaboradorModel` expõe `celular` (`fromJson`: `json['celular']`); datasource/repository/provider passam o campo em cadastrar/atualizar.

## Titularidade (`ADMIN_EMPRESA`)

Feature `features/titularidade/` — wizard `/perfil/titularidade` (`TransferirTitularidadeScreen`); paths relativos ao `baseUrl` (`/api/v1`):

| Método | Rota | Uso |
|---|---|---|
| `POST` | `/titularidade/iniciar` | `{ novoTitularId }` → `{ transferenciaId, novoTitularNome, novoTitularCelular }` |
| `POST` | `/titularidade/{id}/etapa/biometria` | `{ confirmado }` — etapa 1 |
| `POST` | `/titularidade/{id}/etapa/celular/enviar` | Envia OTP ao titular atual → `{ mensagem, destino }` |
| `POST` | `/titularidade/{id}/etapa/celular/verificar` | `{ codigo, celularConfirmado }` |
| `POST` | `/titularidade/{id}/etapa/email/enviar` | Envia OTP ao novo titular → `{ mensagem, destino }` |
| `POST` | `/titularidade/{id}/etapa/email/verificar` | `{ codigo }` |
| `POST` | `/titularidade/{id}/concluir` | Troca papéis → app faz `logout()` + `/login` |
| `POST` | `/titularidade/{id}/cancelar` | Cancela em andamento |

`TitularidadeProvider` guarda o estado das etapas (`biometriaConfirmada`/`celularVerificado`/`emailVerificado`/`concluida`, getter `etapa` 1..4, `podeConcluir`) e `limpar()` ao entrar/sair.

## Ponto & Fiscal

| Método | Rota |
|---|---|
| `POST` | `/pontos/sincronizar` |
| `GET` | `/pontos/espelho` |
| `POST` | `/pontos/ajustar` |
| `POST` | `/pontos/ajustar/solicitar` — colaborador solicita ajuste |
| `GET` | `/pontos/ajustes/pendentes` — RH lista pendentes (`AprovacaoAjustesScreen`, rota painel `aprovacao-ajustes`) |
| `PUT` | `/pontos/ajustes/{id}/aprovar` |
| `PUT` | `/pontos/ajustes/{id}/rejeitar` |
| `GET` | `/fiscal/aej/download` |

## Estoque

| Método | Rota |
|---|---|
| `GET` | `/estoque/saldos` |
| `GET` | `/estoque/movimentacoes` |
| `POST` | `/estoque/movimentacoes/entrada` |
| `POST` | `/estoque/movimentacoes/saida` |
| `GET` | `/estoque/requisicoes` |
| `POST` | `/estoque/requisicoes` |

## Patrimônio

| Método | Rota |
|---|---|
| `GET` | `/patrimonio` |
| `POST` | `/patrimonio` |

Payload de cadastro: `tombamento`, `descricao`*, `categoria`, `estado`*, `localizacao`, `dataAquisicao` (ISO), `valorAquisicao` (número), `responsavelNome`, `numeroNotaFiscal`, `observacoes`. (*=obrigatórios)

## Frota

| Método | Rota |
|---|---|
| `GET` | `/frota/veiculos` |
| `POST` | `/frota/veiculos` |
| `GET` | `/frota/abastecimentos` |
| `POST` | `/frota/abastecimentos` |

> Valores numéricos (`litros`, `valorLitro`, `odometroKm`, `odometroAtual`) são enviados como **números JSON** (o provider converte com `double.tryParse`); o backend calcula `valorTotal`.

## Protocolo

| Método | Rota |
|---|---|
| `GET` | `/protocolo` |
| `POST` | `/protocolo` |
| `PATCH` | `/protocolo/{id}/status` |

- `POST /protocolo` — `numeroProtocolo`*, `tipo`*, `assunto`*, `descricao`, `remetente`, `destinatario`, `responsavel`, `observacoes`.
- `PATCH /protocolo/{id}/status` — `status`* (`RECEBIDO` | `TRIAGEM` | `EM_TRAMITACAO` | `ARQUIVADO` | `CANCELADO`), `responsavel`, `observacoes`.

## Licitações & Execução Contratual

| Método | Rota | Uso |
|---|---|---|
| `GET` | `/licitacoes` | Home de licitações (lista) |
| `GET` | `/licitacoes/{id}/planejamento` | Detalhe / planejamento |
| `POST` | `/licitacoes/{id}/contrato` | Formalizar contrato |
| `GET` | `/contratos` | `ContratoExecucaoScreen` — lista de contratos em execução |
| `GET` | `/contratos/{id}` | Detalhe da execução (resumo/aditivos/fiscalização/medições/sanções) |
| `POST` | `/contratos/{id}/aditivos` | Registrar termo aditivo |
| `POST` | `/contratos/{id}/apontamentos` | Registrar apontamento |
| `POST` | `/contratos/{id}/apontamentos/{apontamentoId}/resolver` | Resolver apontamento |
| `POST` | `/contratos/{id}/medicoes` | Registrar medição |
| `POST` | `/contratos/{id}/sancoes` | Aplicar sanção |
| `POST` | `/contratos/{id}/rescindir` | Rescindir contrato |

## Portal da Transparência (LC 131/2009) + Portal Público (R31)

| Método | Rota | Uso |
|---|---|---|
| `GET` | `/transparencia/resumo` | `TransparenciaHomeScreen` — indicadores do BI |
| `GET` | `/transparencia/despesas-mensais?ano=` | Despesas mensais |
| `GET` | `/transparencia/publicacoes` | Lista de publicações (rascunho/divulgadas) |
| `POST` | `/transparencia/publicacoes` | Cria publicação |
| `POST` | `/transparencia/publicacoes/{id}/publicar` | Divulga publicação |
| `DELETE` | `/transparencia/publicacoes/{id}` | Remove publicação em elaboração |
| `GET` | `/publico/transparencia/{slug}` | **Público** — resumo do órgão na aba "Portal Público" |
| `GET` | `/publico/transparencia/{slug}/licitacoes` | **Público** — licitações com situação pública |
| `GET` | `/publico/transparencia/{slug}/licitacoes/{id}` | **Público** — detalhe com itens |
| `GET` | `/publico/transparencia/{slug}/contratos` | **Público** — contratos |
| `GET` | `/publico/transparencia/{slug}/contratos/{id}` | **Público** — detalhe com aditivos e sanções |
| `GET` | `/publico/transparencia/{slug}/despesas-mensais?ano=` | **Público** — despesas do ano |
| `GET` | `/publico/transparencia/{slug}/publicacoes` | **Público** — publicações divulgadas |

O `slug` vem do login (`tenantSlug` no `UsuarioModel`) e identifica o órgão nas URLs públicas (ex.: `demonstracao`, `lj-code`). Rotas públicas não exigem token (o servidor as libera em `/api/v1/publico/**`).

## Privacidade & LGPD (`/api/v1/privacidade`)

| Método | Rota | Uso |
|---|---|---|
| `GET` | `/privacidade/politica` | `PrivacidadeScreen` + modal do gate — texto do Termo de Ciência + `versao` + `hashTermo` |
| `GET` | `/privacidade/consentimento/status` | `ConsentimentoGate` (MainShell) e `PrivacidadeScreen` — `{ versaoAtual, versaoAceita, aceitePendente }`; falha não bloqueia o app |
| `GET` | `/privacidade/meus-dados` | Exportação dos dados (art. 18 LGPD) |
| `POST` | `/privacidade/consentimento` | `{ versaoPolitica, aceito: true }` — "Ciente e de acordo" (gate modal ou tela de privacidade); idempotente no servidor |
| `DELETE` | `/privacidade/meus-dados` | Anonimização |

`PrivacidadeProvider` expõe `consentimentoPendente`/`versaoConsentimentoAceita`/`dataConsentimentoAceite`, `carregarStatusConsentimento()` (silencioso) e `registrarConsentimento()`; o gate fica em `lib/core/widgets/dialogs/consentimento_gate.dart` (escopo: apenas `MainShell` — Admin Plataforma não é bloqueado).

## Formato de Listagens

As listagens retornam `Page` (`{ content: [...], totalElements, totalPages, ... }`). Os datasources leem `data['content']` ou `data` (lista direta, caso o endpoint devolva lista sem paginação — ex.: `/patrimonio/ativos`).