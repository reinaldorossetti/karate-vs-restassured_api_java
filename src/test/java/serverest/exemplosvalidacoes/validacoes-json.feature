# language: pt
@exemplos-validacoes
Funcionalidade: Exemplos Completos de Validações JSON com Karate

  Contexto:
    * url 'https://serverest.dev'

  @validacao-tipos
  Cenario: Validar tipos de dados em JSON
    Dado caminho '/usuarios'
    Quando método GET
    Então status 200
    E combina resposta.quantidade == '#number'
    E combina resposta.usuarios == '#array'
    E combina resposta.usuarios[0].nome == '#string'
    E combina resposta.usuarios[0].administrador == '#string'
    E combina resposta.quantidade == '#notnull'
    E combina resposta.quantidade == '#present'
    E combina resposta.quantidade == '#number? _ > 0'
    E combina resposta.usuarios == '#[_ > 0]'


  @validacao-schema
  Cenario: Validar estrutura completa do JSON
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
    
    E combina cada resposta.usuarios ==
      """
      {
        nome: '#string',
        email: '#string',
        password: '#string',
        administrador: '#string',
        _id: '#string'
      }
      """
    
    E combina resposta contains
      """
      {
        quantidade: '#number'
      }
      """


  @validacao-regex
  Cenario: Usar expressões regulares para validar formatos
    Dado caminho '/usuarios'
    Quando método GET
    Então status 200
    * def usuario = resposta.usuarios[0]
    E combina usuario.email == '#regex .+@.+\\..+'
    E combina usuario.nome == '#regex ^[A-Za-zÀ-ÿ\\s]+$'
    E combina usuario._id == '#regex ^[A-Za-z0-9]+$'
    E combina usuario.administrador == '#regex ^(true|false)$'


  @validacao-arrays
  Cenario: Validações avançadas de arrays
    Dado caminho '/usuarios'
    Quando método GET
    Então status 200
    E combina resposta.usuarios == '#array'
    E combina resposta.usuarios == '#[10]'
    E combina resposta.usuarios == '#[_ > 0]'
    E combina resposta.usuarios == '#[_ >= 5]'
    E combina resposta.usuarios contains { administrador: 'true' }
    E combina cada resposta.usuarios contains { _id: '#string' }
    E combina resposta.usuarios[0] == '#object'
    * def ultimoIndex = resposta.usuarios.length - 1
    E combina resposta.usuarios[ultimoIndex] == '#object'

  @validacao-predicados
  Cenario: Usar predicados JavaScript para validações complexas
    Dado caminho '/produtos'
    Quando método GET
    Então status 200
    E combina cada resposta.produtos contains { preco: '#number? _ > 0' }
    E combina cada resposta.produtos contains { quantidade: '#number? _ >= 0' }
    E combina cada resposta.produtos contains { nome: '#string? _.length > 3' }
    E combina cada resposta.produtos contains { preco: '#number? _ > 0 && _ < 1000000' }
    
    * def produtos = resposta.produtos
    * def ids = karate.map(produtos, function(x){ return x._id })
    * def idsUnicos = new Set(ids)
    E combina ids.length == idsUnicos.size

  @validacao-contains
  Cenario: Validar presença e ausência de campos
    Dado caminho '/usuarios'
    Quando método GET
    Então status 200
    E combina resposta contains { quantidade: '#number' }
    E combina resposta contains { usuarios: '#array' }
    E combina resposta !contains { erro: '#string' }
    E combina resposta !contains { mensagemErro: '#string' }
    E combina cada resposta.usuarios contains { nome: '#string', email: '#string' }
    E combina cada resposta.usuarios !contains { cpf: '#string' }


  @validacao-only
  Cenario: Validar que JSON contém APENAS os campos especificados
    Dado caminho '/usuarios'
    Quando método GET
    Então status 200
    E combina resposta == { quantidade: '#number', usuarios: '#array' }
    E combina cada resposta.usuarios ==
      """
      {
        nome: '#string',
        email: '#string',
        password: '#string',
        administrador: '#string',
        _id: '#string'
      }
      """

  @validacao-jsonpath
  Cenario: Usar JSON Path para extrair e validar dados
    Dado caminho '/usuarios'
    Quando método GET
    Então status 200
    
    * def admins = karate.jsonPath(resposta, "$.usuarios[?(@.administrador=='true')]")
    * print 'Administradores encontrados:', admins.length
    E combina admins == '#array'
    
    * def emails = karate.jsonPath(resposta, "$.usuarios[*].email")
    * print 'Emails:', emails
    E combina emails == '#[] #string'
    
    * def primeiroUsuario = karate.jsonPath(resposta, "$.usuarios[0]")
    E combina primeiroUsuario == '#object'


  @validacao-javascript
  Cenario: Usar JavaScript para validações customizadas
    Dado caminho '/produtos'
    Quando método GET
    Então status 200
    
    * def produtosCaros = karate.filter(resposta.produtos, function(x){ return x.preco > 100 })
    * print 'Produtos caros:', produtosCaros.length
    
    * def nomesProdutos = karate.map(resposta.produtos, function(x){ return x.nome })
    * print 'Nomes dos produtos:', nomesProdutos
    
    * def precos = karate.map(resposta.produtos, function(x){ return x.preco })
    * def somaPrecos = precos.reduce(function(a, b){ return a + b }, 0)
    * print 'Soma total dos preços:', somaPrecos
    
    * def produtoExiste = resposta.produtos.some(function(x){ return x.nome.includes('Logitech') })
    * print 'Existe produto Logitech?', produtoExiste


  @validacao-fuzzy
  Cenario: Validações flexíveis (fuzzy matching)
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
    
    E combina cada resposta.usuarios contains
      """
      {
        nome: '#string',
        email: '#string'
      }
      """


  @validacao-valores
  Cenario: Comparar com valores esperados específicos
    * def emailEsperado = 'fulano@qa.com'
    
    Dado caminho '/usuarios'
    E param email = emailEsperado
    Quando método GET
    Então status 200
    
    * def usuario = resposta.usuarios[0]
    E combina usuario.email == emailEsperado
    E combina usuario contains { email: '#(emailEsperado)', administrador: 'true' }
    
    * def idEsperado = usuario._id
    E combina usuario._id == idEsperado


  @validacao-erros
  Cenario: Validar estrutura de mensagens de erro
    * def emailDuplicado = 'teste' + new Date().getTime() + '@test.com'
    * def usuario =
      """
      {
        "nome": "Teste",
        "email": "#(emailDuplicado)",
        "password": "senha123",
        "administrador": "true"
      }
      """
    
    Dado caminho '/usuarios'
    E request usuario
    Quando método POST
    Então status 201
    
    Dado caminho '/usuarios'
    E request usuario
    Quando método POST
    Então status 400
    E combina resposta ==
      """
      {
        message: '#string',
        idUsuario: '#string'
      }
      """
    
    E combina resposta.message == 'Este email já está sendo usado'


  @validacao-aninhada
  Cenario: Validar JSON com objetos aninhados complexos
    * def jsonComplexo =
      """
      {
        "usuario": {
          "nome": "João",
          "contato": {
            "email": "joao@test.com",
            "telefones": [
              { "tipo": "celular", "numero": "11999999999" },
              { "tipo": "residencial", "numero": "1133333333" }
            ]
          }
        }
      }
      """
    
    E combina jsonComplexo.usuario.nome == 'João'
    E combina jsonComplexo.usuario.contato.email == 'joao@test.com'
    E combina jsonComplexo.usuario.contato.telefones == '#[2]'
    E combina jsonComplexo.usuario.contato.telefones[0].tipo == 'celular'
    E combina cada jsonComplexo.usuario.contato.telefones contains { numero: '#string' }


  @validacao-numerica
  Cenario: Validações de comparações entre números
    Dado caminho '/produtos'
    Quando método GET
    Então status 200
    
    * def produto = resposta.produtos[0]
    
    E combina produto.preco > 0
    E combina produto.preco >= 0
    E combina produto.quantidade >= 0
    E combina produto.preco > 0 && produto.preco < 1000000
    E combina Math.floor(produto.quantidade) == produto.quantidade


  @validacao-combinada
  Cenario: Combinar múltiplas técnicas de validação
    Dado caminho '/usuarios'
    E param administrador = 'true'
    Quando método GET
    Então status 200
    
    E combina resposta contains { quantidade: '#number', usuarios: '#array' }
    E combina resposta.usuarios == '#[_ > 0]'
    E combina cada resposta.usuarios ==
      """
      {
        nome: '#string? _.length > 0',
        email: '#regex .+@.+\\..+',
        password: '#string',
        administrador: 'true',
        _id: '#string? _.length > 10'
      }
      """
    
    * def usuarios = resposta.usuarios
    * def todosAdmins = usuarios.every(function(x){ return x.administrador == 'true' })
    E combina todosAdmins == true
    * print '✅ Todas as validações passaram com sucesso!'
