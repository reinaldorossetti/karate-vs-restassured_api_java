package serverest.exemplosvalidacoes;

import com.intuit.karate.junit5.Karate;

/**
 * Tests with practical examples of all possible JSON validations in Karate
 */
public class JsonValidationsTest {

    @Karate.Test
    Karate testAllValidations() {
        return Karate.run("JsonValidations").relativeTo(getClass());
    }

    @Karate.Test
    Karate testTypeValidation() {
        return Karate.run("JsonValidations")
                .tags("@type-validation")
                .relativeTo(getClass());
    }

    @Karate.Test
    Karate testSchemaValidation() {
        return Karate.run("JsonValidations")
                .tags("@schema-validation")
                .relativeTo(getClass());
    }

    @Karate.Test
    Karate testRegexValidation() {
        return Karate.run("JsonValidations")
                .tags("@regex-validation")
                .relativeTo(getClass());
    }
}
