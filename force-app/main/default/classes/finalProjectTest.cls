/**
 * @File Name          : finalProjectTest.cls
 * @Description        : 
 * @Author             : Srinidhi Srinivasaraghavan
 * @Group              : 
 * @Last Modified By   : Srinidhi Srinivasaraghavan
 * @Last Modified On   : 6/14/2020, 11:36:45 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/13/2020   Srinidhi Srinivasaraghavan     Initial Version
**/
@isTest
public class finalProjectTest {
    
    // Create common users & territories
    @testSetup 
    static void setup() {
        finalProjectTestUtility.testUtilityUserCreator(4); //4 users
        finalProjectTestUtility.testUtilityTerritoryCreator(4,3); //4 Territories with 3 owners each
    }
    
    // Test Case 1: When account is inserted with billing postal code
    @isTest
    static void accBillingCodeFirstInputWithAccountInsertion() {
        //Create account with billing postal code
        finalProjectTestUtility.testUtilityAccountCreatorWithPostalCode();
        Account testAcc =   [   SELECT  Id,
                                        BillingPostalCode,
                                        OwnerId,
                                        (
                                            SELECT  Id
                                            FROM    Assignment_Histories__r
                                        )
                                FROM    Account
                                WHERE   Name Like 'test%'
                                LIMIT   1
                            ];
        //BillingPostalCode already inserted with account creation
        //Check if the owner is assigned to the right territory owner after insertion of account
        Set<Id> setOfOwnerIds = new Set<Id>();
        //Get the territories associated with the billing postal code inserted into a list
        List<Territory__c> listOfTerritoriesForPostalCode = new List<Territory__c>(
                                                                [   SELECT  Id,
                                                                            Name,
                                                                            OwnerId 
                                                                    FROM    Territory__c
                                                                    WHERE   Name=:testAcc.BillingPostalCode
                                                                ]
                                                            );
        //Get into a set, the owner Ids from territory records associated with billing postal code                                                    
        if(!listOfTerritoriesForPostalCode.isEmpty()) {
            for(Territory__c territoryIterator:listOfTerritoriesForPostalCode) {
                setOfOwnerIds.add(territoryIterator.OwnerId);
            }                                      
        }                  
        //Assert if the owner Id belongs to one of the ownerId values of the territories with same Name as billing postal code
        System.assert(setOfOwnerIds.contains(testAcc.OwnerId));	
        //Assert that assignment history is created
        System.assertEquals(1, testAcc.Assignment_Histories__r.size());
    }

    /* Test Case 2: When account is inserted without billing postal code and is first updated with a billing postal code
                    from an empty value */
    @isTest
    static void accBillingCodeFirstInputWithAccountUpdate() {
        //Create accounts, contacts and opportunities associated with that account
        finalProjectTestUtility.testUtilityAccountCreatorWithoutPostalCode(2,2,2);
        //For test case, updating all postalcodes to 90001
        String testPostalCode = '90001';
        List<Account> accToUpdate = new List<Account>();
        list<id> listUpdateAccIds = new list<id>();
        //Get all the test accounts
        List<Account> testAccs =    new List<Account>(
                                                        [   SELECT  Id,
                                                                    BillingPostalCode,
                                                                    OwnerId
                                                            FROM    Account
                                                            WHERE   Name Like 'test%'
                                                        ]
                                                    );
        //Update Account - give a billingPostalCode for the first time
        for(Account accIterator:testAccs) {
            //For test case, updating all postalcodes to 90001 and add to accToUpdate list
            accIterator.BillingPostalCode = testPostalCode;
            accToUpdate.add(accIterator);
        }
        //Get all the account Ids that are to be updated
        for(Account accIterator : accToUpdate){
            listUpdateAccIds.add(accIterator.Id);
        }
        
        Test.startTest();
        if(!accToUpdate.isEmpty())
            update accToUpdate; //Perform account update - should hit the trigger
        
        //Check if the owner is assigned to the right territory owner after insertion of account
        Set<Id> setOfOwnerIds = new Set<Id>();
        //Get the territories associated with testPostalCode
        List<Territory__c> listOfTerritoriesForPostalCode = new List<Territory__c>(
                                                                                    [   SELECT  Id,
                                                                                                Name,
                                                                                                OwnerId 
                                                                                        FROM    Territory__c
                                                                                        WHERE   Name=:testPostalCode
                                                                                    ]
                                                                                );
        //Get into a set, the owner IDs from the territories associated with the testPostalCode
        if(!listOfTerritoriesForPostalCode.isEmpty()) {
            for(Territory__c territoryIterator:listOfTerritoriesForPostalCode) {
                setOfOwnerIds.add(territoryIterator.OwnerId);
            }                                      
        }
        //Get the accounts after update using the Ids of the accounts updated
        List<Account> testAccsAfterUpdate =     new List<Account>(
                                                                    [   SELECT  Id,
                                                                                BillingPostalCode,
                                                                                OwnerId,
                                                                                (
                                                                                    SELECT  Id,OwnerId
                                                                                    FROM    Contacts
                                                                                ),
                                                                                (
                                                                                    SELECT  Id,OwnerId
                                                                                    FROM    Opportunities
                                                                                    WHERE   isClosed = False
                                                                                ),
                                                                                (
                                                                                    SELECT  Id
                                                                                    FROM    Assignment_Histories__r
                                                                                )
                                                                        FROM    Account
                                                                         WHERE   Id IN :listUpdateAccIds 
                                                                    ]
                                                                );
            Test.stopTest();
            //Perform assertions
            for(Account accIterator:testAccsAfterUpdate) {
                //Assert if the owner ID is in the set
                System.assert(setOfOwnerIds.contains(accIterator.OwnerId));
                //For each contact and open opportunity, assert that owner ID is the same as account's owner ID
                for(Contact conIterator:accIterator.Contacts)
                    System.assertEquals(accIterator.OwnerId,conIterator.OwnerId);
                for(Opportunity oppIterator:accIterator.Opportunities)
                    System.assertEquals(accIterator.OwnerId,oppIterator.OwnerId);
                //Assert if one Assignment history is created
                System.assertEquals(1, accIterator.Assignment_Histories__r.size());	
            }
        
    }

    // Test Case 3: When multiple updates to billing postal code is done
    @isTest
    static void accBillingCodeMultiUpdates() {
        //Create accounts, contacts and opportunities associated with that account
        finalProjectTestUtility.testUtilityAccountCreatorWithoutPostalCode(2,2,2);
        String testPostalCode1 = '90001';
        String testPostalCode2 = '90002';
        List<Account> testAccs =    new List<Account>(
                                                        [   SELECT  Id,
                                                                    BillingPostalCode,
                                                                    OwnerId
                                                            FROM    Account
                                                            WHERE   Name Like 'test%'
                                                        ]
                                                    );
        //Update Account - give a billingPostalCode for the first time
        for(Account accIterator:testAccs) {
            //For ease, updating all postalcodes to 90001
            accIterator.BillingPostalCode = testPostalCode1;
        }
        if(!testAccs.isEmpty())
            update testAccs; //first update

        for(Account accIterator:testAccs) {
            //For ease, updating all postalcodes to 90001
            accIterator.BillingPostalCode = testPostalCode2;
        }

        Test.startTest();
        if(!testAccs.isEmpty())
            update testAccs; //second update

        //Get list of accounts after updates
        List<Account> testAccsAfterUpdate = new List<Account>(
                                                                [  SELECT   Id,
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
                                                                                        New_Territory__r.Name,
                                                                                        Previous_Owner__c,
                                                                                        Previous_Territory__c,
                                                                                        Previous_Territory__r.Name,
                                                                                        Account__c
                                                                                FROM    Assignment_Histories__r
                                                                                ORDER BY CreatedDate DESC
                                                                            ) 
                                                                    FROM    Account 
                                                                    WHERE   Id IN :testAccs
                                                                ]
                                                            );
        Test.stopTest();
        Set<Id> setOfOwnerIds = new Set<Id>();
        //Get all the territories associated with both updates to check assignment history values
        List<Territory__c> listOfTerritoriesForPostalCode = new List<Territory__c>(
                                                                                    [   SELECT  Id,
                                                                                                Name,
                                                                                                OwnerId 
                                                                                        FROM    Territory__c
                                                                                        WHERE   Name=:testPostalCode1 
                                                                                                OR Name=:testPostalCode2
                                                                                    ]
                                                                                );
        Map<String,Set<Id>> mapOfPostalCodeToSetOfOwners = new Map<String,Set<Id>>();
        //Create a map of territory name to set of owner IDs for each
        for(Territory__c territoryIterator:listOfTerritoriesForPostalCode) {
            Set<Id> tempSet = new Set<Id>();
            if(mapOfPostalCodeToSetOfOwners.containsKey(territoryIterator.Name)){
                tempSet = mapOfPostalCodeToSetOfOwners.get(territoryIterator.Name);
            } 
            tempSet.add(territoryIterator.OwnerId);
            mapOfPostalCodeToSetOfOwners.put(territoryIterator.Name,tempSet);
        }

        //Perform assertions
        for(Account accIterator:testAccsAfterUpdate) {
            //Assert if owner set in the map contains the account's ownerID
            System.assert((mapOfPostalCodeToSetOfOwners.get(accIterator.BillingPostalCode)).contains(accIterator.OwnerId));
            //For each contact and open opportunity, assert if the ownerID is same as account's ownerID
            for(Contact conIterator:accIterator.Contacts)
                System.assertEquals(accIterator.OwnerId,conIterator.OwnerId);
            for(Opportunity oppIterator:accIterator.Opportunities)
                System.assertEquals(accIterator.OwnerId,oppIterator.OwnerId);
            //Assert the fields in the last 2 assignment histories
            System.assertEquals(accIterator.OwnerId, accIterator.Assignment_Histories__r[0].New_Owner__c);	
            System.assertEquals(accIterator.BillingPostalCode, accIterator.Assignment_Histories__r[0].New_Territory__r.Name);
            if(accIterator.Assignment_Histories__r.size()>1) {
                System.assertEquals(accIterator.Assignment_Histories__r[1].New_Owner__c, accIterator.Assignment_Histories__r[0].Previous_Owner__c);
                System.assertEquals(accIterator.Assignment_Histories__r[1].New_Territory__c, accIterator.Assignment_Histories__r[0].Previous_Territory__c);                    
            }
        }
    }

    // Test Case 4: When territories exceed 3 owners per name
    @isTest
    static void territoryExceedThreeOwnersPerName() {
        //We already have 3 owners per territory
        //Try adding 4th owner for zipcode 90001
        Territory__c newTerritory = new Territory__c(Name = '90001', OwnerId = UserInfo.getUserId());
        Test.startTest();
            try {
                insert newTerritory;
            }
            catch(Exception e) {
                //Assert if the error message contains the message we display in the code
                System.assertEquals(true, e.getMessage().contains('Cannot add more Owners'));
            }
        Test.stopTest();
    }

    // Test Case 5: When territory is updated for a particular name - existing territory is edited to change owner
    @isTest
    static void territoryUpdateOwnerForName() {
        //Create accounts, contacts and opportunities associated with that account
        finalProjectTestUtility.testUtilityAccountCreatorWithoutPostalCode(2,2,2);
        String testPostalCode = '90001';
        List<Account> testAccs =    new List<Account>(
                                                        [   SELECT  Id,
                                                                    BillingPostalCode,
                                                                    OwnerId
                                                            FROM    Account
                                                            WHERE   Name Like 'test%'
                                                        ]
                                                    );
        //Update Account - give a billingPostalCode for the first time
        for(Account accIterator:testAccs) {
            //For ease, updating all postalcodes to 90001
            accIterator.BillingPostalCode = testPostalCode;
        }
        if(!testAccs.isEmpty())
            update testAccs; //first account update
        //Get the accounts before territory update
        List<Account> testAccsBeforeTerritoryUpdate =    new List<Account>(
                                                                    [   SELECT      Id,
                                                                                    BillingPostalCode,
                                                                                    OwnerId,
                                                                                    (
                                                                                        SELECT      Id
                                                                                        FROM        Assignment_Histories__r
                                                                                        ORDER BY    CreatedDate DESC
                                                                                        LIMIT       1
                                                                                    )
                                                                        FROM        Account
                                                                        WHERE       Id IN :testAccs
                                                                        ORDER BY    Name
                                                                    ]
                                                                );
        //Now change one Territory with zipcode 90001 to a different owner (myself)
        Territory__c territoryToModify = new Territory__c();
        territoryToModify = [   SELECT  Name,
                                        OwnerId                                
                                FROM    Territory__c
                                WHERE   Name = :testPostalCode
                                LIMIT   1
                            ];
        territoryToModify.OwnerId = UserInfo.getUserId(); //Making myself the owner for test purposes
        
        Test.startTest();
        //Update the territory
        update territoryToModify;
        List<Account> testAccsAfterTerritoryUpdate =    new List<Account>(
                                                                            [   SELECT      Id,
                                                                                            BillingPostalCode,
                                                                                            OwnerId,
                                                                                            (
                                                                                                SELECT      Id
                                                                                                FROM        Assignment_Histories__r
                                                                                                ORDER BY    CreatedDate DESC
                                                                                                LIMIT       1
                                                                                            )
                                                                                FROM        Account
                                                                                WHERE       BillingPostalCode = :testPostalCode
                                                                                ORDER BY    Name
                                                                            ]
                                                                        );
        Test.stopTest();
        /* Assert if the size of the accounts before and after territory update are same -
            This means that the update was successful */
        System.assertEquals(testAccsBeforeTerritoryUpdate.size(), testAccsAfterTerritoryUpdate.size());
        for(Integer iterator = 0; iterator < testAccsBeforeTerritoryUpdate.size(); iterator++) {
            /* For each account, check if the assignment histories in the accounts before and after territory updates are different -
                This means that a new assignment history was created as part of the owner update function re-running */
            System.assertNotEquals((testAccsBeforeTerritoryUpdate[iterator]).Assignment_Histories__r[0].Id, 
                                    (testAccsAfterTerritoryUpdate[iterator]).Assignment_Histories__r[0].Id);
        }  
    }
}
