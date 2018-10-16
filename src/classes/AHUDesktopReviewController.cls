/**
 * This class manages desktop review operations for AHU.
 * @author Jordan Dunn <jdunn@builditgreen.org>
 * @since 2015-10
 */
public with sharing class AHUDesktopReviewController {
    private static final String CORRECTION_REQUIRED_STATUS = 'Correction Required';
    private static final String REJECTED_STATUS = 'Rejected';
    public Application__c app {get; set;}
    public Id appId {get; set;}
    public Sub_Application__c subApp {get; set;}
    public Id subAppId {get; set;}
    public Review__c review {get; set;}
    public List<RecordType> subAppRTs {get; set;}
    public Boolean isPreInstall {get; set;}
    public String stageHint {get; set;}
    public Map<String, List<FieldSet>> fieldSets {get; set;}

    public AHUDesktopReviewController(ApexPages.StandardController con) {

        fieldSets = new Map<String, List<FieldSet>>();
        fieldSets.put('Review__c', wrapFieldSets(Review__c.sObjectType, 'AHUDesktopReview'));
        fieldSets.put('Application__c', wrapFieldSets(Application__c.sObjectType, 'AHUDesktopReview'));
        fieldSets.put('Sub_Application__c', wrapFieldSets(Sub_Application__c.sObjectType, 'AHUDesktopReview'));

        Map<String, String> params = ApexPages.currentPage().getParameters();
        String appId = params.get('appId');
        if (String.isBlank(appId)) {
            pageError('\'appId\' URL parameter must be provided.');
            return;
        }

        // Locate application with the passed in appId.
        List<Application__c> app_l = Database.query(new QueryBuilder(Application__c.sObjectType).allFields()
                .whereClause('id = :appId').build());
        if (!app_l.isEmpty()) {
            app = app_l.get(0);
        } else {
            pageError('Application could not be found with the given Id: ' + appId);
            return;
        }

        // Find a sub-app of the app with a record type based on the app's status.
        if (app.status__c == ApplicationUtils.PRE_INSTALL_SUBMITTED_STATUS
                || app.status__c == ApplicationUtils.PRE_INSTALL_RESUBMITTED_STATUS) {
            isPreInstall = true;
            subAppRTs = [
                SELECT id
                FROM RecordType
                WHERE
                    (Name = 'EnergyPro Pre-Installation' OR Name = 'PRE-APP') AND SObjectType = 'Sub_Application__c'
                ];
        } else if (app.status__c == ApplicationUtils.POST_INSTALL_SUBMITTED_STATUS
                || app.status__c == ApplicationUtils.POST_INSTALL_RESUBMITTED_STATUS) {
            isPreInstall = false;
            subAppRTs = [
                SELECT id
                FROM RecordType
                WHERE
                    (Name = 'EnergyPro Post-Installation' OR Name = 'POST-APP') AND SObjectType = 'Sub_Application__c'
                ];
        } else {
            pageError('Invalid application status: ' + app.status__c);
            return;
        }

        List<Sub_Application__c> subApp_l = Database.query(new QueryBuilder(Sub_Application__c.SObjectType)
                .allFields().whereClause('Application__c = :appId AND RecordTypeId IN :subAppRTs').build());
        if (!subApp_l.isEmpty()) {
            subApp = subApp_l.get(0);
            subAppId = subApp.id;
        } else {
            pageError('Could not find a sub-application belonging to application (' + appId + ') with status: '
                     + app.status__c);
            return;
        }

        // Finally, locate a review object belonging to the subApp, if it exists.
        List<Review__c> review_l = Database.query(new QueryBuilder(Review__c.sObjectType).allFields()
                .whereClause('Sub_Application__c = :subAppId order by CreatedDate desc').build());
        if (review_l.isEmpty()) {
            review = (Review__c) con.getRecord();
            review.Application__c = app.id;
            review.Sub_Application__c = subApp.id;
            review.Status__c = 'Under Review';
        } else {
            Review__c oldReview = review_l.get(0);
            if (review_l.get(0).Status__c == 'Under Review') {
                review = oldReview;
            } else {
                review = oldReview.clone(false, true);
                review.Application__c = app.id;
                review.Sub_Application__c = subApp.id;
                review.Status__c = 'Under Review';
                review.Review_Date__c = null;
                review.Approval_Date__c = null;
                review.Reject_Date__c = null;
                review.Request_More_Info_Date__c = null;
                review.Resubmitted_Date__c = null;
                review.Submission_Date__c = null;
            }
        }
        review.RecordTypeId = [SELECT id FROM RecordType WHERE name = 'AHU' AND SObjectType = 'Review__c' ].Id;

        stageHint = isPreInstall ? '(Pre-Install)' : '(Post-Install)';
    }

    public Boolean getDoDisplayForm() {
        return app != null && subAppRTs != null && subApp != null;
    }

    private List<FieldSet> wrapFieldSets(Schema.SObjectType sObjectType, String filter) {
        Schema.DescribeSObjectResult res = sObjectType.getDescribe();
        Map<String, Schema.FieldSet> fieldSetMap = res.fieldSets.getMap();

        List<FieldSet> fieldSets = new List<FieldSet>();
        for (Schema.FieldSet fs : fieldSetMap.values()) {
            if (String.isBlank(filter) || fs.getDescription().contains(filter))
                fieldSets.add(new FieldSet(fs));
        }
        fieldSets.sort();
        return fieldSets;
    }

    public Map<String, AHU_Desktop_Review_Settings__c> getSettings() {
        Map<String, AHU_Desktop_Review_Settings__c> settings = new Map<String, AHU_Desktop_Review_Settings__c>();
        Set<String> fieldNames = new Set<String>();
        for (String fieldName : Review__c.sObjectType.getDescribe().fields.getMap().keySet())
            fieldNames.add(fieldName.toLowerCase());
        for (AHU_Desktop_Review_Settings__c s : AHU_Desktop_Review_Settings__c.getAll().values()) {
            if (fieldNames.contains(s.api_binding_name__c.toLowerCase()))
                settings.put(s.api_binding_name__c, s);
        }
        return settings;
    }

    /* Consumed by Javascript on the VisualForce page.
     */
    public String getSettingsJson() {
        return JSON.serialize(getSettings());
    }

    /* Provide a dynamic component that generates PageBlockSections using filtered FieldSets on Review__c
     * and mapping their fields to 'AHU_Desktop_Review_Settings__c' custom setting entries. The 'text__c'
     * value on those settings are parsed into valid merge syntax and evaluated.
     *
     * Pure VisualForce does not have the ability to assign dynamic (merge) property values; eg. assigning
     * a merge-syntax string to the 'value' property on <apex:outputText/> within a repeat. This can easily
     * be achieved using the 'expressions.value' property in Apex.
     */
    public Component.Apex.OutputPanel getReviewSections() {
        Component.Apex.OutputPanel out = new Component.Apex.OutputPanel();
        Map<String, AHU_Desktop_Review_Settings__c> settings = getSettings();
        for (FieldSet fs : fieldSets.get('Review__c')) {
            Component.Apex.PageBlockSection section = new Component.Apex.PageBlockSection(columns = 1, 
                    title = fs.label);
            for (FieldSetMember f : fs.fields) {
                if (!settings.containsKey(f.fieldPath)) continue; // ignore if field's custom setting is not found
                AHU_Desktop_Review_Settings__c setting = settings.get(f.fieldPath);

                Component.Apex.PageBlockSectionItem item = new Component.Apex.PageBlockSectionItem();
                item.helpText = setting.help_text__c; // add help tooltip next to item text
                item.labelStyleClass = 'c-label';
                item.dataStyleClass = 'c-data';

                Component.Apex.OutputText itemText = new Component.Apex.OutputText();
                itemText.expressions.value = parseMergeText(setting.text__c);
                itemText.escape = false; // do not escape HTML

                Component.Apex.InputField itemInput = new Component.Apex.InputField();
                itemInput.required = f.required || f.dbRequired;
                itemInput.expressions.value = '{!review[\'' + f.fieldPath + '\']}';
                itemInput.styleClass = 'c-field c-field-' + f.fieldPath;

                item.childComponents.add(itemText);
                item.childComponents.add(itemInput);
                section.childComponents.add(item);
            }
            out.childComponents.add(section);
        }
        return out;
    }

    /* Parse a string into valid merge-style syntax that can be parsed in VisualForce.
     * Ex: 'The app id is {!Application__c.Id}' -> '{!"The app id is " & app.Id & ""}''
     */
    private String parseMergeText(String text) {
        if (text == null) text = '';
        text = text.replace('\r\n', '').replace('\n', '').replace('\r', '').replace('"', '\\"');
        Matcher m = Pattern.compile('\\{![^}]*\\}').matcher(text);
        while (m.find()) {
            String unwrapped = m.group().replaceAll('^\\{!', '').replaceAll('\\}$', '');
            text = m.replaceFirst('" & ' + unwrapped + ' & "');
            m.reset(text);
        }
        text = text.replace(' Sub_Application__c', ' subApp').replace(' Application__c', ' app')
                .replace(' Review__c', ' review');
        return '{!"' + text + '"}';
    }

    /* Provide a sorted list of related list settings for Review__c.
     */
    private List<AHU_Desktop_Review_Related_Lists__c> getRelatedLists() {
        Map<String, AHU_Desktop_Review_Related_Lists__c> rlists_m = AHU_Desktop_Review_Related_Lists__c.getAll();
        List<String> keys = new List<String>(rlists_m.keySet());
        keys.sort();
        List<AHU_Desktop_Review_Related_Lists__c> rlists = new List<AHU_Desktop_Review_Related_Lists__c>();
        for (String key : keys) {
            rlists.add(rlists_m.get(key));
        }
        return rlists;
    }

    /* Provide a dynamic component that generates RelatedList elements. The subject property
     * on this element cannot be dynamically assigned in VisualForce, requiring the use of Apex.
     */
    public Component.Apex.OutputPanel getDynamicLists() {
        if(subApp == null) return null;
        Component.Apex.OutputPanel out = new Component.Apex.OutputPanel();
        List<AHU_Desktop_Review_Related_Lists__c> rlists = getRelatedLists();

        for (AHU_Desktop_Review_Related_Lists__c rlist : rlists) {
            if (!rlist.enabled__c) continue;
            Component.Apex.RelatedList rlistc = new Component.Apex.RelatedList();

            if (rlist.object_name__c == 'Application__c') {
                rlistc.subject = app.id;
            } else if (rlist.object_name__c == 'Sub_Application__c') {
                rlistc.subject = subApp.id;
            } else if (rlist.object_name__c == 'Review__c') {
                rlistc.subject = review.id;
            } else {
                continue;
            }

            rlistc.list = rlist.related_list_name__c;
            out.childComponents.add(rlistc);
        }
        return out;
    }

    public PageReference save() {
        try {
            List<Review__c> reviews = [
                SELECT Id, Status__c
                FROM Review__c
                WHERE Application__c = :app.Id ORDER BY CreatedDate DESC LIMIT 1
                ];

            if (reviews.isEmpty() || (!reviews.isEmpty() && reviews.get(0).Status__c == CORRECTION_REQUIRED_STATUS)) {
                insert review;
            } else {
                upsert review;
            }
            app.Desktop_Reviewer__c = UserInfo.getUserId();
            update app;
        } catch (Exception e) {
            pageError(e.getMessage());
            return null;
        }
        PageReference confirm = Page.AHUDesktopReviewConfirmation;
        confirm.getParameters().put('appId', app.id);
        confirm.getParameters().put('reviewId', review.id);
        return confirm;
    }

    private Application_Note__c makeNote(String type) {
        String notes = '';
        if (review.Comments__c != null)
            notes += 'Issues:\n' + review.Comments__c + '\n\n';

        if (review.Additional_Comments__c != null)
            notes += 'Comments:\n' + review.Additional_Comments__c + '\n\n';

        if (notes != null && notes != '') {
            Application_Note__c appNote = new Application_Note__c(
                Action_Type__c = type,
                Application__c = app.Id,
                Note__c = notes,
                Public__c = true,
                Sub_Application__c = subApp.Id
            );
            insert appNote;
            return appNote;
        }
        return null;
    }

    public PageReference approve() {
        Map<String, AHU_Desktop_Review_Settings__c> settings = getSettings();
        for (AHU_Desktop_Review_Settings__c setting : settings.values()) {
            if (review.get(setting.api_binding_name__c) != setting.truthy_value__c) {
                pageError('Could not approve, all review fields must be true.');
                return null;
            }
        }
        if (!String.isBlank(review.Comments__c)) {
            pageError('Could not approve, the issues field must be blank.');
            return null;
        }

        Savepoint sp = Database.setSavepoint();
        // Keep original records without any modifications in case of errors.
        Review__c oldReview = review.clone(true, true);
        Application__c oldApp = app.clone(true, true);
        Sub_Application__c oldSubApp = subApp.clone(true, true);
        
        makeNote('Approved');
        DateTime now = DateTime.now();
        review.Approval_Date__c = now;
        review.Review_Date__c = now;
        review.Status__c = 'Approved';
        if (isPreInstall) {
            app.Status__c = ApplicationUtils.PRE_INSTALL_APPROVED_STATUS;
        } else {
            app.Field_QC_Status__c = 'Available for Selection';
            app.Desktop_Review_Status__c = 'Passed Post-Install Review';
            app.Desktop_Review_Completion_Date__c = now;
        }
        app.Last_Review_Date__c = now;
        app.Desktop_Review_Approval_Date__c = now;
        subApp.Last_Review_Date__c = now;
        subApp.Approval_Date__c = now;

        PageReference ref = save();
        // If ref is null it means there was an error trying to save the records.
        if (ref == null || !updateObject(subApp)) {
            Database.rollback(sp);
            // Set back original values for application, review and sub application.
            review = oldReview;
            app = oldApp;
            subApp = oldSubApp;
            ref = null;
        }

        return ref;
    }

    public PageReference returnForCorrection() {
        if (makeNote('Returned') == null) {
            pageError('Issues or Comments must be provided to mark as Contractor Action Required.');
            return null;
        }
        DateTime now = DateTime.now();
        review.Request_More_Info_Date__c = now;
        review.Review_Date__c = now;
        review.Status__c = CORRECTION_REQUIRED_STATUS;
        app.Status__c = isPreInstall
                ? ApplicationUtils.PRE_INSTALL_CORRECTION_REQUIRED_STATUS
                : ApplicationUtils.POST_INSTALL_CORRECTION_REQUIRED_STATUS;
        app.Last_Review_Date__c = now;
        subApp.Last_Review_Date__c = now;
        
        // we need to update first the Application__c otherwise the process builder on Sub_Application__c
        // is going to take the Submitted status and this makes a bug
        PageReference ref = save();
        
        if (!updateObject(subApp)) {
            ref = null;
        }

        return ref;
    }

    public PageReference reject() {
        if (makeNote(REJECTED_STATUS) == null) {
            pageError('Issues or Comments must be provided to reject.');
            return null;
        }
        DateTime now = DateTime.now();
        review.Reject_Date__c = now;
        review.Review_Date__c = now;
        review.Status__c = REJECTED_STATUS;
        app.Status__c = REJECTED_STATUS;
        app.Desktop_Review_Completion_Date__c = now;
        app.Last_Review_Date__c = now;
        app.Desktop_Review_Status__c = REJECTED_STATUS;
        subApp.Last_Review_Date__c = now;
        
        PageReference ref = save();
        
        if (!updateObject(subApp)) {
            ref = null;
        }

        return ref;
    }

    private Boolean updateObject(SObject sObj) {
        try {
            update sObj;
        } catch (Exception e) {
            pageError(e.getMessage());
            return false;
        }
        return true;
    }

    private void pageError(String message) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }

    public class FieldSet implements Comparable {
        public String label {get; set;}
        public List<FieldSetMember> fields {get; set;}
        public String description {get; set;}
        public String name {get; set;}
        public Schema.SObjectType sObjectType {get; set;}

        public FieldSet() {
            fields = new List<FieldSetMember>();
        }

        public FieldSet(Schema.FieldSet fs) {
            label = fs.getLabel();
            description = fs.getDescription();
            name = fs.getName();
            sObjectType = fs.getSObjectType();
            fields = new List<FieldSetMember>();
            for (Schema.FieldSetMember fsm : fs.getFields())
                fields.add(new FieldSetMember(fsm));
        }

        public Integer compareTo(Object obj) {
            FieldSet fs = (FieldSet) obj;
            return label.compareTo(fs.label);
        }
    }

    public class FieldSetMember {
        public String label {get; set;}
        public String fieldPath {get; set;}
        public Boolean dbRequired {get; set;}
        public Boolean required {get; set;}
        public Schema.DisplayType type {get; set;}

        public FieldSetMember() {}
        
        public FieldSetMember(Schema.FieldSetMember fsm) {
            dbRequired = fsm.getDbRequired();
            fieldPath = fsm.getFieldPath();
            label = fsm.getLabel();
            required = fsm.getRequired();
            type = fsm.getType();
        }
    }

    public class QueryBuilder {
        public Schema.SObjectType sObjectType {get; set;}
        public Schema.DescribeSObjectResult sObjectDsr {get; set;}
        public Set<String> fields {get; set;}
        public String whereClause {get; set;}
        public Integer limitBy {get; set;}

        public QueryBuilder(Schema.SObjectType sObjectType) {
            this.sObjectType = sObjectType;
            sObjectDsr = sObjectType.getDescribe();
            this.fields = new Set<String>();
            fields(new Set<String> {'Id'});
            limitBy(1);
        }
        public QueryBuilder allFields() {
            fields(sObjectDsr.fields.getMap().keySet());
            return this;
        }
        public QueryBuilder fields(Set<String> fields) {
            for (String field : fields)
                this.fields.add(field.toLowerCase());
            return this;
        }
        public QueryBuilder limitBy(Integer limitBy) {
            this.limitBy = limitBy;
            return this;
        }
        public QueryBuilder whereClause(String whereClause) {
            this.whereClause = whereClause;
            return this;
        }
        public String build() {
            String fieldStr = '';
            for (String name : fields) fieldStr += name + ', ';
            fieldStr = fieldStr.substringBeforeLast(',');
            whereClause = String.isNotBlank(whereClause) ? 'WHERE ' + whereClause : '';
            String limitStr = limitBy > 0 ? 'LIMIT ' + limitBy : '';
            return String.format('SELECT {0} FROM {1} {2} {3}', new List<String> {fieldStr, sObjectDsr.getName(), 
                    whereClause, limitStr});
        }
    }
}