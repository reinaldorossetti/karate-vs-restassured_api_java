# language: pt
@produtos
Funcionalidade: Gerenciamento de Produtos (Requer Autenticação de Admin)

  Contexto:
    * url 'https://serverest.dev'
    * def loginResponse = call read('classpath:serverest/login/login.feature@login-reutilizavel')
    * def token = loginResponse.token
    * def randomName = function(){ return 'Produto ' + new Date().getTime() }

  @listar-produtos @smoke
  Cenario: Listar todos os produtos e validar estrutura JSON
    Dado caminho '/produtos'
    Quando método GET
    Então status 200
    
    E combina resposta ==
      """
      {
        quantidade: '#number',
        produtos: '#array'
      }
      """
    
    E combina cada resposta.produtos ==
      """
      {
        nome: '#string',
        preco: '#number',
        descricao: '#string',
        quantidade: '#number',
        _id: '#string'
      }
      """
    
    E combina cada resposta.produtos contains { preco: '#number? _ > 0' }
    
    E combina cada resposta.produtos contains { quantidade: '#number? _ >= 0' }


  @cadastrar-produto @smoke
  Cenario: Cadastrar novo produto como administrador
    * def nomeProduto = randomName()
    * def dadosProduto =
      """
      {
        "nome": "#(nomeProduto)",
        "preco": 250,
        "descricao": "Produto de teste automatizado",
        "quantidade": 100
      }
      """
    
    Dado caminho '/produtos'
    E header Authorization = token
    E request dadosProduto
    Quando método POST
    Então status 201
    
    E combina resposta ==
      """
      {
        message: 'Cadastro realizado com sucesso',
        _id: '#string'
      }
      """
    
    * def produtoId = resposta._id
    
    Dado caminho '/produtos/' + produtoId
    Quando método GET
    Então status 200
    E combina resposta.nome == nomeProduto
    E combina resposta.preco == 250
    E combina resposta.quantidade == 100


  @produto-duplicado
  Cenario: Validar erro ao cadastrar produto com nome duplicado
    * def nomeDuplicado = 'Produto Duplicado Test ' + new Date().getTime()
    * def produto =
      """
      {
        "nome": "#(nomeDuplicado)",
        "preco": 150,
        "descricao": "Primeiro produto",
        "quantidade": 50
      }
      """
    
    Dado caminho '/produtos'
    E header Authorization = token
    E request produto
    Quando método POST
    Então status 201
    
    Dado caminho '/produtos'
    E header Authorization = token
    E request produto
    Quando método POST
    Então status 400
    
    E combina resposta ==
      """
      {
        message: 'Já existe produto com esse nome',
        idProduto: '#string'
      }
      """


  @buscar-com-filtros
  Cenario: Buscar produtos usando query parameters
    Dado caminho '/produtos'
    E param nome = 'Logitech'
    Quando método GET
    Então status 200
    
    * def produtos = resposta.produtos
    * def todosContemNome = karate.filter(produtos, function(x){ return x.nome.includes('Logitech') })
    E combina todosContemNome.length > 0
    
    Dado caminho '/produtos'
    E param preco = 100
    Quando método GET
    Então status 200


  @atualizar-produto
  Cenario: Atualizar informações de um produto existente
    * def nomeProduto = randomName()
    * def produtoInicial =
      """
      {
        "nome": "#(nomeProduto)",
        "preco": 100,
        "descricao": "Descrição original",
        "quantidade": 50
      }
      """
    
    Dado caminho '/produtos'
    E header Authorization = token
    E request produtoInicial
    Quando método POST
    Então status 201
    * def produtoId = resposta._id
    
    * def produtoAtualizado =
      """
      {
        "nome": "#(nomeProduto)",
        "preco": 200,
        "descricao": "Descrição atualizada",
        "quantidade": 75
      }
      """
    
    Dado caminho '/produtos/' + produtoId
    E header Authorization = token
    E request produtoAtualizado
    Quando método PUT
    Então status 200
    E combina resposta.message == 'Registro alterado com sucesso'
    
    Dado caminho '/produtos/' + produtoId
    Quando método GET
    Então status 200
    E combina resposta.preco == 200
    E combina resposta.descricao == 'Descrição atualizada'
    E combina resposta.quantidade == 75


  @validacao-precos
  Cenario: Validar cálculos e comparações de preços
    Dado caminho '/produtos'
    Quando método GET
    Então status 200
    
    * def produtos = resposta.produtos
    * def precos = karate.map(produtos, function(x){ return x.preco })
    * def precoMaximo = Math.max.apply(null, precos)
    * print 'Preço mais alto:', precoMaximo
    
    * def precoMinimo = Math.min.apply(null, precos)
    * print 'Preço mais baixo:', precoMinimo
    
    * def somaPrecos = precos.reduce(function(a, b){ return a + b }, 0)
    * def precoMedio = somaPrecos / precos.length
    * print 'Preço médio:', precoMedio
    
    E combina cada produtos contains { preco: '#number? _ > 0 && _ < 100000' }


  @sem-autorizacao
  Cenario: Tentar cadastrar produto sem token de autenticação
    * def produto =
      """
      {
        "nome": "Produto Sem Auth",
        "preco": 100,
        "descricao": "Teste",
        "quantidade": 10
      }
      """
    
    Dado caminho '/produtos'
    E request produto
    Quando método POST
    Então status 401
    
    E combina resposta ==
      """
      {
        message: 'Token de acesso ausente, inválido, expirado ou usuário do token não existe mais'
      }
      """


  @validacao-campos
  Esquema do Cenário: Validar campos obrigatórios ao cadastrar produto
    * def produtoIncompleto =
      """
      {
        "nome": "<nome>",
        "preco": <preco>,
        "descricao": "<descricao>",
        "quantidade": <quantidade>
      }
      """
    
    Dado caminho '/produtos'
    E header Authorization = token
    E request produtoIncompleto
    Quando método POST
    Então status 400
    
    Exemplos:
      | nome              | preco | descricao | quantidade | motivo              |
      |                   | 100   | Desc      | 10         | Nome vazio          |
      | Produto Teste     | -10   | Desc      | 10         | Preço negativo      |
      | Produto Teste     | 100   |           | 10         | Descrição vazia     |
      | Produto Teste     | 100   | Desc      | -5         | Quantidade negativa |


  @json-complexo
  Cenario: Trabalhar com dados JSON complexos
    Dado caminho '/produtos'
    Quando método GET
    Então status 200
    
    * def produtosBaratos = karate.filter(resposta.produtos, function(x){ return x.preco < 100 })
    * def produtosMedios = karate.filter(resposta.produtos, function(x){ return x.preco >= 100 && x.preco < 500 })
    * def produtosCaros = karate.filter(resposta.produtos, function(x){ return x.preco >= 500 })
    
    * def agrupamento =
      """
      {
        barato: '#(produtosBaratos)',
        medio: '#(produtosMedios)',
        caro: '#(produtosCaros)'
      }
      """
    
    * print 'Produtos baratos:', produtosBaratos.length
    * print 'Produtos médios:', produtosMedios.length
    * print 'Produtos caros:', produtosCaros.length
    
    E combina agrupamento contains { barato: '#array', medio: '#array', caro: '#array' }


  @deletar-produto
  Cenario: Deletar um produto existente
    * def nomeProduto = randomName()
    * def produto =
      """
      {
        "nome": "#(nomeProduto)",
        "preco": 100,
        "descricao": "Produto para deletar",
        "quantidade": 10
      }
      """
    
    Dado caminho '/produtos'
    E header Authorization = token
    E request produto
    Quando método POST
    Então status 201
    * def produtoId = resposta._id
    
    Dado caminho '/produtos/' + produtoId
    E header Authorization = token
    Quando método DELETE
    Então status 200
    E combina resposta.message == 'Registro excluído com sucesso'
    
    Dado caminho '/produtos/' + produtoId
    Quando método GET
    Então status 400
    E combina resposta.message == 'Produto não encontrado'
