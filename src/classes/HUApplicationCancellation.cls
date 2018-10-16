/**
 * This class handles the execution of a flow called "HU_Application_Expiration_Automation".
 *
 * @author Matthew Souther <msouther@builditgreen.org>
 * @since 2017-11
 */
public class HUApplicationCancellation {

    public static String startFlow(Boolean logOnly) {
        Map<String, Object> flowOptions = new Map<String, Object> {'vLogOnly' => logOnly};

        Flow.Interview.HU_Application_Expiration_Automation myFlow =
                new Flow.Interview.HU_Application_Expiration_Automation(flowOptions);
        myFlow.start();

        return (String) myFlow.getVariableValue('vFaultMessage');
    }

}