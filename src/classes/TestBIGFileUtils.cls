/**
 * This class contains unit tests for validating the behavior of BIGFileUtils class.
 *
 * @author Pablo Vigil  pvigil@builditgreen.org
 * @since 2014-11
 */
@isTest
private class TestBIGFileUtils {
    // Constants.
    private static final Integer MAX_FILE_SIZE = 5242880;

    static testMethod void testFileExtensions() {
        String fileName = 'TestFile.png';
        String badFileName = 'BadFile';

        System.Assert('png' == BIGFileUtils.getFileExtension(fileName));
        System.Assert(BIGFileUtils.isFileExtensionIncluded(fileName, new List<String> {'png', 'xml'}));
        System.Assert(BIGFileUtils.isFileExtensionIncluded(fileName, new Set<String> {'png'}));

        System.Assert(null == BIGFileUtils.getFileExtension(badFileName));
        System.AssertEquals(false, BIGFileUtils.isFileExtensionIncluded(badFileName, new List<String> {'png', 'xml'}));
        System.AssertEquals(false, BIGFileUtils.isFileExtensionIncluded(badFileName, new Set<String> {'png'}));
    }

    static testMethod void testFileSize() {
        // We need insert a record to use as a parent for the attachment.
        Account acc = BIGPortalTestUtils.createAccount('Test Account');
        insert acc;
        System.AssertNotEquals(null, acc.Id);

        Attachment file = BIGPortalTestUtils.createAttachment('TestFile.png');
        file.ParentId = acc.Id;
        insert file;

        System.AssertNotEquals(null, file.Id);

        // Retrieve the inserted attachment.
        file = [SELECT Id, Body, BodyLength FROM Attachment WHERE Id =: file.Id];

        System.AssertEquals(false, BIGFileUtils.isFileSizeLarger(file.BodyLength, MAX_FILE_SIZE));
        System.Assert(true == BIGFileUtils.isFileSizeLarger(file.BodyLength, 0));
    }
}