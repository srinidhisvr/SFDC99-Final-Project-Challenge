/**
 * @File Name          : FinalProjectAccountTrigger.trigger
 * @Description        : 
 * @Author             : Srinidhi Srinivasaraghavan
 * @Group              : 
 * @Last Modified By   : Srinidhi Srinivasaraghavan
 * @Last Modified On   : 6/14/2020, 10:42:15 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/1/2020   Srinidhi Srinivasaraghavan     Initial Version
**/
trigger FinalProjectAccountTrigger on Account (after insert, before update) {
    if(Trigger.isInsert){
        //Get account information including related contacts, opportunities and assignment histories
        List<Account> allAccountInfo = FinalProjectHelper.getAccounts(Trigger.New,null);
        //Get the associated list of territories for the new/changed accounts' billing postal code
        Map<String,List<Territory__c>> associatedListOfTerritories = FinalProjectHelper.getTerritoriesByAccount(allAccountInfo,Trigger.newMap);
        //Call owner change function with an argument to identify account insertion
        FinalProjectHelper.ownerChange(allAccountInfo, associatedListOfTerritories,Trigger.newMap,'accountInsert');
    }
    else if(Trigger.isUpdate){
        //Get account information including related contacts, opportunities and assignment histories
        List<Account> allAccountInfo = FinalProjectHelper.getAccounts(Trigger.new,Trigger.oldMap);
        //Get the associated list of territories for the new/changed accounts' billing postal code
        Map<String,List<Territory__c>> associatedListOfTerritories = FinalProjectHelper.getTerritoriesByAccount(allAccountInfo,Trigger.newMap);
        //Call owner change function with an argument to identify account insertion
        FinalProjectHelper.ownerChange(allAccountInfo, associatedListOfTerritories,Trigger.newMap,'accountUpdate');
    }
}  