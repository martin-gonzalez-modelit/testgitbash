/**
 * For each inbound email, this class inserts a Task (under Activity History) related to an email address
 * matching the email's to addressess and an sObject No. or record Id that is parsed from the email body,
 * to the indentified sObject/record. This class can be used with an Email Service
 * to save a record of sObject Notification emails sent via Workflow + Email Alert.
 *
 * @author Jordan Dunn <jdunn@builditgreen.org>
 * @since 2015-3
 */
public class InboundEmailTaskHandler implements Messaging.InboundEmailHandler {
    private static final Integer TASK_DESCRIPTION_MAX_LENGTH = Task.Description.getDescribe().getLength();
    private static final String WHITESPACE_DELIMITER = ' ';
    private static final Integer SPLIT_BODY_LENGTH = 50;

    /**
     * Regex that matches any string with 'ref' or 'ref:' optionally followed by any number of whitespaces and
     * necessarily followed by alphanumeric of length 15 characters.
     */
    private static final String REF_PREFIX_SOBJECT_ID_REGEX = '(?<=(?i)(ref|ref:)[\\p{Z}\\s]*)[^\\W_]{15}';

    /**
     * Regex that matches any string without 'ref' or 'ref:' optionally followed by any number of whitespaces and
     * necessarily followed by alphanumeric of length 15 characters.
     */
    private static final String SOBJECT_ID_REGEX = '(?<!(?i)(ref|ref:)[\\p{Z}\\s]*)\\b[^\\W_]{15}';

    /**
     * Create Task and Attachments related to sObject from email.
     *
     * @param email Received email that contains all information to create new data.
     * @param envelope Information associated with the inbound email.
     * @return Email result with success property that is true if was satisfactory or false if it wasn't.
     */
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email,
            Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        Boolean isPlainTextBody = false;
        String body;
        Id sObjectId;
        Schema.SObjectType sObjType;
        result.success = true;

        if (String.isNotBlank(email.htmlBody)) {
            body = email.htmlBody.stripHtmlTags();
        }
        if (String.isNotBlank(email.plainTextBody)) {
            if (String.isBlank(body)) {
                body = email.plainTextBody.stripHtmlTags();
            }
            isPlainTextBody = true;
        }

        String description = buildTaskDescription(email, isPlainTextBody);

        if (String.isNotBlank(body)) {
            Set<String> prefixSObjectAllowed = getPrefixSObjectAllowedForTaskWhatId();

            for (String sId : getSObjectIdMatches(body)) {
                if (prefixSObjectAllowed.contains(sId.substring(0, 3)) && BIGUtility.isValidSalesforceId(sId)) {
                    sObjectId = sId;
                    sObjType = sObjectId.getSObjectType();
                    break;
                }
            }
        }

        if (String.isNotBlank(sObjectId)) {
            Id contactId;

            try {
                // Get contact Id related to toAddresses from email.
                List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = :email.toAddresses LIMIT 2];

                // Use the contact that matches the email address to set the WhoId field.
                if (contacts.size() == 1) {
                    contactId = contacts.get(0).Id;
                } else {
                    // Get object API Name.
                    String sObjectName = sObjType.getDescribe().getName();

                    // Get all API names fields from related object.
                    List<Schema.DescribeSObjectResult> describeSObject = new List<Schema.DescribeSObjectResult>(
                            Schema.DescribeSObjects(new List<String> { sObjectName }));
                    Set<String> objectFields = new Set<String>(describeSObject.get(0).fields.getMap().keySet());

                    // If there are more than one match or no match, use ownerId from object or object parent.
                    // If object has ownerId field, use it to get the contact Id from User.
                    if (objectFields.contains('ownerid')) {
                        SObject sObj = Database.query('SELECT OwnerId FROM ' + sObjectName + ' WHERE Id = :sObjectId');
                        contactId = [SELECT ContactId FROM User WHERE Id = :(String)sObj.get('OwnerId')].ContactId;
                    } else {
                        String objectRelationshipName;
                        String objectRelationshipFieldName;

                        // Loop for each field object to get Master-Detail relationship data.
                        for (Schema.SObjectField sObjectField : sObjType.getDescribe().fields.getMap().Values()) {
                            // getRelationshipOrder() == 0 or 1 means is a Master-Detail relationship.
                            if (sObjectField.getDescribe().getRelationshipOrder() == 0
                                    || sObjectField.getDescribe().getRelationshipOrder() == 1) {
                                // Get object relationship name (__r).
                                objectRelationshipName = sObjectField.getDescribe().getRelationshipName();
                                // Get object relationship API name (__c).
                                objectRelationshipFieldName =
                                        String.valueOf(sObjectField.getDescribe().getSobjectField());
                            }
                        }

                        /**
                         * If object doesn't have ownerId field, use parent OwnerId from Master-Detail relationship
                         * to get the contact Id from User.
                         */
                        SObject sObjectChild = Database.query(''
                                + 'SELECT ' + objectRelationshipName + '.OwnerId '
                                + 'FROM ' + sObjectName + ' '
                                + 'WHERE Id = :sObjectId');

                        SObject sObjectParent = Database.query(''
                                + 'SELECT OwnerId '
                                + 'FROM ' + objectRelationshipFieldName + ' '
                                + 'WHERE Id = \''
                                + (String)sObjectChild.get(objectRelationshipFieldName) + '\'');

                        contactId = [
                            SELECT ContactId
                            FROM User
                            WHERE Id = :(String)sObjectParent.get('OwnerId')
                            ].ContactId;
                    }
                }
            } catch (Exception e) {
                System.debug('Can\'t get object from query. Error: ' + e.getMessage());
                System.debug('Stack trace: ' + e.getStackTraceString());
            }

            Boolean retry = false;

            do {
                // Insert Task.
                try {
                    Task task = new Task(
                        Type = 'Email',
                        TaskSubtype = 'Task',
                        Priority = 'Normal',
                        Status = 'Completed',
                        ActivityDate = Date.Today(),
                        Subject = 'Email: ' + email.subject,
                        Description = description,
                        IsRecurrence = false,
                        // Context user created by default.
                        OwnerID = UserInfo.getUserId(),
                        // Relate the Task to the object.
                        WhatId = sObjectId,
                        WhoId = contactId);
                    insert task;

                    retry = false;
                } catch (DMLException e) {
                    System.debug('Can\'t insert task or attachment. Error: ' + e.getMessage());
                    System.debug('Stack trace: ' + e.getStackTraceString());

                    if (e.getDmlType(0) == StatusCode.UNABLE_TO_LOCK_ROW) {
                        retry = lockRecord(e.getMessage());
                    } else {
                        retry = false;
                    }

                    if (!retry) {
                        result.success = false;
                        result.message = e.getMessage() + '\n\n\n\n' + description;
                    }
                }
            } while (retry);
        } else {
            result.success = false;
            result.message = 'We couldn\'t find a valid Salesforce Id. \n\n\n\n' + description;
        }

        // If there is an error on process, send an email with related information to Context User.
        if (!result.success) {
            notifyUser(result.message);
            // Set message to null so the sender does not get an exception email.
            result.message = null;
        }

        return result;
    }

    /**
     * Create description based on email information.
     *
     * @param email Received email that contains all information to create a description.
     * @param isPlainTextBody True if email body is a String, false if it is not.
     * @return Description created.
     */
    private String buildTaskDescription(Messaging.inboundEmail email, Boolean isPlainTextBody) {
        String description = '';

        if (!email.toAddresses.isEmpty()) {
            description += 'From: ' + email.fromAddress + '\n'
                    + 'To: ' + String.join(email.toAddresses, ', ') + '\n';
        }

        if (email.ccAddresses != null && !email.ccAddresses.isEmpty()) {
            description += 'Cc: ' + String.join(email.ccAddresses, ', ') + '\n';
        }

        // Assign Description.
        if (isPlainTextBody) {
            // Append plain text body to Description.
            description += ('\n' + email.plainTextBody);

            if (description.length() > TASK_DESCRIPTION_MAX_LENGTH) {
                description = description.substring(0, TASK_DESCRIPTION_MAX_LENGTH);
            }
        }

        return description;
    }

    /**
     * Get all prefix Ids allowed on WhatId field on Task.
     *
     * @return The prefix Ids allowed on WhatId field on Task.
     */
    private Set<String> getPrefixSObjectAllowedForTaskWhatId() {
        Set<String> prefixSObjectAllowed = new Set<String>();

        for(Schema.SObjectType objectReference : Schema.sObjectType.Task.fields.WhatId.getReferenceTo()) {
            prefixSObjectAllowed.add(objectReference.getDescribe().getKeyPrefix());
        }

        return prefixSObjectAllowed;
    }

    /**
     * Split string in order to get sobject ids separated by 'ref' or 'ref:' and alphanumeric characters.
     *
     * @param body The string to split.
     * @return A list with all the sobject ids extracted. If the expression doesn't match it returns an empty list.
     */
    private List<String> getSObjectIdMatches(String body) {
        List<String> matches = new List<String>();
        // Split a string of any size, while avoiding the dreaded 'Regex too complicated' error,
        // which the findMatches method causes on some large inputs.
        List<String> splittedBody = safeSplitString(body.trim());

        for (String s : splittedBody) {
            matches.addAll(BIGUtility.findMatches(SOBJECT_ID_REGEX, s));
        }

        for (String s : splittedBody) {
            matches.addAll(BIGUtility.findMatches(REF_PREFIX_SOBJECT_ID_REGEX, s));
        }

        // Reverses the result list so the latest occurrences have priority.
        BIGUtility.reverseList(matches);

        return matches;
    }

    /**
     * Splits the string into a list of lines, where each line has a maximum length of SPLIT_BODY_LENGTH.
     * Each line contains only full words (not broken).
     *
     * @param input The input line to split.
     * @return A list of lines extracted from the string. If the string is shorter than the maximum length defined
     *         returns the list with one single element, otherwise returns a list with multiple lines.
     */
    private List<String> safeSplitString(String input) {
        // If the string is not longer than the length limit, then just return a single list.
        if (input.length() < SPLIT_BODY_LENGTH) {
            return new List<String> { input };
        }

        List<String> result = new List<String> {''};
        Integer currentLength = 0;
        Integer index = 0;

        // This will cause any number of consecutive spaces to split the string into words.
        for (String word : input.split('\\s+')) {
            // +1 because the word will receive back the space in the end that it loses in split().
            Integer wordLength = word.length() + 1;

            // Check if the length of the current line does not exceeds the maximum length
            // and appends the word and space to the element in the list.
            // If the line's length exceeds the maximum length then we start a new line and add it to the list.
            if ((currentLength + wordLength) <= SPLIT_BODY_LENGTH) {
                result[index] = result.get(index) + word + WHITESPACE_DELIMITER;
                currentLength += wordLength;
            } else {
                result.add(word + WHITESPACE_DELIMITER);
                currentLength = wordLength;
                index++;
            }
        }

        return result;
    }

    /**
     * Holds the record lock for a very short period of time in order to sort the UNABLE_TO_LOCK_ROW exception when
     * inserting a new task record.
     *
     * @param input The input string containing a sObject id to be locked.
     * @return True if acquire the lock, otherwise false.
     */
    private Boolean lockRecord(String input) {
        Boolean locked = false;
        List<String> matches = BIGUtility.findMatches(SOBJECT_ID_REGEX, input);

        if (!matches.isEmpty()) {
            locked = BIGUtility.lockRecords(new List<Id> { matches.get(0) });
        }

        return locked;
    }

    /**
     * Send email to Email Service Context User, with related error.
     *
     * @param description Received email body.
     */
    private void notifyUser(String description) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setTargetObjectId(UserInfo.getUserId());
        mail.setSubject('InboundEmailTaskHandler Error');
        mail.setReplyTo('noreply@builditgreen.org');
        mail.setSenderDisplayName('System Admin');
        mail.setPlainTextBody(description);
        mail.setSaveAsActivity(false);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}