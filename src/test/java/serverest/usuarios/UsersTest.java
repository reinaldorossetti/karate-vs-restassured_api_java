package serverest.usuarios;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 test class to run User tests
 *
 * Execution examples:
 * - Run all tests: mvn test
 * - Run only this class: mvn test -Dtest=UsuariosTest
 * - Run by tags: mvn test -Dkarate.options="--tags @smoke"
 */
public class UsersTest {

    /**
     * Executes all scenarios from the Users.feature feature
     */
    @Karate.Test
    Karate testUsers() {
        return Karate.run("Users").relativeTo(getClass());
    }

    /**
     * Executes only the tests tagged with @smoke
     */
    @Karate.Test
    Karate testSmoke() {
        return Karate.run("Users")
                .tags("@smoke")
                .relativeTo(getClass());
    }

    /**
     * Executes specific tests by tag
     */
    @Karate.Test
    Karate testValidations() {
        return Karate.run("Users")
                .tags("@error-validation,@regex-validation")
                .relativeTo(getClass());
    }
}
