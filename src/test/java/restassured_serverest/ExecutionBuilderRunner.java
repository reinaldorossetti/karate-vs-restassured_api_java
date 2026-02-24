package restassured_serverest;

import org.junit.platform.suite.api.ConfigurationParameter;
import org.junit.platform.suite.api.SelectClasses;
import org.junit.platform.suite.api.Suite;
import org.junit.platform.suite.api.SuiteDisplayName;

/**
 * JUnit 5 suite para executar em conjunto (e em paralelo, via Surefire)
 * os testes RestAssured de Login, Usuários, Produtos e Carrinhos.
 *
 * Para executar apenas esse suite:
 *   mvn test -Dtest=restassured.ExecutionBuilderRunner
 */
@Suite
@SuiteDisplayName("Run Projeto Serverest API Tests with RestAssured")
@SelectClasses({
    restassured_serverest.login.LoginRestAssuredTest.class,
    restassured_serverest.usuarios.UsersRestAssuredTest.class,
    restassured_serverest.produtos.ProductsRestAssuredTest.class,
    restassured_serverest.carrinhos.CartsRestAssuredTest.class
})

@ConfigurationParameter(key = "junit.jupiter.execution.parallel.config.strategy", value = "fixed")
@ConfigurationParameter(key = "junit.jupiter.execution.parallel.config.fixed.parallelism", value = "4")
public class ExecutionBuilderRunner {
}
