public with sharing class BIGPortalToogleApplicationListController {
    // Properties.
    //public Boolean isACQC { get; set; }
    public String columnNames { get; set; }
    public String columnIndexes { get; set; }

    public List<List<String>> getToogleOptions() {
        List<String> colNames = columnNames.split(',');
        List<String> colIndexes = columnIndexes.split(',');

        List<List<String>> result = new List<List<String>>();
        For (Integer i = 0; i < colNames.size(); i++) {
            result.add(new List<String>{colNames[i], colIndexes[i]});
        }
        return result;
    }
}