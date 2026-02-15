# language: pt
@usuarios
Funcionalidade: Gerenciamento de Usuários - ServeRest API

  Contexto:
    * url 'https://serverest.dev'
    * def randomEmail = function(){ return 'user' + new Date().getTime() + '@test.com' }

  @listar @smoke
  Cenario: Listar todos os usuários e validar estrutura JSON
    Dado caminho '/usuarios'
    Quando método GET
    Então status 200
    E combina resposta ==
      """
      {
        quantidade: '#number',
        usuarios: '#array'
      }
      """
    
    E combina resposta.quantidade > 0
    E combina resposta.usuarios == '#[_ > 0]'
    E combina cada resposta.usuarios ==
      """
      {
        nome: '#string',
        email: '#regex .+@.+\\..+',
        password: '#string',
        administrador: '#string',
        _id: '#string'
      }
      """
    
    E combina cada resposta.usuarios contains { administrador: '#regex true|false' }
    
    * def primeiroUsuario = resposta.usuarios[0]
    * print 'Primeiro usuário:', primeiroUsuario


  @buscar-por-id
  Cenario: Buscar usuário específico por ID
    Dado caminho '/usuarios'
    Quando método GET
    Então status 200
    * def userId = resposta.usuarios[0]._id
    
    Dado caminho '/usuarios/' + userId
    Quando método GET
    Então status 200
    E combina resposta contains
      """
      {
        nome: '#present',
        email: '#present',
        _id: '#present'
      }
      """
    E combina resposta.nome == '#string'
    E combina resposta.email == '#string'
    E combina resposta._id == userId
    E combina resposta == { nome: '#string', email: '#string', password: '#string', administrador: '#string', _id: '#string' }


  @cadastrar @smoke
  Cenario: Cadastrar novo usuário com validações completas
    * def novoEmail = randomEmail()
    * def dadosUsuario =
      """
      {
        "nome": "João Silva",
        "email": "#(novoEmail)",
        "password": "senha@123",
        "administrador": "true"
      }
      """
    
    Dado caminho '/usuarios'
    E request dadosUsuario
    Quando método POST
    Então status 201
    E combina resposta.message == 'Cadastro realizado com sucesso'
    E combina resposta._id == '#string'
    E combina resposta._id == '#notnull'
    
    * def novoUserId = resposta._id
    
    Dado caminho '/usuarios/' + novoUserId
    Quando método GET
    Então status 200
    E combina resposta.nome == 'João Silva'
    E combina resposta.email == novoEmail


  @validacoes-avancadas
  Cenario: Validações avançadas de JSON com filtros
    Dado caminho '/usuarios'
    Quando método GET
    Então status 200
    
    * def admins = karate.filter(resposta.usuarios, function(x){ return x.administrador == 'true' })
    * print 'Total de administradores:', admins.length
    
    E combina admins == '#[_ > 0]'
    
    * def usuariosFiltrados = karate.jsonPath(resposta, "$.usuarios[?(@.administrador=='true')]")
    * print 'Usuários admin encontrados:', usuariosFiltrados.length
    
    * def emails = karate.map(resposta.usuarios, function(x){ return x.email })
    * print 'Lista de emails:', emails
    
    E combina emails == '#[] #string'


  @validacao-erro
  Cenario: Validar mensagens de erro ao cadastrar email duplicado
    * def emailDuplicado = randomEmail()
    * def usuario1 =
      """
      {
        "nome": "Usuário 1",
        "email": "#(emailDuplicado)",
        "password": "senha123",
        "administrador": "false"
      }
      """
    
    Dado caminho '/usuarios'
    E request usuario1
    Quando método POST
    Então status 201
    
    * def usuario2 =
      """
      {
        "nome": "Usuário 2",
        "email": "#(emailDuplicado)",
        "password": "outrasenha",
        "administrador": "true"
      }
      """
    
    Dado caminho '/usuarios'
    E request usuario2
    Quando método POST
    Então status 400
    
    E combina resposta ==
      """
      {
        message: 'Este email já está sendo usado',
        idUsuario: '#string'
      }
      """
    E combina resposta.idUsuario == '#notnull'


  @validacao-fuzzy
  Cenario: Validar com fuzzy matching (validação flexível)
    Dado caminho '/usuarios'
    E param administrador = 'true'
    Quando método GET
    Então status 200
    E combina resposta ==
      """
      {
        quantidade: '#number',
        usuarios: '#[]'
      }
      """
    E combina cada resposta.usuarios contains
      """
      {
        nome: '#string',
        email: '#string',
        administrador: 'true'
      }
      """


  @validacao-condicional
  Cenario: Validações condicionais baseadas em valores
    Dado caminho '/usuarios'
    Quando método GET
    Então status 200
    
    * def usuario = resposta.usuarios[0]
    * if (usuario.administrador == 'true') karate.log('Usuário é administrador')
    * if (usuario.administrador == 'false') karate.log('Usuário não é administrador')
    
    E combina usuario.email == '#? _.length > 5'
    E combina usuario.password == '#? _.length > 0'


  @validacao-arrays
  Cenario: Validações complexas de arrays
    Dado caminho '/usuarios'
    Quando método GET
    Então status 200
    E combina resposta.usuarios == '#[10]'
    E combina resposta.usuarios == '#[_ > 0]'
    E combina resposta.usuarios contains { administrador: 'true' }
    
    * def ids = karate.map(resposta.usuarios, function(x){ return x._id })
    * def idsUnicos = new Set(ids)
    E combina ids.length == idsUnicos.size


  @validacao-regex
  Cenario: Validar formatos com expressões regulares
    * def novoEmail = 'teste.regex.' + new Date().getTime() + '@example.com'
    * def dadosUsuario =
      """
      {
        "nome": "Teste Regex",
        "email": "#(novoEmail)",
        "password": "SenhaForte@123",
        "administrador": "false"
      }
      """
    
    Dado caminho '/usuarios'
    E request dadosUsuario
    Quando método POST
    Então status 201
    
    Dado caminho '/usuarios/' + resposta._id
    Quando método GET
    Então status 200
    E combina resposta.email == '#regex .+@.+\\..+'
    E combina resposta.nome == '#regex [A-Za-z\\s]+'
    E combina resposta._id == '#regex [A-Za-z0-9]+'


  @validacao-negativa
  Cenario: Validar ausência de campos
    Dado caminho '/usuarios'
    Quando método GET
    Então status 200
    E combina resposta !contains { error: '#string' }
    E combina resposta !contains { mensagemErro: '#string' }
    * def usuario = resposta.usuarios[0]
    E combina usuario !contains { cpf: '#string' }
    E combina usuario !contains { telefone: '#string' }


  @validacao-variaveis
  Cenario: Usar variáveis para validações dinâmicas
    * def emailEsperado = 'fulano@qa.com'
    * def nomeEsperado = 'Fulano da Silva'
    
    Dado caminho '/usuarios'
    E param email = emailEsperado
    Quando método GET
    Então status 200
    * def usuario = resposta.usuarios[0]
    E combina usuario.email == emailEsperado
    E combina usuario contains { email: '#(emailEsperado)', nome: '#string' }


  @validacao-json-aninhado
  Cenario: Preparar dados para validação de objetos aninhados
    * def dadosComplexos =
      """
      {
        "nome": "Usuário Complexo",
        "email": "#(randomEmail())",
        "password": "senha123",
        "administrador": "true"
      }
      """
    
    Dado caminho '/usuarios'
    E request dadosComplexos
    Quando método POST
    Então status 201
    E combina resposta ==
      """
      {
        message: '#string',
        _id: '#string'
      }
      """
    E combina resposta.message == 'Cadastro realizado com sucesso'
    E combina resposta._id == '#? _.length > 10'
