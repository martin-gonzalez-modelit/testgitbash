/*
*@author: Matias Medina
*/
global class TimeZonePlugin implements Process.Plugin {
	// This method runs when called by a flow's Apex plug-in element.
	global Process.PluginResult invoke(Process.PluginRequest request) {

		// Set up variables to store input parameters from the flow.
		String timeZone = (String) request.inputParameters.get('TimeZone');
		DateTime dateTimeValue = (DateTime) request.inputParameters.get('DateTimeVal');

		// Calculate the offset by passing it to a helper method.
		Map<String, Integer> result = new Map<String, Integer>();
		result = calculateOffset(timeZone, dateTimeValue);

		return new Process.PluginResult(result); 
	}
    
	/*This method describes the plug-in and its inputs from
	and outputs to the flow. Implementing this method adds the class to the 
	Cloud Flow Designer palette.*/
	global Process.PluginDescribeResult describe() {
		// Set up plugin metadata
		Process.PluginDescribeResult result = new 
		Process.PluginDescribeResult();
		result.description = 'Calculate the offset value from GMT in milliseconds.';
		result.tag = 'TimeZone Utility';
        
		//Create a list that stores both mandatory and optional input parameters from the flow.
		/*NOTE: Only primitive types (STRING, NUMBER, etc.) are supported at this time.
		Collections are currently not supported.*/ 
		result.inputParameters = new 
			List<Process.PluginDescribeResult.InputParameter>{
			// TimeZone (mandatory)
			new Process.PluginDescribeResult.InputParameter(
				'TimeZone', 
				Process.PluginDescribeResult.ParameterType.STRING, 
				true),
			// DateTimeVal (mandatory)
			new Process.PluginDescribeResult.InputParameter(
				'DateTimeVal', 
				Process.PluginDescribeResult.ParameterType.DateTime, 
				true)};

		// Create a list that stores output parameters sent 
		// to the flow.
		result.outputParameters = new List<Process.PluginDescribeResult.OutputParameter>{
			// Account ID of the converted lead
			new Process.PluginDescribeResult.OutputParameter('OffsetResult', 
			Process.PluginDescribeResult.ParameterType.Integer)              
		};

		return result;
	}
        
	/**
	* Get the offset for the given time zone.
	*/
	public Map<String, Integer> calculateOffset(String pTimeZone, DateTime pDateVal) {
		Map<String, Integer> result = new Map<String, Integer>();
		TimeZone myTz = TimeZone.getTimeZone(pTimeZone);
		Integer offset = myTz.getOffset(pDateVal);
		result.put('OffsetResult', offset);
		return result;
	}
        

}