trigger UpdateContractorCounty on Account (before insert, before update) {
		AccountServices.setAccountCounty(Trigger.new); 
}