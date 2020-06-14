/**
 * @File Name          : territoryTrigger.trigger
 * @Description        : 
 * @Author             : Srinidhi Srinivasaraghavan
 * @Group              : 
 * @Last Modified By   : Srinidhi Srinivasaraghavan
 * @Last Modified On   : 6/14/2020, 10:47:26 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/1/2020   Srinidhi Srinivasaraghavan     Initial Version
**/
trigger territoryTrigger on Territory__c (before insert, before update) {
    
    //First check if there are only 3 people associated with 1 zipcode - common to insert and update
    Map<String,List<Territory__c>> mapOfTerritories = new Map<String,List<Territory__c>>();
    
    //Get territories in a map associated with each zipcode
    mapOfTerritories = FinalProjectHelper.getTerritoriesByName(Trigger.New);
    
    /* Check for number of people associated with each zipcode
        If the trigger is updated and the update is a name, not owner, we should make sure 
        we do nothing - so pass Trigger.oldmap for update scenario and null for insert scenario */
    if(Trigger.isInsert)
        FinalProjectHelper.checkZipInsertedWithOwnerNumber(Trigger.New,mapOfTerritories, null);    
    else if(Trigger.isUpdate) {
        FinalProjectHelper.checkZipInsertedWithOwnerNumber(Trigger.New,mapOfTerritories, Trigger.oldMap);
        
        /* If there is any update to sales rep for a particular zip code in an existing territory record,
            re-run owner change for associated account, accounts' contacts, open opportunities and 
            update assignment histories */
        
        //Filter out territory updates corresponding to only sales rep changes for a particular zipcode + particular unique territory id
        Map<Id,Territory__c> salesRepChange = FinalProjectHelper.checkIfOwnersChangedForZipCode(Trigger.New,Trigger.oldMap);
        
        //Get accounts corresponding to the above territories
        Map<Id,Account> accountsCorrespondingToTerritories = FinalProjectHelper.getAccountsForTerritory(salesRepChange);
        
        //Get detailed information for these accounts - contacts, opportunities and assignment histories
        List<Account> accountInfo = FinalProjectHelper.getAccountInfo(accountsCorrespondingToTerritories.values());
        
        //Make a territory map 
        Map<String,List<Territory__c>> listOfTerritories = FinalProjectHelper.makeTerritoryMap(salesRepChange.values());
        
        //Run owner change function again when sales rep changed for territory (originally run in Account trigger)
        FinalProjectHelper.ownerChange(accountInfo, listOfTerritories, accountsCorrespondingToTerritories,'territoryUpdate');
    }
}

