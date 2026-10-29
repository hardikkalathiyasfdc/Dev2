public with sharing class ListTagsHelper {
    
    public static String getAlphabeticalListSource(String sourceNames) {
        System.debug('#######ListTagsHelper-getAlphabeticalListSource-sourceNames: ' + sourceNames);
        String alphabeticalSource = '';
        if(String.isNotEmpty(sourceNames)) {
            sourceNames = sourceNames.remove('List(s): ');
            List<String> otherSourceNames = sourceNames.split('\n');
            otherSourceNames.sort();
            alphabeticalSource = 'List(s): ' + String.join(otherSourceNames,'; ');
        }
        System.debug('#######ListTagsHelper-getAlphabeticalListSource-alphabeticalSource: ' + alphabeticalSource);
        return alphabeticalSource;
    }

    public static String getAlphabeticalTagSource(String sourceNames) {
        System.debug('#######ListTagsHelper-getAlphabeticalTagSource-sourceNames: ' + sourceNames);
        String alphabeticalSource = '';
        if(String.isNotEmpty(sourceNames)) {
            sourceNames = sourceNames.remove('Tag(s): ');
            List<String> otherSourceNames = sourceNames.split('\n');
            otherSourceNames.sort();
            alphabeticalSource = 'Tag(s): ' + String.join(otherSourceNames,'; ');
        }
        System.debug('#######ListTagsHelper-getAlphabeticalTagSource-alphabeticalSource: ' + alphabeticalSource);
        return alphabeticalSource;
    }
}