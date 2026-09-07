# ============================================================================
# CHRONOS PULSE - Jornadas de Teste (Frontend Flutter)
# Cenários no padrão Gherkin (Given-When-Then), derivados dos testes em /test
# Executar: flutter test
# ============================================================================

@frontend @ecossistema @autenticacao
Feature: Autenticação, Rede e Controle de Acesso (Frontend)
  Como usuário do Chronos Pulse
  Eu quero que a aplicação se comunique com a API de forma resiliente e respeite os perfis de acesso
  Para que eu receba mensagens claras em falhas e apenas veja funcionalidades permitidas ao meu perfil

  @api @config
  Scenario: A base da API aponta para um endpoint /api/v1 válido
    Given a aplicação é iniciada em qualquer plataforma (web, Android, iOS ou desktop)
    When a constante ApiConstants.baseUrl é consultada
    Then a URL retornada não é vazia
    And começa com "http://" ou "https://"
    And termina com "/api/v1"

  @api @config
  Scenario: Os endpoints principais são construídos corretamente
    Given as constantes de endpoint da aplicação
    When valido os caminhos padrão de rede
    Then o endpoint de login é "/auth/login"
    And o endpoint de sincronização de ponto é "/pontos/sincronizar"
    And o endpoint de materiais de estoque é "/estoque/materiais"

  @rede @falha
  Scenario: Falha de timeout de conexão exibe mensagem amigável
    Given o servidor demora além do tempo limite para responder
    When uma requisição HTTP é disparada pelo DioClient
    Then é lançada uma DioException com a mensagem "Tempo limite de conexão excedido"

  @rede @falha
  Scenario: Falha de conexão (servidor fora do ar ou CORS bloqueado) exibe mensagem amigável
    Given o servidor está inacessível (connection refused / CORS bloqueado)
    When uma requisição HTTP é disparada pelo DioClient
    Then é lançada uma DioException com a mensagem "Não foi possível conectar ao servidor"

  @rede @login @auth
  Scenario: Login com servidor inacessível repassa erro amigável ao usuário
    Given a conexão com o servidor falha
    When o usuário tenta autenticar informando CPF e senha
    Then o AuthRemoteDataSource lança uma Exception contendo "Não foi possível conectar ao servidor"

  @rede @login @auth
  Scenario: Credenciais inválidas retornam mensagem de erro específica
    Given o servidor está online
    And o CPF "12345678901" existe mas a senha informada está errada
    When o AuthRemoteDataSource.login é chamado com a senha "wrong"
    Then é lançada uma Exception contendo "CPF ou senha incorretos"

  @rbac
  Scenario: Perfil ADMIN_PLATAFORMA possui acesso irrestrito
    Given um usuário autenticado com role "ADMIN_PLATAFORMA"
    When os flags de permissão são avaliados no UsuarioModel
    Then isAdminPlataforma é verdadeiro
    And isAdminOrRh é verdadeiro
    And temAcessoEstoque é verdadeiro

  @rbac
  Scenario: Perfil GESTOR_RH possui acesso irrestrito a colaborador e estoque
    Given um usuário autenticado com role "GESTOR_RH" e sem flag de estoque explícita
    When os flags de permissão são avaliados no UsuarioModel
    Then isGestorRh é verdadeiro
    And isAdminOrRh é verdadeiro
    And temAcessoEstoque é verdadeiro

  @rbac @esteira
  Scenario: Colaborador sem flag de estoque não tem acesso ao módulo de estoque
    Given um usuário autenticado com role "COLABORADOR"
    And com flag acessoEstoque = false
    When os flags de permissão são avaliados no UsuarioModel
    Then isColaborador é verdadeiro
    And isAdminOrRh é falso
    And temAcessoEstoque é falso

  @rbac @estoque
  Scenario: Colaborador com flag de estoque ativa tem acesso ao módulo de estoque
    Given um usuário autenticado com role "COLABORADOR"
    And com flag acessoEstoque = true
    When os flags de permissão são avaliados no UsuarioModel
    Then isColaborador é verdadeiro
    And isAdminOrRh é falso
    And temAcessoEstoque é verdadeiro

@frontend @ui @landing @navegacao
Feature: Landing Page e Navegação para Login (Frontend)
  Como visitante do site
  Eu quero visualizar a apresentação da plataforma e acessar o login
  Para que eu possa me autenticar no sistema

  @ui
  Scenario: Landing page inicial deslogada renderiza marca, módulos e botão de login
    Given o aplicativo é iniciado sem sessão ativa
    When a tela de boas-vindas (Landing) é exibida
    Then o título "Chronos Pulse" está visível
    And a seção "Módulos da Plataforma" é renderizada
    And os módulos "Ponto Eletrônico & Espelho Digital", "Almoxarifado & Gestão Contábil" e "Gestão de Servidores & RBAC" estão presentes
    And existe um botão "Login" identificado pela chave "landing_appbar_login_button"

  @ui @navegacao
  Scenario: Clicar em Login navega para a tela de autenticação
    Given a Landing Page está exibida
    When o usuário clica no botão "Login" do app bar superior
    Then a tela LoginScreen é aberta
    And o botão de ação principal exibe o texto "Logar"
    And o texto "Acessar Sistema" não está presente
    And há exatamente 2 campos de texto (CPF e Senha)

@frontend @ponto @offline @sincronizacao
Feature: Registro de Ponto com Sensor de Conectividade (Frontend)
  Como colaborador
  Eu quero registrar batidas mesmo sem internet e sincronizar quando a conexão voltar
  Para que meus pontos nunca sejam perdidos

  @justificativas
  Scenario: A lista fornece as 8 justificativas obrigatórias
    Given o módulo de ponto está acessível
    When a lista de justificativas padronizadas é carregada
    Then existem exatamente 8 justificativas
    And incluem "Esquecimento de marcação", "Falha técnica", "Atividade externa", "Viagem a trabalho", "Trabalho remoto", "Atendimento médico", "Autorização da liderança" e "Plantão ou sobreaviso"

  @offline @sync
  Scenario: Ponto registrado offline fica pendente e sincroniza automaticamente ao voltar a conexão
    Given o servidor está offline (sem conexão)
    When o colaborador registra uma batida de ENTRADA
    Then o registro é salvo localmente como pendente (sincronizado = false)
    And o contador de pendentes passa a ser 1
    And o histórico do dia contém o registro
    Given o servidor volta a ficar online
    When o sensor de conectividade executa a checagem com auto-sincronização
    Then o status de conexão passa a online
    And o contador de pendentes volta a 0
    And o registro é marcado como sincronizado no histórico
    And o lote enviado ao servidor contém exatamente 1 registro

  @offline @sync
  Scenario: Sincronização manual processa lote acumulado de pontos
    Given o servidor está offline
    When o colaborador registra 2 pontos (ENTRADA e INTERVALO) sem conexão
    Then o contador de pendentes passa a ser 2
    Given o servidor volta a ficar online
    When o usuário dispara a sincronização manual
    Then o total sincronizado é 2
    And o contador de pendentes volta a 0
    And o status de conexão está online

  @ajuste @justificativa
  Scenario: Ajuste manual de ponto salva justificativa e atualiza o espelho
    Given o colaborador esqueceu de marcar um ponto
    When ele solicita o ajuste manual informando data/hora "03/09/2026 08:00", tipo ENTRADA, justificativa "Esquecimento de marcação" e observação "Cheguei no horário correto"
    Then o ajuste é registrado com sucesso
    And o histórico passa a conter 1 registro
    And o registro possui flag ajusteManual = verdadeiro
    And a justificativa salva é "Esquecimento de marcação"
    And a observação salva é "Cheguei no horário correto"

@frontend @cpf @util
Feature: Formatação e Validação de CPF (Frontend)
  Como usuário digitando CPF
  Eu quero que o campo aplique máscara progressiva e limite de 11 dígitos
  Para que o dado seja padronizado para envio

  @mascara
  Scenario: Máscara é aplicada progressivamente conforme a digitação
    Given o usuário digita dígitos em um campo de CPF
    When o formatador processa cada entrada
    Then "123" permanece "123"
    And "1234" vira "123.4"
    And "123456" vira "123.456"
    And "1234567" vira "123.456.7"
    And "123456789" vira "123.456.789"
    And "1234567890" vira "123.456.789-0"
    And "12345678901" vira "123.456.789-01"

  @mascara @limite
  Scenario: Entrada acima de 11 dígitos é truncada na máscara
    Given o usuário digita ou cola "1234567890199999"
    When o formatador processa a entrada
    Then o resultado é "123.456.789-01"

  @util
  Scenario: A função clean remove pontuação e caracteres não numéricos
    Given uma string com máscara ou caracteres inválidos
    When a função CpfInputFormatter.clean é aplicada
    Then "123.456.789-01" vira "12345678901"
    And "123-abc.456-789/01" vira "12345678901"
    And "" permanece ""

  @validacao
  Scenario: isValidLength valida 11 dígitos
    Given strings representando CPFs
    When a função CpfInputFormatter.isValidLength é aplicada
    Then "12345678901" é válido
    And "123.456.789-01" é válido
    And "1234567890" é inválido
    And "123456789012" é inválido
    And null é inválido

  @formcontroller
  Scenario: formatEditUpdate limita e formata durante a digitação
    Given um campo de texto que recebe "123456789019999"
    When o formatter formatEditUpdate processa o novo valor
    Then o texto resultante é "123.456.789-01"
    And o cursor é posicionado no índice 14

@frontend @estoque @modelos
Feature: Modelos do Módulo de Estoque (Frontend)
  Como aplicativo Flutter
  Eu quero deserializar corretamente os dados do backend de estoque
  Para que catálogo, saldos e requisições sejam exibidos com precisão

  @modelo
  Scenario: MaterialModel desserializa JSON de material corretamente
    Given um JSON de material com id, grupo, código CATMAT, descrição e unidade
    When o MaterialModel.fromJson é chamado
    Then o id é "mat-001"
    And o código CATMAT é "CAT-1001"
    And a descrição é "Papel A4 Sulfite"
    And a unidade de medida é "RESMA"
    And o estoque mínimo é 10.0

  @modelo @saldo
  Scenario: EstoqueSaldoModel calcula valor total e sinaliza estoque abaixo do mínimo
    Given um saldo com quantidade 5.0, custo médio 28.50 e estoque mínimo 10.0
    When o EstoqueSaldoModel.fromJson é chamado
    Then isAbaixoMinimo é verdadeiro
    And o valor total é 142.50
    Given um saldo com quantidade 20.0, custo médio 10.0 e estoque mínimo 5.0
    When o EstoqueSaldoModel.fromJson é chamado
    Then isAbaixoMinimo é falso
    And o valor total é 200.0

  @modelo @requisicao
  Scenario: RequisicaoModel desserializa itens corretamente
    Given um JSON de requisição com status PENDENTE e um item de 5.0 unidades de Papel A4
    When o RequisicaoModel.fromJson é chamado
    Then o id é "req-001"
    And o status é "PENDENTE"
    And há exatamente 1 item
    And a quantidade solicitada do primeiro item é 5.0

@frontend @colaborador @modelo
Feature: Serialização de Colaborador (Frontend)
  Como módulo de RH
  Eu quero mapear colaboradores vindos do backend
  Para que a listagem e a edição funcionem

  @modelo
  Scenario: ColaboradorModel desserializa campos com flag de estoque
    Given um JSON de colaborador com cpf, nome, matrícula e acesso ao estoque
    When o ColaboradorModel.fromJson é chamado
    Then o id é "colab-123"
    And o nome é "João Silva"
    And acessoEstoque é verdadeiro
    And ativo é verdadeiro