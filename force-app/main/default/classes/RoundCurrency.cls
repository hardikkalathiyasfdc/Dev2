public without sharing class RoundCurrency {
    
    private static long THOUSAND = 1000L;
    private static long MILLION = 1000000L;
    private static long BILLION = 1000000000L;
    private static long TRILLION = 1000000000000L;
    
    public static RoundAmount getRoundAmount (Double x) {
        return new RoundAmount (x);
    }
    
    private static String formatValue (Decimal d) {
        return d.format();
    }	
    
    public class RoundAmount {
        public String formattedAmount;
        public Decimal roundedAmount; 
        
        public RoundAmount (Double x) {
            if((roundedAmount = ((Decimal)(x/THOUSAND)).setScale(0)) < THOUSAND) {
                formattedAmount = formatValue(roundedAmount) + 'k';
                roundedAmount = roundedAmount * THOUSAND;
            } else if ((roundedAmount = ((Decimal)(x/MILLION)).setScale(1)) < THOUSAND) {
                formattedAmount = formatValue(roundedAmount) + 'M';
                roundedAmount = roundedAmount * MILLION;                
            } else {
                roundedAmount = ((Decimal)(x/BILLION)).setScale(2);
                formattedAmount = formatValue(roundedAmount) + 'B';
                roundedAmount = roundedAmount * BILLION;
            }
        }
    }
}