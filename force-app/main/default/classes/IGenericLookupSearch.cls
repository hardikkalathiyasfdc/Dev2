/**
 * @description       : Interface for Generic Lookup custom search logic
 * @author            : Ravi Bheemreddy
 * @jira			  : BRME-6660
 **/
public interface IGenericLookupSearch {
    List<GenericLookupController.LookupRecord> search(GenericLookupController.SearchRequest req);
}