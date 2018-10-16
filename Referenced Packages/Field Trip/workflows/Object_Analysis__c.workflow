<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_Processing_Complete_Notification</fullName>
        <ccEmails>pge@modelit.xyz</ccEmails>
        <description>Send Processing Complete Notification</description>
        <protected>false</protected>
        <senderType>CurrentUser</senderType>
        <template>Field_Trip_Postcards/Processing_Completed</template>
    </alerts>
    <rules>
        <fullName>Processing Complete</fullName>
        <actions>
            <name>Send_Processing_Complete_Notification</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED( Last_Analyzed__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
