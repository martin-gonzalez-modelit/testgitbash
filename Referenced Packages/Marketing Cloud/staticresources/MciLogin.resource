	//This method lets you log into MC Home page
	function iLoginHome(etLink,apiUrl,sessId,lblMessage)
	{
		if(confirm(lblMessage))
		{			
			submitMCForm(getMCForm(etLink,sessId,apiUrl));
		}
		return false;
	}	
	
	//This method lets you log into Create New Email Page
	function iLoginNewEmail(etLink,apiUrl,sessId,lblMessage)
	{
		if(confirm(lblMessage))
		{
			var mcForm = getMCForm(etLink,sessId,apiUrl);
			mcForm.appendChild(setEntityType('Email'));
			mcForm.appendChild(setEntityAction('Create'));
			submitMCForm(mcForm);		    									
		}
		return false;
	}
	
	//This method lets you log into Edit Email Page
	function iLoginEditEmail(entityId,etLink,apiUrl,sessId,lblMessage)
	{
		if(confirm(lblMessage))
		{
			var mcForm = getMCForm(etLink,sessId,apiUrl);
			mcForm.appendChild(setEntityId(entityId));
			mcForm.appendChild(setEntityType('Email'));
			mcForm.appendChild(setEntityAction('Edit'));
			submitMCForm(mcForm);			
		}
		return false;
	}
	
	//Set Entity Type
	function setEntityType(entityTypeValue)
	{
		var entityType = document.createElement("input");
		entityType.setAttribute("type", "hidden");
		entityType.setAttribute("name", "entityType");
		entityType.setAttribute("value", entityTypeValue);		                        
		return entityType;  
	}
	
	//Set Entity Action	
	function setEntityAction(entityActionValue)
	{
		var entityAction = document.createElement("input");
		entityAction.setAttribute("type", "hidden");
		entityAction.setAttribute("name", "entityAction");
		entityAction.setAttribute("value", entityActionValue);
		return 	entityAction;
	}
	
	//Set Entity Id
	function setEntityId(entityIdValue)
	{
		var entityId = document.createElement("input");
		entityId.setAttribute("type", "hidden");
		entityId.setAttribute("name", "entityid");
		entityId.setAttribute("value", entityIdValue);	
		return entityId;            
	}
	
	//Set Session Id
	function setSessionId(sessionId)
	{
		var sessId = document.createElement("input");            
	    sessId.setAttribute("type", "hidden");
	    sessId.setAttribute("name", "sessid");            
	    sessId.setAttribute("value", sessionId);
	    return sessId; 
	}
	
	//Set Session Url
	function setSessionUrl(sessionUrl)
	{
		var sessUrl = document.createElement("input");            	    
	    sessUrl.setAttribute("type", "hidden");
	    sessUrl.setAttribute("name", "sessurl");                                   
	    sessUrl.setAttribute("value", sessionUrl );
	    return sessUrl; 
	}
	
	//Set Display Navi
	function setDisplayNavi(display)
	{
		var displayNavi = document.createElement("input");
	    displayNavi.setAttribute("type", "hidden");
	    displayNavi.setAttribute("name", "displaynavi");
	    displayNavi.setAttribute("value", display);	            	    	                            	               
	    return displayNavi; 
	}
			
	//Base Method which creates attributes common to all functionality.
	//All the attributes are attached to the form and returned.
	function getMCForm(etLink,sessId,apiUrl)
	{	
	    var mcForm = document.createElement("form");     		     		     			    
	    mcForm.setAttribute("method", "post");     		     	         		
	    mcForm.setAttribute("action", etLink +"sessurl=" + apiUrl);
	    mcForm.setAttribute("target", "_blank");     		            	     		            					                 
	    mcForm.appendChild(setSessionId(sessId));
	    mcForm.appendChild(setSessionUrl(apiUrl));	    	            	    	    
	    mcForm.appendChild(setDisplayNavi(false));             			     
	    return mcForm;
	}

	//Submits the given MC form	
	function submitMCForm(mcForm)
	{
		document.body.appendChild(mcForm);
	    mcForm.submit();
	}	