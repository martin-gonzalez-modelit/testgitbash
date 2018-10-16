/**
 * @author: Matias Medina
 */
@isTest
private class TestTimeZonePlugin {

    static testMethod void timeZonePluginTest() {
        // TO DO: implement unit test
        Map<String,Object> inputParams = new Map<String, Object>();
        Process.PluginResult result;
        TimeZonePlugin tmzp = new TimeZonePlugin();
        String key = 'OffsetResult';

        inputParams.put('TimeZone', 'America/Los_Angeles');
        inputParams.put('DateTimeVal', DateTime.now());

        Process.PluginRequest request = new Process.PluginRequest(inputParams);

        result = tmzp.invoke(request);
        system.assertNotEquals(null, result);
        system.assertEquals(true, result.outputParameters.containsKey(key));
    }
    
    static testMethod void testDescribe() {
        TimeZonePlugin tmzp = new TimeZonePlugin();
        Process.PluginDescribeResult pdr = tmzp.describe();
        System.assertEquals(2, pdr.inputParameters.size());
        System.assertEquals(1, pdr.outputParameters.size());
    }
}