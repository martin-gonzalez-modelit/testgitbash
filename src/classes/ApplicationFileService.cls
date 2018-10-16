/**
 * Service that contains methods to work with the Application File object.
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @author Mauricio Medina <mauricio.medina@modelit.xyz>
 * @since 2018-6
 */

public with sharing class ApplicationFileService {
    /**
     * Returns the url of the attachments for the running org as a string.
     *
     * @return Url of the attachments as a string.
     */
    public static String getAttachmentURL() {
        return URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=';
    }

    /**
     * Creates a new application file and it's corresponding attachment if it hasn't been done before.
     * If the method is called with an existing application file id, it appends the missing chunks to its attachment.
     *
     * @param parentId The id of the application.
     * @param fileName The name of the file to upload.
     * @param base64Data The contents of the file encoded in base64.
     * @param contentType The file type or file extension.
     * @param fileAppId The application file id.
     * @param attachmentId The attachment id.
     * @return Map of the application file id as key and the attachment id as value.
     */
    public static Map<Id,Id> saveChunk(Id parentId, String fileName, String base64Data, String contentType,
            String fileAppId, String attachmentId) {
        Map<Id,Id> attachmentByApplicationFileId = new Map<Id,Id>();

        try {
            if (String.isBlank(attachmentId)) {
                attachmentByApplicationFileId = saveFile(parentId, fileName, base64Data, contentType);
                fileAppId = new List<Id>(attachmentByApplicationFileId.keySet()).get(0);
                attachmentId = attachmentByApplicationFileId.get(fileAppId);
            } else {
                appendToAttachment(attachmentId, base64Data);
                attachmentByApplicationFileId = new Map<Id,Id>{fileAppId => attachmentId};
            }
        } catch (Exception e) {
            System.debug('###Error Couldn\'t save chunk. Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return attachmentByApplicationFileId;
    }

    /**
     * Deletes an application file.
     *
     * @param applicationFileId A string. It would either be user input, or an address selected by the user.
     */
    public static String deleteApplicationFile(String applicationFileId) {
        try {
            Application_File__c applicationFile = [
                SELECT Id
                FROM Application_File__c
                WHERE Id = :applicationFileId
                ];

            delete applicationFile;
        } catch (Exception e) {
            System.debug('###Error Couldn\'t delete application file. Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return applicationFileId;
    }

    /**
     * Creates an application file of type "Field QC Photos" and it's corresponding attachment.
     * It returns a map, which contains the application file as key and the attachment id as value.
     *
     * @param parentId The id of the application.
     * @param fileName The name of the file to upload.
     * @param base64Data The contents of the file encoded in base64.
     * @param contentType The file type or file extension.
     * @return Map of the application file id as key and the attachment id as value.
     */
    public static Map<Id,Id> saveFile(Id parentId, String fileName, String base64Data, String contentType) {
        Application_File__c applicationFile = new Application_File__c();
        Attachment attachment = new Attachment();

        try {
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

            applicationFile.Application_File_Type__c = 'Field QC Photos';
            applicationFile.Application__c = parentId;
            applicationFile.File_Name__c = fileName;
            applicationFile.FQC_Billable__c = true;
            insert applicationFile;

            attachment.ParentId = applicationFile.Id;
            attachment.Name = fileName;
            attachment.ContentType = contentType;
            attachment.Body = EncodingUtil.base64Decode(base64Data);
            insert attachment;
        } catch (Exception e) {
            System.debug('###Error Couldn\'t save file. Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }

        return new Map<Id,Id>{applicationFile.Id => attachment.Id};
    }

    /**
     * Appends chunks to the existing attachment.
     *
     * @param attachmentId The attachment id.
     * @param base64Data The contents of the file encoded in base64.
     */
    public static void appendToAttachment(Id attachmentId, String base64Data) {
        try {
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
            Attachment a = [
                SELECT Id, Body
                FROM Attachment
                WHERE Id = :attachmentId
                ];
            String existingBody = EncodingUtil.base64Encode(a.Body);
            a.Body = EncodingUtil.base64Decode(existingBody + base64Data);
            update a;
        } catch (Exception e) {
            System.debug('###Error Couldn\'t append to attachment. Message: ' + e.getMessage());
            System.debug('###StackTrace: ' + e.getStackTraceString());
        }
    }
}