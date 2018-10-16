<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>TrackingAsOf</fullName>
        <field>Tracking_As_Of__c</field>
        <formula>LastModifiedDate</formula>
        <name>TrackingAsOf</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>true</protected>
    </fieldUpdates>
    <rules>
        <fullName>TrackingAsOfIER</fullName>
        <actions>
            <name>TrackingAsOf</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED(DateBounced__c) ||  ISCHANGED(DateOpened__c) ||  ISCHANGED(DateSent__c) ||  ISCHANGED(DateUnsubscribed__c) ||  ISCHANGED(NumberOfTotalClicks__c) ||  ISCHANGED(NumberOfUniqueClicks__c) ||  ISCHANGED(Opened__c) ||  ISCHANGED(SoftBounce__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
