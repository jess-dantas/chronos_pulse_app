# CP Gestão Pública — Revisão Técnica, Objetivos Alcançados e Roadmap de Conformidade

> Documento consolidado gerado em 08/09/2026 a partir de revisão de código (backend + app), das anotações de projeto (`C:\app\_projeto\projeto-chronos-pulse-gestao-publica-licitacoes.txt` e `C:\app\_projeto\conformidade-governo-licitacoes.txt`) e das leis/regulamentações citadas.

## 1. Contexto e decisões estratégicas

- **Suíte própria, nativa e desacoplada (CP Gestão Pública)** — a dependência do ecossistema Frappe/ERPNext foi **abandonada**. O produto é um **monólito modular**: backend em **Spring Boot 4.1.1 / Java** (`chronos-pulse`) e frontend multi-plataforma em **Flutter 3.47** (`chronos_pulse_app`), com modelo **SaaS multi-tenant**.
- A decisão de manter tudo em um único repositório Spring Boot (monólito modular, `com.jess.chronos.pulse.modules.*`) está alinhada às anotações: reuso de segurança JWT, extração de `tenantId`, seed de dados; facilita entregar **Ponto + Estoque** em um único servidor e permite extrair módulos depois, se um edital exigir separação.
- **Estratégia de mercado** (das anotações): começar por **editais pequenos** (Câmaras Municipais, pequenas prefeituras) com **Estoque/Almoxarifado**, acumular atestados de capacidade técnica e receita recorrente, e evoluir de forma incremental — nunca tentando construir um ERP público completo de uma vez.
- Modelo comercial: **SaaS + implantação + suporte + (futuro) hardware de ponto** com marca própria.

**Estado atual (resumo):** módulos nativos já implementados e funcionais — **Ponto eletrônico, Estoque (com PMP), Frota, Patrimônio, Protocolo, RH/Colaboradores, Contratos e Admin de Plataforma** (empresas, colaboradores, módulos, dashboard). O backend tem 16 migrations Flyway e 89 testes; o app passa em `flutter analyze` com 0 erros / 0 avisos e 64 testes verdes (cobertura ~14%).

---

## 2. Objetivos já alcançados (estado da arte)

### 2.1 Backend (Spring Boot)
- **Multi-tenancy**: `tenant_id` (UUID) nas tabelas, extração do tenant a partir do token JWT; isolamento por empresa/órgão.
- **Autenticação/autorização**: login por CPF + senha (BCrypt), JWT Bearer com `id`, `tenantId`, `nome`, `email`, `papel`, módulos; roles `ADMIN_PLATAFORMA`, `SUPORTE_N1/N2`, `ADMIN_EMPRESA`, `GESTOR_RH`, `COLABORADOR`; refresh token; alterar senha; recuperação de senha por código enviado por e-mail; upload de foto do usuário.
- **Módulo Estoque/Almoxarifado**: materiais (código, descrição, unidade, estoque mínimo, preços, flags de lote/validade), almoxarifados, saldos, **custo médio ponderado (PMP)** em `CalculadoraPmpService`, movimentações de entrada/saída, **requisições com fluxo solicitar → aprovar → atender** (`RequisicaoService`), seed de almoxarifado.
- **Módulo Ponto**: registro sequencial de batidas (ENTRADA/INTERVALO/RETORNO/SAÍDA), `GeradorHashService` (rastreabilidade estilo `nsr`/`hashLocal`), sincronização em lote, espelho mensal, **ajuste manual com justificativas obrigatórias**, envio de comprovante por e-mail (`EmailComprovantePontoService`), exportação **AEJ** (`GeradorArquivoAEJAdapter`).
- **Admin de plataforma**: cadastro de empresas (com endereço, contato e **ativação automática dos módulos Ponto e RH**), cadastro/edição de colaboradores por empresa, catálogo e **ativação de módulos por empresa**, contratos e eventos de contrato, dashboard com métricas, seeds de admin/suporte/gestor/colaborador/almoxarife.
- **Qualidade**: 89 testes (27 classes) cobrindo PMP, requisição, materiais, autenticação, cadastro de empresa/colaborador, espelho, ajuste, hash, sincronização, AEJ, security/CORS, validação de CNPJ, política de senha por papel e privacidade/LGPD. Build via Maven `BUILD SUCCESS`.
- **Operação**: migrations Flyway `V1..V16`, profiles `dev`/`test`/`prod`, deploy em Render (PostgreSQL) funcionando.

### 2.2 App (Flutter)
- **Arquitetura**: organização por *features* com padrão **Data → Domain → Presentation** (`datasource → models → repository → provider → screens`), DI em `main.dart` (`MultiProvider`), shell adaptativo (NavigationRail web/desktop, NavigationBar mobile).
- **Autenticação/sessão**: restauração de sessão via `tryRestoreSession` (login único por CPF), tempo de inatividade 15 min e sessão máxima 8 h com aviso de motivo, login/cadastro de empresa público e **cadastro de empresa pelo admin** reutilizando o widget compartilhado `empresa_form_fields.dart`.
- **Gating por módulo**: getters `temModulo*` no `UsuarioModel`; o menu só exibe itens contratados; `AuthWrapper` separa área de plataforma (`AdminNavigationScreen`) da área operacional (`MainNavigationScreen`).
- **Ponto**: registro com **GPS + biometria** (`hardware_service`), **foto frontal** (`camera`), **offline-first em SQLite** com sincronização em lote, heartbeat online/offline a cada 8 s, espelho mensal com cálculo de horas e ajustes, **exportação PDF** com referência à **PORTARIA MTP Nº 671/2021** e campos de assinatura (colaborador e RH/fiscal).
- **Estoque**: abas Saldos/Requisições, cards de métricas (itens distintos, valor total, abaixo do mínimo), fluxo completo de requisição.
- **Frota / Patrimônio / Protocolo**: CRUDs funcionais (veículos+abastecimentos, bens com tombação e estados de conservação NOVO→INSERVÍVEL, processos/documentos com tipos e status de tramitação).
- **Validação brasileira**: CPF/CNPJ com dígitos verificadores (CNPJ **numérico e alfanumérico**), CEP, telefone; consultas públicas via **BrasilAPI** (CNPJ → razão social; CEP → endereço); listas de cargos/departamentos em `listas_govbr.dart`.
- **UX**: tema claro/escuro persistido, máscaras, feedback consistente (SnackBar de sucesso/erro), estados de vazio/loading, diálogos de confirmação. `flutter analyze`: **0 erros, 0 warnings, 37 infos** (todas pré-existentes no R18).

### 2.3 Correções recentes importantes
- **Checksum de migration Flyway estabilizado**: a `V3` havia sido editada depois de aplicada (troca do e-mail do admin), causando `checksum mismatch` no Render. Corrigido restaurando a `V3` ao conteúdo original e criando a **`V13__atualizar_email_admin_plataforma.sql`** (atualização pontual do e-mail por CPF). **Regra de ouro: nunca editar migration já aplicada**; sempre criar uma nova.
- Refatoração do cadastro de empresa (admin e público) usando widget único; módulos Ponto e RH ativados automaticamente no cadastro.

---

## 3. Revisão técnica — pontos fortes e riscos

### 3.1 Pontos fortes confirmados
- Padrão limpo e consistente entre módulos (facilita manutenção e onboarding).
- Ponto eletrônico orientado à conformidade trabalhista (espelho, justificativas, PDF, hash/nsr).
- Estoque com PMP e fluxo de requisição completo — diferencial em editais de almoxarifado.
- Validação forte de documentos e consulta pública de CNPJ/CEP.
- Docs do app (`docs/arquitetura.md`, `docs/api.md`, `docs/autenticacao.md`, `docs/modulos.md`) bem estruturados.

### 3.2 Riscos e dívidas técnicas priorizados

| # | Sev. | Lado | Item | Impacto / Ação recomendada |
|---|---|---|---|---|
| R01 | **P0** | Back | ~~Segredos no repositório~~ **RESOLVIDO**: app Gmail removido; `application-prod.yml` e `application.yml` exigem `JWT_SECRET` via env (sem default hardcoded/sem `chronos-pulse-secret-key-...`); `docker-compose.yml` exige `SPRING_MAIL_USERNAME`/`SPRING_MAIL_PASSWORD`/`JWT_SECRET`; `application-test.yml` com segredo de teste; credenciais via secrets do Render/CI. Falta apenas o usuário **rotacionar a senha do Gmail** no Google (providenciar fora do código). |
| R02 | **P0** | App | ~~Tokens em texto plano no SharedPreferences~~ **RESOLVIDO**: `flutter_secure_storage ^11.0.0` + `core/security/session_storage.dart`; `AuthProvider` grava/ler/remove tokens via `SessionStorage` (Keystore/Keychain no nativo; fallback SharedPreferences apenas na Web — documentado). |
| R03 | **P0** | App | ~~Sem refresh automático / doc divergente~~ **RESOLVIDO**: `DioClient` reescrito com interceptor 401 → refresh único (dedupe via `_refreshing`) com retry único (`_retry`), excluindo login/refresh; `main.dart` conecta `onRefreshToken` → `SessionStorage` + `AuthProvider.restaurarSessaoAposRefresh` e `logout()` em falha; `docs/autenticacao.md` alinhado. |
| R04 | **P0** | Back | ~~IDOR/tenant frágil~~ **RESOLVIDO**: `ColaboradorController` exige `tenantId` no cadastro (usa o do token para não-plataforma; bloqueia tenant alheio) e resolve `tenantId` do token em listar/atualizar/excluir com `buscarPorIdETenant`; `EspelhoPontoController` e `ExportacaoFiscalController` filtram por tenant do usuário autenticado (`targetColaboradorId` só é aceito para papéis superiores; consultas sempre escopadas por tenant). |
| R05 | **P0** | Back | ~~Sem handler global de exceções~~ **RESOLVIDO**: `shared/web/GlobalExceptionHandler.java` (`@RestControllerAdvice`, `ApiError(status, mensagem, campos)`) mapeando 400/403/409/413/500. |
| R06 | **P0** | Back | ~~Exportação AEJ mockada~~ **RESOLVIDO**: `ExportacaoFiscalController` gera AEJ real via `GeradorArquivoAEJAdapter` a partir dos `RegistroPonto` persistidos (escopados por colaborador+tenant), com `colaboradorId` default = usuário logado. |
| R07 | **P1** | Back | ~~open-in-view true / sem transação~~ **RESOLVIDO**: `spring.jpa.open-in-view: false`; `@Transactional` nos `@Bean` dos `*ModuleConfig` multi-repositório (colaborador, empresa, auth; estoque já tinha). |
| R08 | **P1** | Back/App | ~~`double` para moeda~~ **RESOLVIDO**: backend usa `BigDecimal`; app padroniza moeda/números em `double` com **normalização no parse** (`_toDouble()` aceita `num` ou string com vírgula decimal — frota e **estoque**), **formatação pt-BR** (`_fmtNum` na frota; `NumberFormat.currency('pt_BR')` no espelho de saldos/exportações de estoque) e **envio com `,`→`.`** (`criarVeiculo`, `registrarAbastecimento`, `nova_entrada_dialog`). Na última revisão `EstoqueSaldoModel`/`MaterialModel`/`RequisicaoItemModel`/`CriarRequisicaoRequestDTO` passaram a normalizar `custoMedioUnitario`, `valorTotal`, `valorUnitario`, `estoqueMinimo`, `quantidadeAtual` e quantidades no `fromJson`/DTO, eliminando casts frágeis (`as num`). |
| R09 | **P1** | Back | ~~Sem locking otimista~~ **RESOLVIDO**: `@Version Long version` em `EstoqueSaldo` e `RegistroPontoJpaEntity` + migração `V14__add_version_optimistic_locking.sql`. |
| R10 | **P1** | App | ~~Sem modelos tipados na área admin~~ **RESOLVIDO**: `admin/data/models/admin_models.dart` tipa empresa/contrato/colaborador/evento/módulo/dashboard e `PaginatedResponse` (`core/network/paginated_response.dart`) normaliza `List` vs envelope `content` no cliente; datasource/repository/provider/screens migrados para modelos tipados. |
| R11 | **P1** | App | ~~Paginação fixa `page=0&size=100`~~ **RESOLVIDO (frota/patrimônio/protocolo)**: datasources agora paginam (`page`/`size`) via `PaginatedResponse` e as telas exibem "Carregar mais" (hasMore/totalPages). Admin permanece consulta integral (listas pequenas, sem endpoint paginado). |
| R12 | **P1** | App | ~~Ponto web não persiste offline~~ **RESOLVIDO**: `PontoLocalDataSource` passou a usar somente o `DatabaseHelper`, que já abre `IndexedDB` na Web via `sqflite_common_ffi` (removido o branch de memória `_webStorage`); registros offline sobrevivem ao reload. |
| R13 | **P1** | App | ~~IP fixo + cleartext~~ **RESOLVIDO**: `api_constants.dart` sem `192.168.1.14` (getter `apiUrlInformada`, `--dart-define=API_URL`); `AndroidManifest.xml` principal sem `usesCleartextTraffic`; cleartext apenas no `src/debug/AndroidManifest.xml` (com `tools:replace`). |
| R14 | **P1** | Back/App | ~~Sem trilha de auditoria~~ **RESOLVIDO**: tabela `tb_auditoria` (migração `V15__create_tabela_auditoria.sql`), entidade+repository+`AuditoriaService` (cadeia hash SHA-256, `REQUIRES_NEW`, gênese "GENESIS"); audita cadastro/atualização/exclusão de colaborador, login, ajuste de ponto, entradas/saídas de estoque, requisição (criar/aprovar/atender) e cadastro de contrato; `GET /api/v1/admin/auditoria` com CPF mascarado. |
| R15 | **P2** | Back/App | ~~LGPD ausente~~ **RESOLVIDO**: camada de privacidade completa — backend (`modules/privacidade`: `PrivacidadeService` + `PrivacidadeController` com `GET /politica`, `GET /meus-dados`, `POST /consentimento`, `DELETE /meus-dados`, migração `V16__create_consentimento_privacidade.sql`, consentimento vinculado a `cpc_id`+versão com `ip_origem` gravado, política v1.0 embutida, exportação omite `senhaHash` e mascara CPF, `anonimizarMeusDados` com auditoria `EXCLUSAO_DADOS_PESSOAIS` e `CpcUsuario.anonimizar()`; `GET /politica` aberto (`permitAll`)) e app (módulo `privacidade`: tela no menu principal e no nav do Admin com política, registro de consentimento, **exportar dados em JSON** via `FilePicker.saveFile` e **apagar/anonimizar dados** com confirmação + logout; DPO `privacidade@chronos-pulse.com.br`). Registro de operações é coberto pela auditoria do R14. | |
| R16 | **P2** | Back/App | ~~Cobertura de testes do app <10%~~ **RESOLVIDO (14%)**: CI criado nos 2 repos (backend: `.github/workflows/ci.yml` JDK 25 + `mvn -B clean verify` com `JWT_SECRET`; app: `subosito/flutter-action` + `flutter analyze/test/build apk --debug`); backend com 27 arquivos de teste / 89 testes verdes (ex.: tenant isolation, excluir colaborador, `AuditoriaService`, `GlobalExceptionHandler`, `PasswordPolicy`, `PrivacidadeService`). **App ampliado** de ~6 arquivos / 24 testes para **10 arquivos / 64 testes verdes** (cobertura linear ~14%): `CsvExport` (BOM UTF-8, separador `;`, aspas/escape), modelos/DTOS do estoque (moeda pt-BR, PMP), providers de frota/patrimônio/protocolo/privacidade com datasources fake (listagem, paginação, normalização `,`→`.`, erros amigáveis) e **widget tests** de telas críticas (Landing→Login; `PrivacidadeScreen`: política, consentimento e erro). Meta aspiracional de 60–80% segue como incremento contínuo nas próximas fases. |
| R17 | **P2** | App | ~~Exportações/relatórios limitados~~ **RESOLVIDO (CSV)**: util `CsvExport` (`core/utils/csv_export.dart`, `;` separador, BOM UTF-8, aspas escapadas) + exportação CSV no app para **patrimônio** (tombamento, descrição, categoria, estado, localização, valor, responsável, NF, observações), **protocolo** (recebidos/enviados — número, tipo, assunto, remetente, destinatário, data, status, responsável), **frota** (veículos e abastecimentos — placa, renavam, marca/modelo, combustível, status, odômetro, litros, valor/litro, posto) e **saldos de estoque** (almoxarifado, catmat, und., lote, validade, saldo físico, custo médio, valor total, estoque mínimo, situação). PDF de espelho de ponto já existia; arquivos por TCE permanecem na Fase de conformidade (roadmap 5.x). | |
| R18 | **P2** | Back/App | ~~Política de senha fraca / infos do analisador~~ **RESOLVIDO**: política de senha por papel no backend (`PasswordPolicy` — mínimo 6 p/ `COLABORADOR`, 8 p/ demais com maiúscula+minúscula+dígito+símbolo; aplicada em cadastro de colaborador, cadastro de empresa, alterar e redefinir senha) e **limpeza total das infos do analisador** (`withOpacity`→`.withValues(alpha:)` em 12 arquivos, `DropdownButton.value`→`initialValue` em 9 campos e `use_build_context_synchronously` no `home_ponto_screen` — `flutter analyze` = 0 issues). **i18n adiado por decisão de produto**: strings seguem hardcoded; será introduzido quando houver editais plurilíngues. | |

---

## 4. Conformidade legal e regulatória — matriz de status

| Norma / exigência | Status atual | Gap | Ação |
|---|---|---|---|
| **Portaria MTP 671/2021** (ponto eletrônico) | Parcial — espelho, PDF com referência à norma, justificativas obrigatórias, `nsr`/`hashLocal` no modelo, offline-first | **AEJ mockado**; sem integração com relógio homologado (REP)/protocolo de troca; marcação confia no relógio do dispositivo | Implementar AEJ real (AFD/AFDT futuri) e, se fornecer hardware, protocolo do relógio + validação de `nsr`/hash no servidor |
| **Lei 14.133/2021** (licitações e contratos) | Base de contratos/eventos existe (admin); **não há módulo de licitação** (ETP, termo de referência, edital, propostas, lances, julgamento, recursos, homologação, PNCP) | Módulo Licitações ausente | Cronograma Fase 3; revisar contrato para suportar saldos/empenho |
| **MCASP/STN** | PMP implementado no estoque (valoração correta por custo médio) | Sem **provisão para perdas** (deterioração/obsolescência), sem entrada via liquidação de **NFe vinculada a contrato/empenho** | Contabilização de ajustes + integração de entrada por NFe |
| **Decreto 9.373/2018** (desfazimento) | Patrimônio registra estado `INSERVIVEL` mas **sem fluxo formal** de baixa/cessão/transferência/alienação | Baixa com laudo/comissão | Fluxo de desfazimento na Fase de conformidade |
| **Tribunais de Contas** (e-TCE, SAGRES, TCE-MG, etc.) | Sem exportações padronizadas | Exportações específicas por TCE | Gerador flexível de arquivos CSV/XML por contrato |
| **LC 131/2009 + LAI (12.527/2011)** (transparência) | Sem portal | Portal da Transparência | Módulo futuro (roadmap longo) |
| **LGPD 13.709/2018** | Parcial → **camada de privacidade implementada** (R15): consentimento registrado (versão + IP), política v1.0, direito de exportar (portabilidade, JSON) e apagar/anonimizar dados, DPO, registro de operações pela auditoria (R14) | Notificação de incidente de segurança à ANPD e adoção de contrato de DPA (medidas organizacionais, fora do escopo de código) | Manter política vigente e tratar notificações/DPA na operação |
| **eSocial** | Não há integração | AFD/AFDT, eventos de jornada | Pós-conformidade de ponto |
| **e-MAG / WCAG** (acessibilidade) | Parcial (UX cuidada, sem Semantics avançadas/contraste/focus) | Níveis A/AA | Incremento contínuo |
| **SIAFIC/PCASP, NFS-e, tributário** | Não há | Módulos de contabilidade pública | Roadmap de longo prazo (não crítico para os primeiros editais) |

---

## 5. Roadmap de evolução

> Ordem inspirada na estratégia das anotações (Estoque público → Patrimônio → Compras/Contratos → Ponto/RH → Licitações → Contabilidade) **aplicada ao estado real do produto**, priorizando o que destrava os primeiros editais pequenos.

### Fase P0 — Blindagem e licitação SaaS (imediata; 2–3 semanas)
> Condições mínimas para comercializar o produto com segurança e não reprovar por falha de segurança em auditoria.
1. Rotacionar/remover segredos do git; `JWT_SECRET` e credenciais só via variáveis de ambiente (fail-fast em prod); revisar `docker-compose.yml`.
2. `flutter_secure_storage` para tokens; remover IP fixo; `--dart-define=API_URL` obrigatório; cleartext proibido fora de debug.
3. Interceptor de **refresh automático em 401** + atualizar `docs/autenticacao.md`.
4. `@ControllerAdvice` global com respostas consistentes.
5. **Corrigir IDOR/tenant** em `ColaboradorController`, `EspelhoPontoController` e demais rotas que recebem IDs sem validar vínculo.
6. `@Transactional` nos use cases de escrita; `open-in-view=false`.
7. `github/workflows/ci.yml` (lint, build, teste, analyze) como barreira de qualidade.
8. Testes de contrato/HTTP para as rotas mais críticas.

### Fase P1 — Auditoria e estabilidade (4–6 semanas)
1. **Trilha de auditoria inalterável**: tabela `auditoria (tenant_id, usuario_id, acao, entidade, id_entidade, antes, depois, data_hora, hash_chain)` registrada em todos os write paths; leitura restrita a papéis gestores.
2. `@Version` (locking otimista) em saldos de estoque e registros de ponto.
3. Moeda/quantidade em `BigDecimal`/centavos (estoque, frota, contratos).
4. Modelos tipados no admin; padronizar contrato de paginação no cliente.
5. **Persistência offline do ponto na web** (IndexedDB) e paginação real com "carregar mais".
6. Ampliar testes (providers, repos offline, endpoints; cobertura ≥60%).
7. Sanidade de dados: unicidade/índices nas tabelas de tenant; teste de fábrica de backup/restore no Postgres do Render.

### Fase P2 — Conformidade para editais de Almoxarifado + Ponto (2–3 meses)
> Alvo: atender integralmente um edital típico pequeno/médio (Câmara ou Prefeitura pequena) de **Estoque + Patrimônio + Ponto**.
1. **LGPD**: termos e consentimento no cadastro; direito de exclusão/exportação de dados pessoais; minimização; indicação de encarregado/DPO; registro de operações.
2. **AEJ real** com base nos registros persistidos; validação de `nsr`/`hashLocal` no servidor; (se aplicável) protocolo com relógio homologado.
3. **Decreto 9.373/2018**: fluxo de **desfazimento** de bens (laudo + comissão + baixa), nos estados OCIOSO/RECUPERÁVEL/ANTIECONÔMICO/IRRECUPERÁVEL.
4. **MCASP/almoxarifado**: entrada por termos de recebimento provisório/definitivo, provisão para perdas (vencimento/obsolescência), lote + validade + código de barras em entradas de materiais perecíveis.
5. **Exportações**: CSV/PDF auditáveis para estoque, patrimônio, frota, protocolo e relatório mensal de requisições (base para prestação de contas).
6. **Contratos**: reforçar saldo, vigência, alertas e histórico de eventos (base já existente) — requisito recorrente em editais.
7. Acessibilidade básica (contraste + `Semantics` em telas-chave).

### Fase P3 — Expansão para médios/grandes (4–8 meses)
1. **Módulo Licitações (Lei 14.133/2021)**: planejamento da contratação (ETP/TR), processos, editais, propostas, pregão eletrônico, julgamento, recursos, adjudicação/homologação, publicação em **PNCP**.
2. **Compras**: requisição de compra → cotação → fornecedor → pedido/AF → **entrada por NFe (XML webservice SEFAZ)** vinculada a contrato/empenho; banco de preços.
3. **Patrimônio avançado**: inventário com conferência via app (QR/código de barras), depreciados/transferência; integração com desfazimento.
4. **Portal da Transparência (LC 131)** e **BI/relatórios**.
5. **Contabilidade pública/SIAFIC, tributário e NFS-e** (roteiro de longo prazo, conforme anotações — não bloquear os primeiros editais).

### Marcos de negócio (vinculados às anotações de mercado)
- **MVP vendável (agora)**: Estoque + Almoxarifado + Ponto já competitivos em editais pequenos (ex.: faixa de R$ 12–95 mil/ano).
- Atestado técnico via primeiro edital → habilita concorrências maiores (R$ 200–900 mil de software SaaS).
- Meta: disputar editais de suíte parcial (Estoque + Patrimônio + Contratos + Ponto) após P2, e suíte ampla após P3.

---

## 6. Recomendações de curto prazo (próximas 48h)

1. **Rotacionar a senha do Gmail** (comprometida no repositório) e remover segredos do histórico/`docker-compose.yml`.
2. Corrigir a expiração de sessão com **refresh automático** e alinhar `docs/autenticacao.md`.
3. Aplicar as correções de tenant/autorização (R04) e `@ControllerAdvice` (R05) antes de qualquer apresentação a cliente.
4. Definir `JWT_SECRET`/`DATABASE_PASSWORD`/`MAIL_PASSWORD` no Render e remover os defaults.
5. Rodar `flutter analyze` e `mvn test` como gate contínuo e configurar o CI.

---

## Apêndice A — Inventário de migrations Flyway (V1–V16)

| Migration | Conteúdo |
|---|---|
| V1 | `registros_ponto` (base do ponto) |
| V2 | Auth/empresa/colaborador + `configuracao_jornada` |
| V3 | Seed inicial do admin (`admin@chronospulse.com.br`, tenant/usuários demo) |
| V4 | Módulo Estoque/Almoxarifado (materiais, saldos, movimentações, requisições) + almoxarifado |
| V5 | Papel `GESTOR_RH` e `acesso_estoque` |
| V6 | Ajuste manual + espelho de ponto |
| V7 | Contato de empresa + celular de colaborador |
| V8 | Contrato e contrato_evento |
| V9 | Seed founder/red-cape e configurações de jornada |
| V10 | E-mail/endereço/foto/recuperação de senha |
| V11 | Módulos de plataforma: patrimônio, frota, protocolo |
| V12 | Acesso por módulo no colaborador + data desligamento |
| V13 | Atualização do e-mail do admin por CPF (apoia a restauração da V3) |
| V14 | `version` (locking otimista) em `tb_estoque_saldo` e `registro_ponto` (R09) |
| V15 | Tabela `tb_auditoria` (trilha inalterável, cadeia SHA-256) (R14) |
| V16 | Tabela `tb_consentimento_privacidade` (consentimento LGPD por colaborador+versão, com IP de origem) (R15) |

> **Regra de ouro:** migrations **nunca** são editadas após aplicadas; qualquer correção de dado/schema exige nova versão.

## Apêndice B — Vetores de revisão pendentes confirmados

- **R01 (ação fora do código)**: rotacionar/revogar a senha de app do Gmail no Google (o vazamento foi removido do repositório).
- **R16**: cobertura de testes do app em ~14% (10 arquivos / 64 testes) — superou o <10%, mas segue abaixo da meta aspiracional de 60–80%; incremento contínuo nas próximas fases.