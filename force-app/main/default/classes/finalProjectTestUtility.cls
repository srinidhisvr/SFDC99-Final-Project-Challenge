/**
 * @File Name          : finalProjectTestUtility.cls
 * @Description        : 
 * @Author             : Srinidhi Srinivasaraghavan
 * @Group              : 
 * @Last Modified By   : Srinidhi Srinivasaraghavan
 * @Last Modified On   : 6/14/2020, 11:38:20 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/13/2020   Srinidhi Srinivasaraghavan     Initial Version
**/
@isTest
public with sharing class finalProjectTestUtility {
    //Create users for the test classes
    public static void testUtilityUserCreator(Integer numUsers) {
        List<User> testUserList = new List<User>();
        Profile testProfile =   [   SELECT  Id 
                                    FROM    Profile 
                                    WHERE   Name='Test Platform User'
                                ];
        for(Integer iterator = 0; iterator < numUsers; iterator++) {
            User testUser = new User(
                                    Alias='test'+iterator, Email='srinidhi.svr@gmail.com', 
                                    EmailEncodingKey='UTF-8', LastName='testUser'+iterator, LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId=testProfile.Id, 
                                    TimeZoneSidKey='America/Los_Angeles', UserName='testUser'+iterator+'@finalProject.com'
                                    );
            testUserList.add(testUser);
        }
        insert testUserList;
    }
    
    //Create territories for test classes
    public static void testUtilityTerritoryCreator(Integer numTerritories, Integer numOwnersForEachTerritory) {
        List<User> testUserList =   [   SELECT  Id
                                        FROM    User
                                        WHERE   UserName Like 'test%'
                                    ];
        List<Territory__c> testTerritoryList = new List<Territory__c>();
        
        //Ensure that you insert only maximum of 3 owners per territory
        for(Integer iterator = 0; iterator < numTerritories; iterator++) {
            Integer randomNumberGen = Integer.valueof((Math.random() * testUserList.size()-1));
            Set<Integer> randomNumber = new Set<Integer>();
            for(Integer owners = 0; owners < numOwnersForEachTerritory; owners++) {
                //This is performed so that the same owners aren't assigned each time
                while(randomNumber.contains(randomNumberGen))
                    randomNumberGen = Integer.valueof((Math.random() * testUserList.size()-1));
                randomNumber.add(randomNumberGen);
                Territory__c testTerritory = new Territory__c   (
                                                                Name='9000'+String.valueOf(iterator+1),
                                                                OwnerId=testUserList[randomNumberGen].Id
                                                                );
                testTerritoryList.add(testTerritory);
            }
        }
        insert testTerritoryList;
    }
    
    //Create account with billing postal code
    public static void testUtilityAccountCreatorWithPostalCode() {
            //Create only 1 account for testing postal code while insertion case
            //No need to create contact/opportunity as they remain unaffected during first insert
            Account testAcc = new Account   (
                                            Name='testAcc',
                                            BillingPostalCode = '90001'
                                            );
            insert testAcc;
    }

    //Create account without billing postal code along with contacts and open opportunities
    public static void testUtilityAccountCreatorWithoutPostalCode(Integer numAcc, Integer numContactForEachAcc, Integer numOppForEachAcc) {
        List<Account> listOfAccounts = new List<Account>();
        for(Integer iterator = 0; iterator < numAcc; iterator++) {
            Account testAcc = new Account   (
                                            Name='testAcc' + iterator
                                            );
            listOfAccounts.add(testAcc);
        }
        insert listOfAccounts;
        System.debug('listOfAccounts >>>' + listOfAccounts);

        List<Contact> listOfContacts = new List<Contact>();
        for(Integer iterator = 0; iterator < numAcc; iterator++) {
            Account testAcc = listOfAccounts[iterator];
            for(Integer contactIterator = 0; contactIterator < numContactForEachAcc; contactIterator++) {
            	Contact testCon = new Contact   (
                                                LastName='testCon' + iterator + contactIterator, 
                                                AccountId=testAcc.Id
                                                );
                listOfContacts.add(testCon);
        	}
        }
        insert listOfContacts;
        System.debug('listOfContacts >>>' + listOfContacts);

        List<Opportunity> listOfOpp = new List<Opportunity>();
        for(Integer iterator = 0; iterator < numAcc; iterator++) {
            Account testAcc = listOfAccounts[iterator];
            for(Integer oppIterator = 0; oppIterator < numOppForEachAcc; oppIterator++) {
                Opportunity testOpp = new Opportunity   (
                                                        Name='testOpp',
                                                        StageName='Prospecting',
                                                        CloseDate=System.Today()+10,
                                                        AccountId=testAcc.Id
                                                        );
                listOfOpp.add(testOpp);
        	}
    	}
        insert listOfOpp;
        System.debug('listOfOpps >>>' + listOfOpp);

	}
}
