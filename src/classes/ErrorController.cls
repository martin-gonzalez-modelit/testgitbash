public class ErrorController{
    public PageReference landingAction(){
        System.debug('ERROR MESSAGE: ' + Site.getErrorMessage());
        System.debug('ERROR DESCRIPTION: ' + Site.getErrorDescription());
        return null;
    }
}