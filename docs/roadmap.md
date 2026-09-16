# Roadmap

O roadmap do produto é versionado no repositório do **backend** (fonte canônica):

- **`chronos-pulse` → [`ROADMAP.md`](https://github.com/jess-dantas/chronos-pulse/blob/develop/ROADMAP.md)**

Este app entrega a frente Flutter de cada requisito (R-series). Estado atual: `R27` a `R31` concluídos; `R31.1` (pós-entrega) com batida de ponto blindada (watchdog 30s), voltar nas telas públicas e **cadastro em 3 etapas virou lead** (Sem conta/CPF/senha → `POST /leads/empresas`).

**R32 — REP-P (Portaria MTP 671/2021):** backend gera **AFD** (Anexo V) e **AEJ** (Anexo VI) com leiaute oficial (`/fiscal/afd` e `/fiscal/aej`); app segue entregando espelho (art. 84) e comprovante (art. 79). Homologação pendente: registro INPI (art. 91), assinatura ICP-Brasil (art. 88) e validação com o leiaute definitivo.

**R33 — Acompanhamento de leads (entregue):** `GET /leads` + `PATCH /leads/{id}/status` no backend e tela **Acompanhamento de Leads** no painel admin com funil (NOVO → AGENDADO → REUNIAO → CONTRATADO/DESCARTADO), contadores e avanço por dropdown (`test/leads_test.dart`).

**Pós-R31.1 (offline-first web & mobile):**
- SQLite (nativo) e **SharedPreferences/localStorage (Web)** garantem fila offline durável — igual funcional em Android/iOS/Chrome, sobrevive a F5 e troca de porta do dev server.
- Sequência de batidas preservada offline; auto-sync 30s; chamadas remotas limitadas (4s/8s) para não travar com servidor indisponível.
- Ajuste manual de ponto: **excluído da lista/sequência da home** (que mostra só batidas feitas pelo botão) e **sobreposto** na célula do espelho e no PDF — valor ajustado com o original entre parênteses; colunas nomeadas Entrada/Intervalo/Retorno/Saída.
- Sequência de batidas conta **apenas batidas de botão** (`SequenciaPonto`) na tela principal e no diálogo de ajuste — ajustes não atrasam o ciclo (Saída não vira Intervalo).
- App localizado em **pt-BR**: calendários dos pickers de data/hora em Português, datas DD/MM/AAAA e hora 24h (`flutter_localizations`).

**Cobertura de testes do app: 200** (`flutter test`), analyze limpo.