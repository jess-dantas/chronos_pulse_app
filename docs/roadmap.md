# Roadmap

O roadmap do produto é versionado no repositório do **backend** (fonte canônica):

- **`chronos-pulse` → [`ROADMAP.md`](https://github.com/jess-dantas/chronos-pulse/blob/develop/ROADMAP.md)**

Este app entrega a frente Flutter de cada requisito (R-series). Estado atual: `R27` a `R31` concluídos; `R31.1` (pós-entrega) com batida de ponto blindada (watchdog 30s), voltar nas telas públicas e **cadastro em 3 etapas virou lead** (Sem conta/CPF/senha → `POST /leads/empresas`).

**Pós-R31.1 (offline-first web & mobile):**
- SQLite (nativo) e **SharedPreferences/localStorage (Web)** garantem fila offline durável — igual funcional em Android/iOS/Chrome, sobrevive a F5 e troca de porta do dev server.
- Sequência de batidas preservada offline; auto-sync 30s; chamadas remotas limitadas (4s/8s) para não travar com servidor indisponível.
- Ajuste manual de ponto: **excluído da lista/sequência da home** (que mostra só batidas feitas pelo botão) e **sobreposto** na célula do espelho e no PDF — valor ajustado com o original entre parênteses; colunas nomeadas Entrada/Intervalo/Retorno/Saída.
- Sequência de batidas conta **apenas batidas de botão** (`SequenciaPonto`) na tela principal e no diálogo de ajuste — ajustes não atrasam o ciclo (Saída não vira Intervalo).
- App localizado em **pt-BR**: calendários dos pickers de data/hora em Português, datas DD/MM/AAAA e hora 24h (`flutter_localizations`).

**Cobertura de testes do app: 200** (`flutter test`), analyze limpo.