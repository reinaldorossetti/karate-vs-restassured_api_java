# language: en
@login
Feature: User Authentication - Login

  Background:
    * url 'https://serverest.dev'
    * def FakerUtils = Java.type('serverest.utils.FakerUtils')
    * def randomProductName = function(){ return FakerUtils.randomProduct() }
    * def loginPayload = read('resources/loginPayload.json')
    * def randomEmail = function(){ return FakerUtils.randomEmail() }
    * def userEmail = randomEmail()
    * def userPassword = 'SenhaSegura@123'
    * def newUser =
      """
      {
        "nome": "#(userEmail)",
        "email": "#(userEmail)",
        "password": "#(userPassword)",
        "administrador": "false"
      }
      """

    Given path '/usuarios'
    And request newUser
    When method POST
    Then status 201

  @regression @smoke @login-success @ct01
  Scenario: CT01 - Perform login with valid credentials and validate token
    # Update login payload to use the created user's credentials
    Given path '/login'
    And request { email: "#(userEmail)", password: "#(userPassword)" }
    When method POST
    Then status 200
    * def message = response.message
    * def authToken = response.authorization

    And match message == 'Login realizado com sucesso'
    And match authToken == '#notnull'
    And match authToken == '#? _.length > 50'
    * print 'Generated Token:', authToken

  @regression
  Scenario: CT02 - Attempt login with invalid credentials
    * def invalidCredentials =
      """
      {
        "email": "usuario@inexistente.com",
        "password": "senhaerrada"
      }
      """
    
    Given path '/login'
    And request invalidCredentials
    When method POST
    Then status 401
    And match response.message == 'Email e/ou senha inválidos'
    And match response !contains { authorization: '#string' }


  @regression
  Scenario Outline: CT03 - Validate required fields on login
    * def incompleteData =
      """
      {
        "email": "<email>",
        "password": "<password>"
      }
      """
    
    Given path '/login'
    And request incompleteData
    When method POST
    Then status 400
    * if (!incompleteData.email) karate.match(response, { email: '#string' })
    * if (!incompleteData.password) karate.match(response, { password: '#string' })
    
    Examples:
      | email              | password |
      |                    | senha123 |
      | test@email.com     |          |
      |                    |          |

  @regression
  Scenario: CT04 - Login and use token to access a protected resource
    * def adminEmail = 'admin.' + new Date().getTime() + '@example.com'
    * def adminPassword = 'SenhaSegura@123'
    * def adminUser =
      """
      {
        "nome": "Admin User",
        "email": "#(adminEmail)",
        "password": "#(adminPassword)",
        "administrador": "true"
      }
      """

    Given path '/usuarios'
    And request adminUser
    When method POST
    Then status 201

    Given path '/login'
    And request { email: "#(userEmail)", password: "#(userPassword)" }    
    When method POST
    Then status 200
    * def message = response.message
    * def authToken = response.authorization
    And match message == 'Login realizado com sucesso'

    * def productName = randomProductName()
    * def newProduct =
      """
      {
        "nome": "#(productName)",
        "preco": 100,
        "descricao": "Produto gerado com Faker para teste de autenticação",
        "quantidade": 10
      }
      """
    
    Given path '/produtos'
    And header Authorization = authToken
    And request newProduct
    When method POST
    Then status 403
    And match response.message == "Rota exclusiva para administradores"
    And match response.message == '#string'

  @regression
  Scenario Outline: CT05 - Validate invalid email format
    * def invalidLogin = { "email": "<invalidEmail>", "password": "senha123" }
    
    Given path '/login'
    And request invalidLogin
    When method POST
    Then status 400
    And match response contains { email: '#string' }
    
    Examples:
      | invalidEmail     |
      | emailwithoutat   |
      | @noname.com      |
      | email@nodomain   |
      | email            |
      | 12345@test.c     |
      | !@#$%            |
