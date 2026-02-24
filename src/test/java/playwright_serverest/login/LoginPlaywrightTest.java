package playwright_serverest.login;

import com.microsoft.playwright.APIResponse;
import com.microsoft.playwright.options.RequestOptions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.TestInstance.Lifecycle;
import org.junit.jupiter.api.parallel.Execution;
import org.junit.jupiter.api.parallel.ExecutionMode;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvFileSource;
import playwright_serverest.BaseApiTest;
import playwright_serverest.utils.FakerUtils;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@TestInstance(Lifecycle.PER_CLASS)
@Execution(ExecutionMode.CONCURRENT)
public class LoginPlaywrightTest extends BaseApiTest {

    private APIResponse createUser(String email, String password, boolean admin) {
        String payload = String.format("""
                {
                  "nome": "%s",
                  "email": "%s",
                  "password": "%s",
                  "administrador": "%s"
                }""", email, email, password, admin ? "true" : "false");

        return request.post("/usuarios", RequestOptions.create()
                .setHeader("Content-Type", "application/json")
                .setData(payload));
    }

    @Test
    @DisplayName("CT01 - Perform login with valid credentials and validate token")
    void ct01_loginWithValidCredentials() throws Exception {
        String email = FakerUtils.randomEmail();
        String password = "SenhaSegura@123";

        APIResponse createResp = createUser(email, password, false);
        assertEquals(201, createResp.status(), "User creation should return 201");

        String loginBody = String.format("""
                {"email": "%s", "password": "%s"}""", email, password);

        APIResponse loginResp = request.post("/login", RequestOptions.create()
                .setHeader("Content-Type", "application/json")
                .setData(loginBody));

        assertEquals(200, loginResp.status());

        @SuppressWarnings("unchecked")
        Map<String, Object> body = objectMapper.readValue(loginResp.body(), Map.class);
        assertEquals("Login realizado com sucesso", body.get("message"));
        assertNotNull(body.get("authorization"), "authorization token must not be null");
    }

    @Test
    @DisplayName("CT02 - Attempt login with invalid credentials")
    void ct02_loginWithInvalidCredentials() throws Exception {
        String body = """
                {
                  "email": "usuario@inexistente.com",
                  "password": "senhaerrada"
                }""";

        APIResponse resp = request.post("/login", RequestOptions.create()
                .setHeader("Content-Type", "application/json")
                .setData(body));

        assertEquals(401, resp.status());

        @SuppressWarnings("unchecked")
        Map<String, Object> responseBody = objectMapper.readValue(resp.body(), Map.class);
        assertEquals("Email e/ou senha inválidos", responseBody.get("message"));
        assertNull(responseBody.get("authorization"));
    }

    @DisplayName("CT03 - Validate required fields on login")
    @ParameterizedTest(name = "CT03 - Validate required fields on login")
    @CsvFileSource(resources = "/playwright/login/invalido-login.csv", numLinesToSkip = 1)
    void ct03_validateRequiredFields() throws Exception {
        // 1) Empty email, filled password
        APIResponse resp1 = request.post("/login", RequestOptions.create()
                .setHeader("Content-Type", "application/json")
                .setData("{\"email\": \"\", \"password\": \"senha123\"}"));
        assertEquals(400, resp1.status());
        @SuppressWarnings("unchecked")
        Map<String, Object> body1 = objectMapper.readValue(resp1.body(), Map.class);
        assertNotNull(body1.get("email"));

        // 2) Filled email, empty password
        APIResponse resp2 = request.post("/login", RequestOptions.create()
                .setHeader("Content-Type", "application/json")
                .setData("{\"email\": \"test@email.com\", \"password\": \"\"}"));
        assertEquals(400, resp2.status());
        @SuppressWarnings("unchecked")
        Map<String, Object> body2 = objectMapper.readValue(resp2.body(), Map.class);
        assertNotNull(body2.get("password"));

        // 3) Both empty
        APIResponse resp3 = request.post("/login", RequestOptions.create()
                .setHeader("Content-Type", "application/json")
                .setData("{\"email\": \"\", \"password\": \"\"}"));
        assertEquals(400, resp3.status());
        @SuppressWarnings("unchecked")
        Map<String, Object> body3 = objectMapper.readValue(resp3.body(), Map.class);
        assertNotNull(body3.get("email"));
        assertNotNull(body3.get("password"));
    }

    @Test
    @DisplayName("CT04 - Login and use token to access a protected resource")
    void ct04_loginAndUseTokenInProtectedRoute() throws Exception {
        String userEmail = FakerUtils.randomEmail();
        String userPassword = "SenhaSegura@123";

        APIResponse createResp = createUser(userEmail, userPassword, false);
        assertEquals(201, createResp.status());

        String loginBody = String.format("{\"email\": \"%s\", \"password\": \"%s\"}", userEmail, userPassword);

        APIResponse loginResp = request.post("/login", RequestOptions.create()
                .setHeader("Content-Type", "application/json")
                .setData(loginBody));
        assertEquals(200, loginResp.status());

        @SuppressWarnings("unchecked")
        Map<String, Object> loginBody2 = objectMapper.readValue(loginResp.body(), Map.class);
        assertEquals("Login realizado com sucesso", loginBody2.get("message"));
        String authToken = (String) loginBody2.get("authorization");

        // Attempt to access admin-only route with non-admin token
        String productName = FakerUtils.randomProduct();
        String productPayload = String.format("""
                {
                  "nome": "%s",
                  "preco": 100,
                  "descricao": "Product generated for auth test",
                  "quantidade": 10
                }""", productName);

        APIResponse productResp = request.post("/produtos", RequestOptions.create()
                .setHeader("Content-Type", "application/json")
                .setHeader("Authorization", authToken)
                .setData(productPayload));

        assertEquals(403, productResp.status());
        @SuppressWarnings("unchecked")
        Map<String, Object> productBody = objectMapper.readValue(productResp.body(), Map.class);
        assertEquals("Rota exclusiva para administradores", productBody.get("message"));
    }

    @ParameterizedTest(name = "CT05 - Validate invalid email format: {0}")
    @CsvFileSource(resources = "/playwright/login/invalid-login-emails.csv", numLinesToSkip = 1)
    @Execution(ExecutionMode.CONCURRENT)
    @DisplayName("CT05 - Validate invalid email format")
    void ct05_validateInvalidEmailFormat(String invalidEmail) throws Exception {
        String body = String.format("{\"email\": \"%s\", \"password\": \"senha123\"}", invalidEmail);

        APIResponse resp = request.post("/login", RequestOptions.create()
                .setHeader("Content-Type", "application/json")
                .setData(body));

        assertEquals(400, resp.status());
        @SuppressWarnings("unchecked")
        Map<String, Object> responseBody = objectMapper.readValue(resp.body(), Map.class);
        assertNotNull(responseBody.get("email"));
    }
}
