/**
 * Test Methods related to  HUApplicationCancellation class to run a flow "HU_Application_Expiration_Automation".
 *
 * @author Matthew Souther <msouther@builditgreen.org>
 * @since 2017-11
 */
@isTest
public class HUApplicationCancellationTest {

    @isTest
    static void startFlowTest() {
        String faultMessage = HUApplicationCancellation.startFlow(true);

        System.assert(faultMessage == null || faultMessage == '');
    }

}