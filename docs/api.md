# Endpoints Consumidos pelo App

Constant base: `lib/core/constants/api_constants.dart`. Todas as rotas são sob `baseUrl = /api/v1`, autenticadas com `Authorization: Bearer <accessToken>` (exceto onde indicado).

## Públicos (Auth)

| Método | Rota | Uso |
|---|---|---|
| `POST` | `/auth/login` | Login CPF/senha |
| `POST` | `/auth/cadastrar-empresa` | Cadastro público de empresa |
| `POST` | `/auth/refresh` | Renovar access token |
| `GET` | `/auth/ping` | Health-check |
| `GET` | `/auth/me` | Perfil do usuário logado |

## Admin Plataforma

| Método | Rota | Feature/Tela |
|---|---|---|
| `GET` | `/admin/modulos` | `AdminModulosScreen` — catálogo |
| `GET` | `/admin/empresas/{tenantId}/modulos` | Módulos ativos da empresa |
| `PUT` | `/admin/empresas/{tenantId}/modulos` | Salvar ativação |
| `GET` | `/admin/empresas` | Lista de empresas (painel e tela de módulos) |
| (vários) | `/admin/*` | Dashboard, contratos e colaboradores do painel |

## Colaboradores (módulo RH)

| Método | Rota |
|---|---|
| `GET` | `/colaboradores` |
| `POST` | `/colaboradores` |
| `PUT` | `/colaboradores/{id}` |
| `DELETE` | `/colaboradores/{id}` |

## Ponto & Fiscal

| Método | Rota |
|---|---|
| `POST` | `/pontos/sincronizar` |
| `GET` | `/pontos/espelho` |
| `POST` | `/pontos/ajustar` |
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

## Formato de Listagens

As listagens retornam `Page` (`{ content: [...], totalElements, totalPages, ... }`). Os datasources leem `data['content']` ou `data` (lista direta, caso o endpoint devolva lista sem paginação — ex.: `/patrimonio/ativos`).