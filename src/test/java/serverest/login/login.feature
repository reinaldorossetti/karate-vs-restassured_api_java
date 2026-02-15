# language: pt
@login
Funcionalidade: Autenticação de Usuários - Login

  Contexto:
    * url 'https://serverest.dev'

  @login-sucesso @smoke
  Cenario: Realizar login com credenciais válidas e validar token
    * def credenciais =
      """
      {
        "email": "fulano@qa.com",
        "password": "teste"
      }
      """
    
    Dado caminho '/login'
    E request credenciais
    Quando método POST
    Então status 200
    
    E combina resposta ==
      """
      {
        message: '#string',
        authorization: '#string'
      }
      """
    
    E combina resposta.message == 'Login realizado com sucesso'
    
    E combina resposta.authorization == '#notnull'
    E combina resposta.authorization == '#? _.length > 50'
    
    * def authToken = resposta.authorization
    * print 'Token gerado:', authToken


  @login-invalido
  Cenario: Tentar login com credenciais inválidas
    * def credenciaisInvalidas =
      """
      {
        "email": "usuario@inexistente.com",
        "password": "senhaerrada"
      }
      """
    
    Dado caminho '/login'
    E request credenciaisInvalidas
    Quando método POST
    Então status 401
    E combina resposta.message == 'Email e/ou senha inválidos'
    E combina resposta !contains { authorization: '#string' }


  @validacao-campos-obrigatorios
  Esquema do Cenário: Validar campos obrigatórios no login
    * def dadosIncompletos =
      """
      {
        "email": "<email>",
        "password": "<password>"
      }
      """
    
    Dado caminho '/login'
    E request dadosIncompletos
    Quando método POST
    Então status 400
    E combina resposta contains { email: '#string' }
    
    Exemplos:
      | email              | password |
      |                    | senha123 |
      | teste@email.com    |          |
      |                    |          |


  @login-e-usar-token
  Cenario: Fazer login e usar token para acessar recurso protegido
    * def credenciais = { "email": "fulano@qa.com", "password": "teste" }
    
    Dado caminho '/login'
    E request credenciais
    Quando método POST
    Então status 200
    * def token = resposta.authorization
    
    * def novoProduto =
      """
      {
        "nome": "Produto Auth Test",
        "preco": 100,
        "descricao": "Produto de teste com autenticação",
        "quantidade": 10
      }
      """
    
    Dado caminho '/produtos'
    E header Authorization = token
    E request novoProduto
    Quando método POST
    Então status 201
    E combina resposta.message == 'Cadastro realizado com sucesso'


  @validacao-formato-email
  Esquema do Cenário: Validar formato de email inválido
    * def loginInvalido = { "email": "<emailInvalido>", "password": "senha123" }
    
    Dado caminho '/login'
    E request loginInvalido
    Quando método POST
    Então status 400
    E combina resposta contains { email: '#string' }
    
    Exemplos:
      | emailInvalido    |
      | emailsemarroba   |
      | @semnome.com     |
      | email@semdominio |
      | email            |


  @login-reutilizavel
  Cenario: Login reutilizável para outros testes
    * def credenciais = { "email": "fulano@qa.com", "password": "teste" }
    
    Dado caminho '/login'
    E request credenciais
    Quando método POST
    Então status 200
    
    * def token = resposta.authorization
    * def mensagem = resposta.message
