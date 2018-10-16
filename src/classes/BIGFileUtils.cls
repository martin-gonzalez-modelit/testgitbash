/**
 * Provides general global file utility methods.
 *
 * @author Pablo Vigil  pvigil@builditgreen.org
 * @since 2014-11
 */
public with sharing class BIGFileUtils {

    /**
     * Checks if the file extension is included into the list of extensions.
     *
     * @param fileName The full name of the file to validate. It cannot be null/empty.
     * @param fileExtensions A set of extensions to validate against. It cannot be null/empty.
     * @return True if the extension file is included in the list, otherwise False.
     */
    public static Boolean isFileExtensionIncluded(String fileName, Set<String> fileExtensions) {
        return fileExtensions.contains(getFileExtension(fileName));
    }

    /**
     * Checks if the file extension is included into the list of extensions.
     *
     * @param fileName The full name of the file to validate. It cannot be null/empty.
     * @param fileExtensions The list of extensions to validate against. It cannot be null/empty.
     * @return True if the extension file is included in the list, otherwise False.
     */
    public static Boolean isFileExtensionIncluded(String fileName, List<String> fileExtensions) {
        return new Set<String>(fileExtensions).contains(getFileExtension(fileName));
    }

    /**
     * Checks if the size of the file is larger than the maximum size.
     *
     * @param fileSize The size of the file (in bytes). It cannot be null/empty.
     * @param maxFileSize The maximum size of the file allowed. It cannot be null/empty.
     * @return True if the file size is larger than the maximum size, otherwise False.
     */
    public static Boolean isFileSizeLarger(Integer fileSize, Integer maxFileSize) {
        return fileSize > maxFileSize;
    }

    /**
     * Extracts extension from the file name. Dot is not included in the returned string.
     *
     * @param fileName The full name of the file. It cannot be null/empty.
     * @return The extension of the file, otherwise null.
     */
    public static String getFileExtension(String fileName) {
        String fileExtension = fileName.substringAfterLast('.');
        return String.isNotBlank(fileExtension) ? fileExtension.deleteWhitespace().toLowerCase() : null;
    }

}