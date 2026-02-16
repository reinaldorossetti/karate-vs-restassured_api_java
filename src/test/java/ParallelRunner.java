import static org.junit.jupiter.api.Assertions.assertEquals;
import org.junit.jupiter.api.Test;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;

class ParallelRunner {

    @Test
    void testParallel() {
        Results results = Runner.path("classpath:serverest")
                .tags("~@ignore", "@regression")
                .outputJunitXml(true)          // Jenkins/CI integration
                .outputCucumberJson(true)      // Dashboard integration
                .reportDir("target/karate-reports")
                .parallel(6);  // 6 threads
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }

}