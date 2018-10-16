/**
 * This class associates a county object to an account if the city does match.
 *
 * @author Danny Teng <dteng@builditgreen.org>
 * @since 2012-03
 */
public class AccountServices {
    public static void setAccountCounty(Account[] contractors) {
        List<Account> updatedContractors = new List<Account>();
        for (Account acc : contractors) {
            if (acc.recordTypeId == Label.ContractorRT
                && (acc.billingcity != null)
                && !acc.billingcity.equals('')
                && (acc.billingstate != null)
                && !acc.billingstate.equals(''))
            {
                String thecity = acc.BillingCity.toUpperCase().trim();
                String thestate = acc.BillingState.toUpperCase().trim();
                for (County__c theCounty : [select name, city__c, state__c from County__c where state__c=:thestate]) {
                    String theCountyName = theCounty.name.toUpperCase().trim();
                    String theCountyCity = theCounty.city__c.toUpperCase().trim();
                    theCountyCity = theCountyCity.substring(0, theCountyCity.length());
                    if (theCountyCity.equals(thecity)) {
                        acc.county__c = theCounty.name;
                        updatedContractors.add(acc);
                    }
                }
            }
        }
    }
}