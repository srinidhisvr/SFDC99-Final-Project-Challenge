/**
 * @File Name          : FinalProjectHelper.cls
 * @Description        : 
 * @Author             : Srinidhi Srinivasaraghavan
 * @Group              : 
 * @Last Modified By   : Srinidhi Srinivasaraghavan
 * @Last Modified On   : 6/14/2020, 11:12:45 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/1/2020   Srinidhi Srinivasaraghavan     Initial Version
**/

public with sharing class FinalProjectHelper {
    
    /* Function returns a list of all account details including contacts, oppotunities and assignment history 
        associated with accounts passed as argument */
    public static List<Account> getAccountInfo(List<Account> accountList) {
        List<Account> accountDetails = new List<Account>();
        accountDetails =    [  SELECT   Id,
                                        OwnerId,
                                        BillingPostalCode,
                                        (
                                            SELECT  OwnerId 
                                            FROM    Contacts
                                        ),
                                        (
                                            SELECT  OwnerID 
                                            FROM    Opportunities
                                            WHERE   isClosed = False
                                        ),
                                        (
                                            SELECT  Changed_By__c,
                                                    New_Owner__c,
                                                    New_Territory__c,
                                                    Previous_Owner__c,
                                                    Previous_Territory__c,
                                                    Account__c
                                            FROM    Assignment_Histories__r
                                            ORDER BY CreatedDate DESC
                                            LIMIT 1
                                        ) 
                                FROM    Account 
                                WHERE   Id IN :accountList
                            ];
        return accountDetails;
    }

    //Get Account information for the zipcodes that are newly inserted into account/updated 
    //Call getAccountInfo function to get the detailed account information
    public static List<Account> getAccounts(List<Account> allAccountsChanged, map<Id,Account> mapOldAccounts) {
        List<Account> accountsWithPostalCodeChange = new List<Account>();
        List<Account> accContactOppInfo = new List<Account>();
        for(Account accountIterator:allAccountsChanged) {
            //Account Insertion - if the oldmap is Null, then add to list zipcodes of new accounts' inserted
            if(mapOldAccounts == null) {
                if(accountIterator.BillingPostalCode != NULL) {
                    accountsWithPostalCodeChange.add(accountIterator);
                }
            }
            /* Account updation - if the oldmap is not NULL, compare the values of zipcode in oldmap and new list
                to make sure only updated accounts' zipcodes are added to list */
            else {
                Account oldAcc = mapOldAccounts.get(accountIterator.Id);
                if((accountIterator.BillingPostalCode != NULL) && 
                    (oldAcc.BillingPostalCode != accountIterator.BillingPostalCode)) {
                        accountsWithPostalCodeChange.add(accountIterator);
                }
            } 
        }  
        //System.debug('accountsWithPostalCodeChange >>> ' + accountsWithPostalCodeChange);
        
        /* Only fetch account details, associated contacts, open opportunities 
            and assignment history for the accountsWithPostalCodeChange */
        accContactOppInfo = getAccountInfo(accountsWithPostalCodeChange);
        //System.debug('accContactOppInfo >>> ' + accContactOppInfo);
        return accContactOppInfo;
    }
    
    /* Create a map of territories - each territory zipcode/name tied to a list of territories 
        that has the same name but different owners */
    public static Map<String,List<Territory__c>> makeTerritoryMap(List<Territory__c> listOfTerritories) {
        Map<String,List<Territory__c>> mapOfTerritories = new Map<String,List<Territory__c>>();
        for(Territory__c territoryIterator: listOfTerritories) {
            List<Territory__c> tempList = new List<Territory__c>();
            if(mapOfTerritories.containsKey(territoryIterator.Name)) {
                tempList = mapOfTerritories.get(territoryIterator.Name);
                tempList.add(territoryIterator);
                mapOfTerritories.put(territoryIterator.Name,tempList);      
            }
            else {
                tempList.add(territoryIterator);
                mapOfTerritories.put(territoryIterator.Name,tempList);
            }
        }
        return mapOfTerritories;
    }

    /* For the territories inserted or changed in territory trigger get the relevant territories
        with the same zipcode - so as to get owners that could be assigned */
    public static Map<String,List<Territory__c>> getTerritoriesByName(List<Territory__c> listOfTerritoriesInTrigger) {
        List<Territory__c> listOfRelevantTerritories = new List<Territory__c>();
        Map<String,List<Territory__c>> mapOfTerritories = new Map<String,List<Territory__c>>();
        Set<String> territoryNames = new Set<String>();
        
        // Add to set all the zipcodes we need to fetch from Territory
        for(Territory__c territoryIterator: listOfTerritoriesInTrigger) {
            territoryNames.add(territoryIterator.Name);
        }
        
        // Get relevant territories for each zipcode in territoryNames
        listOfRelevantTerritories = [   SELECT  Name,
                                                OwnerId 
                                        FROM    Territory__c 
                                        WHERE   Name IN :territoryNames
                                    ];
        /* Create a map of territories - each territory zipcode/name tied to a list of territories 
            that has the same name but different owners */
        mapOfTerritories = makeTerritoryMap(listOfRelevantTerritories);
        
        return mapOfTerritories;
    }
    
    /* For the accounts billing postalcode inserted or changed in account trigger get the relevant territories
        with the same zipcode - so as to get owners that could be assigned */
    public static Map<String,List<Territory__c>> getTerritoriesByAccount(List<Account> accountsChanged, 
                                                                        Map<Id,Account> newMapOfBillingPostalCodes) {
        List<Territory__c> listOfTerritories = new List<Territory__c>();
        Map<String,List<Territory__c>> mapOfTerritories = new Map<String,List<Territory__c>>();
        Set<String> billingpostalcodes = new Set<String>();
        //System.debug('newmap>>>' +newMapOfBillingPostalCodes);

        // Add to set all the zipcodes we need to fetch from Territory
        for(Account accountIterator:accountsChanged) {
                Account newAcc = newMapOfBillingPostalCodes.get(accountIterator.Id);
                billingpostalcodes.add(newAcc.BillingPostalCode);
        }
        
        // Get relevant territories for each zipcode in territoryNames
        listOfTerritories = [   SELECT  Name,
                                        OwnerId 
                                FROM    Territory__c 
                                WHERE   Name IN :billingpostalcodes
                            ];
        //System.debug('listOfTerritories >>>' + listOfTerritories);
        
        /* Create a map of territories - each territory zipcode/name tied to a list of territories 
            that has the same name but different owners */
        mapOfTerritories = makeTerritoryMap(listOfTerritories);
        
        return mapOfTerritories;
    }

    //For the territories that have sales rep update, get all the accounts associated
    public static Map<id,Account> getAccountsForTerritory(Map<id,Territory__c> territoriesWithChanges) {
        Map<Id,Account> accountsCorrespondingToTerritories;
        List<String> territoryNames = new List<String>();
        List<Territory__c> territoryList = new List<Territory__c>();

        // Get territory list and from that, get territory names/zipcodes in another list
        if(territoriesWithChanges != null) {
            territoryList = territoriesWithChanges.values();
        }
        for(Territory__c territoryIterator:territoryList) {
            territoryNames.add(territoryIterator.Name);
        }
        //System.debug('territoryNames >>>' + territoryNames); 
        
        //This will become the newMapOfAccounts argument for the function ownerChange() -- for territory trigger
        accountsCorrespondingToTerritories = new Map<Id,Account>(
                                                                [  SELECT  Id,
                                                                            BillingPostalCode,
                                                                            OwnerId 
                                                                    FROM    Account 
                                                                    WHERE   BillingPostalCode IN :territoryNames
                                                                ]
                                                                );
        //System.debug('accountsCorrespondingToTerritories >>> ' + accountsCorrespondingToTerritories);
        return accountsCorrespondingToTerritories;     
    }

    //Owner change function for both account and territory triggers
    public static void ownerChange (List<Account> allAccountInfo, //account info with contacts,open opp & Assignment history
                                    Map<String,List<Territory__c>> associatedListOfTerritories, //map of territories
                                    Map<id,Account> newMapOfAccounts, //map of accounts with new changes
                                    String typeOfTrigger) //to check if 'territoryUpdate'/'accountInsert'/'accountUpdate'
                                    { 
        List<Contact> contactsToChange = new List<Contact>();
        List<Opportunity> oppsToChange = new List<Opportunity>();
        
        //For after insert account scenario, add to the below list and udpate the owner Id in this function
        List<Account> accListOwnerIdUpdate = new List<Account>(); 
        List<Assignment_History__c> assignmentHistoryList = new List<Assignment_History__c>();
                
        //System.debug('allAccountInfo >> ' +  allAccountInfo);
        //System.debug('newMapOfAccounts >> ' + newMapOfAccounts);
        //System.debug('associatedListOfTerritories >>>' + associatedListOfTerritories);
        
        for(Account accountIterator: allAccountInfo) {
            Account newAcc = new Account();
            Integer randomNumber;
            Assignment_History__c assignmentHistory = new Assignment_History__c();
            List<Territory__c> tempList = new List<Territory__c>();
            
            /* If there is territory update or account update and assignment history is non empty,
                we get the existing account from new map */
            if((typeOfTrigger.equals('territoryUpdate')) || (!(accountIterator.Assignment_Histories__r.isEmpty()))) {   
                newAcc = newMapOfAccounts.get(accountIterator.Id);

            /* Assignment history is empty - account after insert case or if no billing postal code 
                was given when account was created - so this is our first update with billing postal code, 
                we need to create a new instance of account so as to make the billing postal code 
                non-empty in our code flow */
            }
            else
                newAcc = new Account(
                                    Id=newMapOfAccounts.get(accountIterator.Id).Id,
                                    BillingPostalCode=newMapOfAccounts.get(accountIterator.Id).BillingPostalCode
                                    );
            //Common to all triggers
            //Get the list of territories associated with billing postal code into a tempList
            if(associatedListOfTerritories.containsKey(newAcc.BillingPostalCode)) {
                tempList= associatedListOfTerritories.get(newAcc.BillingPostalCode);
            }
            //Only if there is atleast 1 territory associated with the billing postal code, do owner changes
            //else do nothing
            if (!(tempList.isEmpty())) {
                /* System.debug('tempList >>>' + tempList); */
                
                //Select a random owner
                randomNumber = Integer.valueof((Math.random() * tempList.size()-1));
                
                //System.debug('tempList >>>' + tempList);
                //System.debug('randomNumber >>>' + randomNumber);
                
                /* If it goes back to the existing owner itself again, it still creates a new assignment history
                    to show that technically there was a re-run */
                newAcc.OwnerId = tempList[randomNumber].OwnerId;
                
                /* Adding back to the map in case it is not accountInsert - this is because, 
                    otherwise the original value was not getting updated properly when tested */
                if(!typeOfTrigger.equals('accountInsert'))
                    newMapOfAccounts.get(accountIterator.Id).OwnerId = newAcc.OwnerId;

                //Associate this owner with contacts of the account
                if(!(accountIterator.Contacts).isEmpty()) {
                    for(Contact contactIterator:accountIterator.Contacts) {
                        if(contactIterator.OwnerId != newAcc.OwnerId) {
                            contactIterator.OwnerId = newAcc.OwnerId;
                            contactsToChange.add(contactIterator);
                        }     
                    }
                }

                //Associate this owner with open opportunities of the account
                if(!(accountIterator.Opportunities).isEmpty()) {
                    for(Opportunity oppIterator:accountIterator.Opportunities) {
                        if(oppIterator.OwnerId != newAcc.OwnerId) {
                            oppIterator.OwnerId = newAcc.OwnerId;
                            oppsToChange.add(oppIterator);
                        } 
                    }
                } 

                /* Create an assignment history for account trigger - after insert scenario or
                    if this is the first time we are updating billing postal code from an empty value
                    ie. we didn't give billing postal code while creating the account */
                if((accountIterator.Assignment_Histories__r).isEmpty()) {
                    assignmentHistory.New_Owner__c = newAcc.OwnerId;
                    assignmentHistory.New_Territory__c = templist[randomNumber].Id;
                    assignmentHistory.Previous_Owner__c = null;
                    assignmentHistory.Previous_Territory__c = null;
                    assignmentHistory.Changed_By__c = UserInfo.getUserId();
                    assignmentHistory.Account__c = newAcc.Id;
                    assignmentHistoryList.add(assignmentHistory);
                    //Make sure to update the account owner change in account record for accountInsert scenario
                    //For accountUpdate trigger, it is automatically updated since before update is used
                    if(typeOfTrigger.equals('accountInsert'))
                        accListOwnerIdUpdate.add(newAcc);
                }
                /* If there is an existing assignment history, we create a new one and 
                    re-arrange values based on the old AH and new values */
                else {
                    //Only for territoryUpdate trigger, make sure to update the account owner change in the account record
                    //For accountUpdate trigger, it is automatically updated since before update is used
                    if(typeOfTrigger.equals('territoryUpdate'))
                        accListOwnerIdUpdate.add(newAcc);
                    Assignment_History__c tempOldValue = accountIterator.Assignment_Histories__r;
                    assignmentHistory.Previous_Owner__c = tempOldValue.New_Owner__c;
                    assignmentHistory.Previous_Territory__c = tempOldValue.New_Territory__c;
                    assignmentHistory.New_Owner__c = newAcc.OwnerId;
                    assignmentHistory.New_Territory__c = templist[randomNumber].Id;
                    assignmentHistory.Changed_By__c = UserInfo.getUserId();
                    assignmentHistory.Account__c = newAcc.Id;       
                    assignmentHistoryList.add(assignmentHistory);
                }
            }
            //System.debug(newMapOfAccounts.get(accountIterator.Id).OwnerId + ' >> new account owner is  >> '+ newAcc) ;
        }
        //Update account owner Id for 'accountInsert' & 'territoryUpdate' triggers
        if(!accListOwnerIdUpdate.isEmpty())
            update accListOwnerIdUpdate;
        //Update contact owner ID and opportunity owner ID changes
        if(!contactsToChange.isEmpty())
            update contactsToChange;
        if(!oppsToChange.isEmpty())
            update oppsToChange;
        //Insert the new assignment histories created
        if(!assignmentHistoryList.isEmpty()) {
            insert assignmentHistoryList;
        }
    }

    //For territory trigger, make sure not more than 3 owners are associated with 1 zipcode
    public static void checkZipInsertedWithOwnerNumber(List<Territory__c> territoriesInserted, Map<String,List<Territory__c>> mapOfTerritories, map<Id,Territory__c> mapOld) {
        for(Territory__c territoryIterator: territoriesInserted) {
            /* Only perform the check if the Name is changed. 
                To compare the old and new value of names, use oldMap in territory update trigger,
                if oldMap is null, then it is territory insert */
            boolean checkCondition = false;
            Territory__c oldTerritory = new Territory__c();
            List<Territory__c> tempList = new List<Territory__c>();
            if(mapOfTerritories.containsKey(territoryIterator.Name)) {
                tempList = mapOfTerritories.get(territoryIterator.Name);
                // Always check for territoryInsert trigger
                if(mapOld == null) {
                    checkCondition = true;
                }
                else {
                    /* For territoryUpdates, check if old Name & new Name are different and only check when true
                        It is possible that a territory is updated with a different Name and 
                        that Name could already have 3 territory records */
                    if(mapOld.containsKey(territoryIterator.id))
                        oldTerritory = mapOld.get(territoryIterator.Id);
                        if(territoryIterator.Name != oldTerritory.Name)
                            checkCondition = true;
                }

                //System.debug('tempList >>> ' + tempList);
                
                //If the flag checkCondition is marked true, then check the size, else do nothing
                if(checkCondition){
                    if(tempList.size() == 3)
                        territoryIterator.addError('Cannot add more Owners to zipCode'+territoryIterator.Name);
                }
            }
        }
    }

    /* Check and filter out territory updates (only for update trigger on territory)
        corresponding to only sales rep changes for a particular zipcode + particular unique territory id */
    public static Map<Id,Territory__c> checkIfOwnersChangedForZipCode(List<Territory__c> territoriesChanged, 
                                                                                Map<Id,Territory__c> oldMap) {
        //System.debug('Trigger.New >>>' + territoriesChanged);
        //System.debug('Old map >>> ' + oldMap);
        
        Map<Id,Territory__c> salesRepChange = new Map<Id,Territory__c>();
        for(Territory__c newValueChanged:territoriesChanged) {
            if(oldMap.containsKey(newValueChanged.Id)) {
                Territory__c oldValueCorrespondingToNewValue = oldMap.get(newValueChanged.Id);
                //System.debug('oldValueCorrespondingToNewValue >>>' + oldValueCorrespondingToNewValue);
                if((newValueChanged.OwnerId != oldValueCorrespondingToNewValue.OwnerId) &&
                    (newValueChanged.Name == oldValueCorrespondingToNewValue.Name)) {
                    //This means owner corresponding to this zipcode and unique ID has been edited
                    //Add this to salesRepChange map
                    salesRepChange.put(newValueChanged.Id,newValueChanged);
                }
            }
        }
        //System.debug('salesRepChange >>>' + salesRepChange);
        return salesRepChange;
    }
}
