@isTest
public class RoundCurrency_Test {

    @isTest
    static void roundCurrencyTest () {
        Double amount = 99999;
        Double amount2 = 999999;
        Double amount3 = 999999999;
        System.assertEquals ('100k',RoundCurrency.getRoundAmount(amount).formattedAmount);
        System.assertEquals ('1M',RoundCurrency.getRoundAmount(amount2).formattedAmount);
        System.assertEquals ('1B',RoundCurrency.getRoundAmount(amount3).formattedAmount);
    }
}