/**
 * This class handles the schedule HUApplicationCancellation class to run a flow "HU_Application_Expiration_Automation".
 *
 * @author Matthew Souther <msouther@builditgreen.org>
 * @since 2017-11
 */
 public class HUApplicationCancellationScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        HUApplicationCancellation.startFlow(false);
    }
}