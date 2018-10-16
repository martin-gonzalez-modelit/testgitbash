/**
 * Helper class for handling lists of SObjects, separating them into pages.
 * This is mainly targetted at usage in web UIs.
 *
 * @author Pablo Vigil <pablo.vigil@modelit.xyz>
 * @since 2013-6
 */
public virtual with sharing class BIGPortalPaginationUtils {

    // Constants
    private static final String GPR_SETTINGS_DATASET_NAME = 'PGEPortalSettings';
    private static final Integer NUMBER_OF_RECORDS_PER_PAGE = null;
    protected final Integer NUMBER_OF_RECORDS_JSON = 15000;
    // Private Properties
    protected ApexPages.StandardSetController stdController = null;
    protected String query { get; set; }
    // Public properties
    public String direction { get; set; }
    public Integer pageNumber { get; set; }
    public String orderBy { get; set; }
    public Integer limitQuery { get; set; }

    static {
        // Initialize custom setting
        // This custom setting has the value of the number of records displayed on each page of the pagination
        PGE_Portal_Settings__c settings = PGE_Portal_Settings__c.getInstance(GPR_SETTINGS_DATASET_NAME);
        if (settings != null && settings.Number_Of_Records_Per_Page__c != null
                && settings.Number_Of_Records_Per_Page__c != 0) {
            NUMBER_OF_RECORDS_PER_PAGE = Integer.valueOf(settings.Number_Of_Records_Per_Page__c);
        } else {
            // Set five records by default
            NUMBER_OF_RECORDS_PER_PAGE = 5;
        }
    }

    public BIGPortalPaginationUtils() {
        direction = 'ASC';
    }

    /**
     * Sets a list of records to Standar set controller
     */
    protected virtual void setRecords(List<sObject> records) {
        stdController = new ApexPages.StandardSetController(records);
        stdController.setPageSize(NUMBER_OF_RECORDS_PER_PAGE);
   }

    /**
     * Set query to get records from the standardSetController
     */
    protected virtual void setQueryToController() {
        if (query != null && query != '') {
            String queryWithFilter = query;
            if (orderBy != null && orderBy != '') {
                String[] columns = orderBy.split(',');
                if (columns.size() > 1) { // if order by has multiple columns
                    orderBy = '';
                    for (Integer i = 0; i < columns.size() - 1; i++) {
                        orderBy += columns[i] + ' ' + direction + ', ';
                    }
                    orderBy += columns[columns.size() - 1];
                }
                queryWithFilter += ' ORDER BY ' + String.escapeSingleQuotes(orderBy) + ' ' + direction;
            }
            if (limitQuery != null) {
                queryWithFilter += ' LIMIT ' + limitQuery;
            }
            stdController = new ApexPages.StandardSetController(Database.query(queryWithFilter));
            stdController.setPageSize(NUMBER_OF_RECORDS_PER_PAGE);
        }
    }

    /**
     * Toggle Direction of Ordering
     */
    public virtual void toggleDirection() {
        if (direction == 'ASC') {
            direction = 'DESC';
        } else {
            direction = 'ASC';
        }
        setQueryToController();
        setCurrentPageNumber();
    }

    /**
     * Indicates the total number of pages.
     */
    public virtual Integer getNumberOfPages() {
        if (stdController != null) {
            if (math.mod(stdController.getResultSize(), stdController.getPageSize()) > 0) {
                return stdController.getResultSize()/stdController.getPageSize() + 1;
            } else {
                return (stdController.getResultSize()/stdController.getPageSize());
            }
        }
        return 0;
    }

    /**
     * Indicates current page number
     */
    public virtual Integer getCurrentPageNumber() {
        if (stdController != null) {
            return stdController.getPageNumber();
        } else {
            return 0;
        }
    }

    /**
     * Return a list of PageItems
     * PageItem is used by the paginator controls on VF Page to indicate
     * each page number and if the page displayed is the current page
     */
    public virtual List<PageItem> getPageItems() {
        List<PageItem> l = new List<PageItem>();
        PageItem pItem = null;
        for (Integer i = 1; i <= getNumberOfPages(); i++) {
            pItem = new PageItem();
            pItem.pageNumber = i;
            pItem.isCurrentPage = pItem.pageNumber == getCurrentPageNumber() ? true : false;
            l.add(pItem);
        }
        return l;
    }

    /**
     * Indicates whether there are more records after the current page set.
     */
    public virtual Boolean getHasNext() {
        if (stdController != null) {
            return stdController.getHasNext();
        } else {
            return false;
        }
    }

    /**
     * Indicates whether there are more records before the current page set.
     */
    public virtual Boolean getHasPrevious() {
        if (stdController != null) {
            return stdController.getHasPrevious();
        } else {
            return false;
        }
    }

    /**
     * Returns the page number of the current page set
     */
    public virtual Integer getPageNumber() {
        if (stdController != null) {
            return stdController.getPageNumber();
        } else {
            return 0;
        }
    }

    /**
     * Set Page Number
     */
    public virtual void setCurrentPageNumber() {
        if (stdController != null) {
            stdController.setPageNumber(pageNumber);
        }
    }

    /**
     * Returns the first page of records
     */
    public virtual void first() {
        if (stdController != null) {
            stdController.first();
        }
    }

    /**
     * Returns the last page of records
     */
    public virtual void last() {
        if (stdController != null) {
            stdController.last();
        }
    }

    /**
     * Returns the previous page of records
     */
    public virtual void previous() {
        if (stdController != null) {
            stdController.previous();
        }
    }

    /**
     * Returns the next page of records
     */
    public virtual void next() {
        if (stdController != null) {
            stdController.next();
        }
    }

    /**
     * Class to handle the pages generated by the StandardSetController
     * Each PageItem will contain the page number and a boolean value indicating if it's the current page displayed
     */
    public virtual class PageItem {
        public Integer pageNumber { get; set; }
        public Boolean isCurrentPage { get; set; }

        public PageItem() {}

    }
}