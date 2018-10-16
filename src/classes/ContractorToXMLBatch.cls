/**
 * This class handles the batch process for creating Contractor Resources XML.
 *
 * @author Maiquel Cabrera <maiquel.cabrera@modelitsoftware.com>
 * @author Jordan Dunn <jdunn@builditgreen.org>
 * @since 2014-02
 */
global class ContractorToXMLBatch implements Database.Batchable<sObject>, Database.Stateful {

    private static final String NAMESPACE = 'http://www.w3.org/2001/XMLSchema';
    private static final String PREFIX = 'xs';
    public static final String PGE_SETTING_DATA_SET = 'PGEContractorRaterEmailSettings';
    global static final Set<String> ACCOUNT_RECORD_TYPE_NAMES = new Set<String> {'Contractor', 'Rater'};
    global PGE_Contractor_Rater_Email__c customSetting;
    global final String query = null;
    global String contractorsXml = null;
    global ErrorHandlingUtil errorLog = ErrorHandlingUtil.getInstance(); // Instantiate the class to log the errors.

    global ContractorToXMLBatch() {
        initCustomSetting();
        Set<Id> accountIdSet = new Set<Id>(); // set of relevant account ids

        try {
            for (Program_Enrollment__c programEnrollment : Database.query(''
                    + 'SELECT Account__c '
                    + 'FROM Program_Enrollment__c '
                    + 'WHERE RecordType.Name = \'' + ProgramEnrollmentUtility.AHU_RECORD_TYPE_NAME + '\' '
                        + 'AND Enrollment_Status__c = \'Full Participation\' '
                        + 'AND (Account__r.Include_in_Contractor_XML__c = true '
                            + 'OR (Account__r.Exclude_from_Contractor_XML__c = false '
                                + 'AND (Account__r.RecordType.Name = \'Rater\' '
                                    + 'OR (Account__r.RecordType.Name = \'Contractor\' '
                                        + 'AND (Enrollment_Date__c = '
                                        + 'LAST_N_DAYS:' + customSetting.Enrollment_Grace_Period__c.intValue() + ' '
                                            + 'OR Account__r.AHU_Last_App_Approval_Date__c = LAST_N_DAYS:365 '
                                        + ')'
                                    + ')'
                                + ')'
                            + ')'
                        + ')')) {
                accountIdSet.add(programEnrollment.Account__c); // add account ids to a set to assure uniqueness
            }
        } catch (QueryException e) {
            System.debug(
                'ContractorToXMLBatch.ContractorToXMLBatch() - A query exception has occurred: ' + e.getMessage());
            errorLog.logDebug('ContractorToXMLBatch', 'Constructor',
                    'A query exception has occurred: ' + e.getMessage(), '');
        } catch (Exception e) {
            System.debug(
                'ContractorToXMLBatch.ContractorToXMLBatch() - An exception has occurred: ' + e.getMessage());
            errorLog.logDebug('ContractorToXMLBatch', 'Constructor',
                    'A query exception has occurred: ' + e.getMessage(), '');
        }

        List<Id> accountIdList = new List<Id>(accountIdSet); // add to a list to join elements as a string

        // use the list of relevant account ids to construct the query string needed to get data for each batch
        query = ''
            + 'SELECT Id, RecordType.Name, Name, DBA__c, Phone, Email__c, Website, '
                + 'BillingStreet, BillingCity, BillingState, BillingPostalCode, '
                + 'HU_Last_App_Approval_Date__c, AHU_Last_App_Approval_Date__c, '
                + 'Include_in_Contractor_XML__c, Exclude_from_Contractor_XML__c, '
                + '(SELECT Id, Account__c, Enrollment_Date__c, Primary_Program_Contact__c, RecordType.Name '
                + 'FROM Program_Enrollments__r '
                + 'WHERE RecordType.Name = \'' + ProgramEnrollmentUtility.AHU_RECORD_TYPE_NAME + '\' '
                    + 'AND Enrollment_Status__c = \'Full Participation\'), '
                + '(SELECT Id FROM Contacts WHERE RecordType.Name IN (\'Rater\', \'Contractor\')), '
                + '(SELECT Credential_Type__c, Specialization__c, Provider_Issued_ID__c '
                + 'FROM Credentials__r '
                + 'WHERE Status__c = \'' + ApplicationUtils.CREDENTIAL_ACTIVE_VERIFIED_STATUS + '\' '
                    + 'AND Expiration_Date__c > ' + String.valueOf(Date.today()) + ' '
                    + 'AND (Credential_Type__c IN '
                        + '(\'State Contractor\\\'s License\', \'BPI Certification\', \'BPI Accreditation\', '
                        + '\'Home Energy Score Assessor\', \'High Performance HVAC Installer\'))) '
            + 'FROM Account '
            + 'WHERE RecordType.Name IN (\'Rater\', \'Contractor\') '
                + 'AND Id IN (\'' + String.join(accountIdList, '\', \'') + '\') '
            + 'Order By Name';

        this.buildXmlString(); // instantiate document
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        if (scope.isEmpty()) {
            return;
        }

        Set<Id> contactIds = new Set<Id>();
        Set<Id> contractorAccountIds = new Set<Id>();
        Map<String, Dom.Xmlnode> rtnameToNode = new Map<String, Dom.Xmlnode>();
        Dom.Document doc = new Dom.Document();
        doc.load(contractorsXml);
        Dom.Xmlnode root = doc.getRootElement();

        for (String rtname : ACCOUNT_RECORD_TYPE_NAMES) {
            rtnameToNode.put(rtname, root.getChildElement(rtname + 's', NAMESPACE));
        }

        Dom.XmlNode contractor = null;

        for (Account account : scope) {
            // Get contractor accounts.
            if (account.RecordType.Name == 'Contractor') {
                contractorAccountIds.add(account.Id);
            }
            // Get all relevant contact ids.
            for (Contact c : account.Contacts) {
                contactIds.add(c.Id);
            }
        }

        // Get all the partner rater accounts related to the contractor accounts.
        Map<Id, Account> partnerRaterAccountsById = new Map<Id, Account>([
            SELECT Id,
                (SELECT Credential_Type__c
                FROM Credentials__r
                WHERE Credential_Type__c = 'Home Energy Score Assessor'
                AND Status__c = :ApplicationUtils.CREDENTIAL_ACTIVE_VERIFIED_STATUS),
                (SELECT Id, Account.Id FROM Contacts)
            FROM Account
            WHERE RecordType.Name  = 'Rater'
                AND Id IN (SELECT AccountToId FROM Partner WHERE AccountFromId IN :contractorAccountIds)]);
        // Get partners, which will be used to relate the contractor and rater accounts.
        List<Partner> partners = [
            SELECT AccountToId, AccountFromId FROM Partner WHERE AccountFromId IN :contractorAccountIds
            ];
        // Get engagement contacts that fulfill the requirements:
        // 1 - Engagment Result has to be equal to Pass
        // 2 - Engagement Type has to be equal to either 2-4 Unit Test-In Observation or 2-4 Unit Test-Out Observation.
        List<Engagement_Contact__c> engagementContacts = [
            SELECT Engagement_Result__c, Engagement_Type__c, Contact__c, Contact__r.Account.Id
            FROM Engagement_Contact__c
            WHERE Contact__c IN :contactIds
                AND Engagement_Result__c = 'Pass'
                AND Engagement_Type__c IN ('2-4 Unit Test-In Observation', '2-4 Unit Test-Out Observation')
            ];

        for (Account account : scope) {
            contractor = rtnameToNode.get(account.RecordType.Name)
                    .addChildElement(account.RecordType.Name, NAMESPACE, PREFIX);

            if (ACCOUNT_RECORD_TYPE_NAMES.contains(account.RecordType.Name)) {
                contractor.addChildElement('CompanyName', NAMESPACE, null)
                        .addTextNode(account.DBA__c != null ? account.DBA__c : account.Name);

                contractor.setAttribute('CompanyId', (String) account.Id);

                contractor.addChildElement('DBA', NAMESPACE, null)
                        .addTextNode(account.DBA__c != null ? account.DBA__c : '');

                contractor.addChildElement('Email', NAMESPACE, null)
                        .addTextNode(account.Email__c != null ? account.Email__c : '');

                contractor.addChildElement('Phone', NAMESPACE, null)
                        .addTextNode(account.Phone != null ? account.Phone : '');

                contractor.addChildElement('Website', NAMESPACE, null)
                        .addTextNode(account.Website != null ? account.Website : '');

                contractor.addChildElement('BusinessAddress', NAMESPACE, null)
                        .addTextNode(account.BillingStreet != null ? account.BillingStreet : '');

                contractor.addChildElement('Zip', NAMESPACE, null)
                        .addTextNode(account.BillingPostalCode != null ? account.BillingPostalCode : '');

                contractor.addChildElement('City', NAMESPACE, null)
                        .addTextNode(account.BillingCity != null ? account.BillingCity : '');

                contractor.addChildElement('State', NAMESPACE, null)
                        .addTextNode(account.BillingState != null ? account.BillingState : '');

                contractor.addChildElement('PrimaryContact', NAMESPACE, null).addTextNode('');
            }

            // Add more data to Contractor nodes.
            if (account.RecordType.Name == 'Contractor') {
                // State Contractor's License
                String providerIssuedId = '';

                for (Credential__c credential : CredentialUtility.getCredentialsByCredentialType(
                        account.Credentials__r, 'State Contractor\'s License')) {
                    if (String.isNotBlank(credential.Provider_Issued_ID__c)) {
                        providerIssuedId = credential.Provider_Issued_ID__c;
                        break;
                    }
                }

                contractor.addChildElement('StateContractorsNo', NAMESPACE, null).addTextNode(providerIssuedId);

                contractor.addChildElement('PGE', NAMESPACE, null).addTextNode('Yes');

                // BPI Accreditation
                contractor.addChildElement('BPIAccredited', NAMESPACE, null)
                        .addTextNode(
                            CredentialUtility.hasCredential(account.credentials__r, 'BPI Accreditation')
                            ? 'Yes'
                            : 'No');

                // BPI Certification
                contractor.addChildElement('BPICertifiedAnalyst', NAMESPACE, null)
                        .addTextNode(
                            CredentialUtility.hasCredential(
                                account.credentials__r, 'BPI Certification', 'Building Analyst')
                            ? 'Yes'
                            : 'No');

                contractor.addChildElement('BPICertifiedHeated', NAMESPACE, null)
                        .addTextNode(
                            CredentialUtility.hasCredential(account.credentials__r, 'BPI Certification', 'Heating')
                            ? 'Yes'
                            : 'No');

                contractor.addChildElement('BPICertifiedEnvelope', NAMESPACE, null)
                        .addTextNode(
                            CredentialUtility.hasCredential(
                                account.credentials__r, 'BPI Certification', 'Envelope Professional')
                            ? 'Yes'
                            : 'No');

                contractor.addChildElement('BPICertifiedAC', NAMESPACE, null)
                        .addTextNode(
                            CredentialUtility.hasCredential(
                                account.credentials__r, 'BPI Certification', 'Air Conditioning & Heat Pump')
                            ? 'Yes'
                            : 'No');

                contractor.addChildElement('BPICertifiedMTF', NAMESPACE, null)
                        .addTextNode(
                            CredentialUtility.hasCredential(account.credentials__r, 'BPI Certification', 'Multifamily')
                            ? 'Yes'
                            : 'No');

                // Program Enrollments
                contractor.addChildElement('Advanced', NAMESPACE, null)
                        .addTextNode(
                            ProgramEnrollmentUtility.hasProgramEnrollment(
                                account.Program_Enrollments__r, ProgramEnrollmentUtility.AHU_RECORD_TYPE_NAME)
                            ? 'Yes'
                            : 'No');

                // <xs:Assessor>Yes/No</xs:Assessor>
                List<Credential__c> hesCredentials = CredentialUtility.getCredentialsByCredentialType(
                        account.Credentials__r, 'Home Energy Score Assessor');

                contractor.addChildElement('Assessor', NAMESPACE, null)
                        .addTextNode(
                            !hesCredentials.isEmpty() || hasPartnerWithCredentialType(
                                account.Id, partners, partnerRaterAccountsById.values(), 'Home Energy Score Assessor')
                            ? 'Yes'
                            : 'No');

                // <xs:Installer>Yes/No</xs:Installer>
                List<Credential__c> hvacCredentials = CredentialUtility.getCredentialsByCredentialType(
                        account.Credentials__r, 'High Performance HVAC Installer');

                contractor.addChildElement('Installer', NAMESPACE, null)
                        .addTextNode(!hvacCredentials.isEmpty() ? 'Yes' : 'No');

                // <xs:Qualified>Yes/No</xs:Qualified>
                contractor.addChildElement('Qualified', NAMESPACE, null)
                        .addTextNode(
                            isQualifiyingAccount(account.Id, partners, partnerRaterAccountsById, engagementContacts)
                            ? 'Yes'
                            : 'No');
            }
        }

        contractorsXml = doc.toXmlString();
    }

    global void finish(Database.BatchableContext BC) {
        // Check if there's no errors.
        if (errorLog.getErrorLogsToInsert().size() == 0) {
            // Seek and remove empty nodes.
            this.removeEmptyNodes();

            // Create email attachemnt
            Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
            emailAttachment.setContentType('text/xml');
            emailAttachment.setFileName(customSetting.Email_Attachment_Name__c);
            emailAttachment.setInline(false);
            emailAttachment.setBody(Blob.valueOf(contractorsXml));
            // Send email on finish
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setToAddresses(customSetting.Email_To__c.split(';'));
            mail.setOrgWideEmailAddressId(customSetting.OrgWideEmailAddressId__c);
            mail.setSubject(customSetting.Email_Subject__c);
            mail.setPlainTextBody(customSetting.Email_Content__c != null ? customSetting.Email_Content__c : '');

            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { emailAttachment });

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } else {
            // Insert log records.
            errorLog.logMessage();
        }
    }

    private void removeEmptyNodes() {
        Dom.Document doc = new Dom.Document();
        doc.load(contractorsXml);
        Dom.Xmlnode root = doc.getRootElement();

        for (String rtname : ACCOUNT_RECORD_TYPE_NAMES) {
            Dom.Xmlnode node = root.getChildElement(rtname + 's', NAMESPACE);
            // If there's no data, remove the node.
            if (node.getChildElements().size() == 0) {
                root.removeChild(node);
            }
        }

        contractorsXml = doc.toXmlString();
    }

    private void buildXmlString() {
        contractorsXml = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<CONTRACT xmlns:xs="http://www.w3.org/2001/XMLSchema"></CONTRACT>';
        Dom.Document doc = new Dom.Document();
        doc.load(contractorsXml);
        Dom.Xmlnode root = doc.getRootElement();

        // Add dynamically nodes to xml depending on accounts record types.
        for (String accountRecordTypeName : ACCOUNT_RECORD_TYPE_NAMES) {
            root.addChildElement(accountRecordTypeName + 's', NAMESPACE, PREFIX);
        }
        contractorsXml = doc.toXmlString();
    }

    private void initCustomSetting() {
        customSetting = PGE_Contractor_Rater_Email__c.getInstance(PGE_SETTING_DATA_SET);
        if (customSetting == null || customSetting.Email_Attachment_Name__c == null
               || customSetting.Email_Subject__c == null || customSetting.Email_To__c == null
               || customSetting.OrgWideEmailAddressId__c == null || customSetting.Enrollment_Grace_Period__c == null) {
            errorLog.logDebug('ContractorToXMLBatch', 'validateCustomSetting',
                    'Please define all the fields for the Custom Setting PGEContractorRaterEmail.', '');
        }
    }

    /**
     * Determines if the given account has at least one partner account with at least one credential of the given
     * credential type.
     *
     * @param accountId The account Id.
     * @param partners The list of partners.
     * @param partnerAccounts The list of relevant partner accounts.
     * @param credentialType The credential type, which we will search for in the partner accounts.
     * @return Return true if at least one partner account has at least one credential of the given credential type.
     *         Otherwise, return false.
     */
    private Boolean hasPartnerWithCredentialType(Id accountId, List<Partner> partners, List<Account> partnerAccounts,
            String credentialType) {
        for (Partner partner : partners) {
            if (partner.AccountFromId == accountId) {
                for (Account partnerAccount : partnerAccounts) {
                    if (partnerAccount.Id == partner.AccountToId
                                && !CredentialUtility.getCredentialsByCredentialType(
                                    partnerAccount.Credentials__r, credentialType).isEmpty()) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    /**
     * Determines if the given account is a qualifying account. This means that either the given account or one of its
     * partner accounts has to have at least one engagement contact that fulfills the requirements. These are:
     * 1 - Engagment Result has to be equal to Pass
     * 2 - Engagement Type has to be equal to either 2-4 Unit Test-In Observation or 2-4 Unit Test-Out Observation.
     *
     * @param accountId The account Id.
     * @param partners The list of partners.
     * @param partnerAccountsById A map of partner accounts with its Id as key.
     * @param engagementContacts The list of engagement contacts that fullfill the requirements.
     * @return Return true if at least there is one engagement contact that fulfills the requirements within the
     *         account's or the partner account's engagement contact records. Otherwise, return false.
     */
    private Boolean isQualifiyingAccount(Id accountId, List<Partner> partners, Map<Id, Account> partnerAccountsById,
            List<Engagement_Contact__c> engagementContacts) {
        Boolean isQualifiyingAccount = false;
        // First, search within the account's engagement contacts.
        for (Engagement_Contact__c engagementContact : engagementContacts) {
            if (accountId == engagementContact.Contact__r.Account.Id) {
                isQualifiyingAccount = true;
                break;
            }
        }
        // If the account's engagement contacts don't fulfill the requirements, then search within the related
        // partner accounts' engagement contacts.
        if (!isQualifiyingAccount) {
            isQualifiyingAccount = hasQualifyingPartner(accountId, partners, partnerAccountsById, engagementContacts);
        }

        return isQualifiyingAccount;
    }

    /**
     * Determines if the given account has a partner account with at least one engagement contact that fullfill the
     * requirements.
     *
     * @param accountId The account Id.
     * @param partners The list of partners.
     * @param partnerAccountsById A map of partner accounts with its Id as key.
     * @param engagementContacts The list of engagement contacts that fullfill the requirements.
     * @return Return true if at least one partner account has at least one engagement contact that fulfills the
     *         requirements. Otherwise, return false.
     */
    private Boolean hasQualifyingPartner(Id accountId, List<Partner> partners, Map<Id, Account> partnerAccountsById,
            List<Engagement_Contact__c> engagementContacts) {
        for (Partner partner : partners) {
            if (partner.AccountFromId == accountId && partnerAccountsById.containsKey(partner.AccountToId)) {
                List<Contact> contacts = partnerAccountsById.get(partner.AccountToId).Contacts;

                for (Contact c : contacts) {
                    for (Engagement_Contact__c engagementContact : engagementContacts) {
                        if (c.Id == engagementContact.Contact__c) {
                            return true;
                        }
                    }
                }
            }
        }

        return false;
    }
}