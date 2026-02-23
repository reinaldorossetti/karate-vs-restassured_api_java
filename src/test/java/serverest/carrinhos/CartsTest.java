package serverest.carrinhos;

import com.intuit.karate.junit5.Karate;

public class CartsTest {

    @Karate.Test
    Karate testCartsRegression() {
        return Karate.run("Carts")
                .tags("@carts")
                .relativeTo(getClass());
    }
}
