<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>PopulateTSBackupWorkflow</fullName>
        <field>BackupWorkflow__c</field>
        <formula>now()+(1/288)</formula>
        <name>PopulateTSBackupWorkflow</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UnpopulateTSBackupWokflow</fullName>
        <field>BackupWorkflow__c</field>
        <name>UnpopulateTSBackupWokflow</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>PopulateTrigSendBackupWorkflow</fullName>
        <actions>
            <name>PopulateTSBackupWorkflow</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>hasDelayedSends__c &amp;&amp; ISBLANK( BackupWorkflow__c ) &amp;&amp; Active__c</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
