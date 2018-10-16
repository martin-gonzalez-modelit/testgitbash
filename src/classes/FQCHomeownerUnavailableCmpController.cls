/**
 * This controller handles the functionality of the FQCHomeownerUnavailableCmp lightning component.
 * @author Gabriela Rojas <gabriela.rojas@modelit.xyz>
 * @author Mauricio Medina <mauricio.medina@modelit.xyz>
 * @since 2018-6
 */

public with sharing class FQCHomeownerUnavailableCmpController {
    private ApplicationFileService applicationFileService;

    public FQCHomeownerUnavailableCmpController() {
        // Instantiate application file service.
        applicationFileService = new ApplicationFileService();
    }

    /**
     * Returns the url of the attachments for the running org as a string.
     *
     * @return Url of the attachments as a string.
     */
    public static String getAttachmentURL() {
        return applicationFileService.getAttachmentURL();
    }

    /**
     * Creates a new application file and it's corresponding attachment if it hasn't been done before.
     * If the method is called with an existing application file id but no attachment id (empty value), it deletes the
     * existing application and creates a new application file and attachment.
     * On the other hand, if there is an existing attachment, it appends the missing chunks to it.
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
        return applicationFileService.saveChunk(parentId, fileName, base64Data, contentType, fileAppId, attachmentId);
    }

    /**
     * Deletes an application file.
     *
     * @param applicationFileId A string. It would either be user input, or an address selected by the user.
     */
    public static String deleteApplicationFile(String applicationFileId) {
        return applicationFileService.deleteApplicationFile(applicationFileId);
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
    private static Map<Id,Id> saveFile(Id parentId, String fileName, String base64Data, String contentType) {
        return applicationFileService.saveFile(parentId, fileName, base64Data, contentType);
    }

    /**
     * Appends chunks to the existing attachment.
     *
     * @param attachmentId The attachment id.
     * @param base64Data The contents of the file encoded in base64.
     */
    private static void appendToAttachment(Id attachmentId, String base64Data) {
        applicationFileService.appendToAttachment(attachmentId, base64Data);
    }
}