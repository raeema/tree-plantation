public with sharing class TreeListController {
    @AuraEnabled(cacheable=true)  //1231232424q123
    public static List<Tree__c> getAllTrees(){
        return [SELECT Id, Name, Benefit__c, Picture__c FROM Tree__c LIMIT 100];
    }
}
