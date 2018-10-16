// Certain SalesForce acount types (specifically Professional Edition) do not allow web services requests. This function allows us to fall back on using 101 for those accounts in button triggered requests.
function invokeWithActOnServerUrl(func)
{
	var callback = 
	{ 
		onSuccess: function(result) 
		{ 
			func(result); 
		}, 
		onFailure: function() 
		{ 
			func("https://sf.actonsoftware.com"); 
		}
	} 
	sforce.apex.execute('ActOn/ActonWebService','getServerUrl',{}, callback);	
}
