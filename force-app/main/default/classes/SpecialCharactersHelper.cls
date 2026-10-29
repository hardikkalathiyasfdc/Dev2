/*
*  test class: SpecialCharactersHelperTest
*/
public with sharing class SpecialCharactersHelper {

    private static final String ERR_UPDATE_SPECIAL_CHAR_CHECKBOX_FAILED = 'SpecialCharactersHelper_updateSpecialCharCheckbox_FAILED';
    private static final String ERR_HAS_SPECIAL_CHARS_FAILED = 'SpecialCharactersHelper_hasSpecialChars_FAILED';
    private static final String ERR_CONVERT_SPECIAL_CHAR_FAILED = 'SpecialCharactersHelper_convertSpecialCharToEnglish_FAILED';

    public static void updateSpecialCharCheckbox(String val, SObject myObj, String field) {
        try {
            myObj.put(field, hasSpecialChars(val));
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_UPDATE_SPECIAL_CHAR_CHECKBOX_FAILED));
        }
    }

    public static boolean hasSpecialChars(String val) {
        try {
            if(String.isBlank(val)) return false;
            String exp = Label.Special_Characters_Regex;
            Pattern nonAlphanumeric = Pattern.compile(exp);
            Matcher matcher = nonAlphanumeric.matcher(val);
            return !matcher.matches();
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_HAS_SPECIAL_CHARS_FAILED));
            return false;
        }
    }
    
    public static String convertSpecialCharToEnglish(String input) {
        try {
            return convertSpecialCharToEnglish(input, false);
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CONVERT_SPECIAL_CHAR_FAILED));
            return input;
        }
    }

    public static String convertSpecialCharToEnglish(String input, Boolean skipWhiteSpace) {
        try {
            if(String.isBlank(input)) return input;
            Map<String, String> mapSpecialCharacter = Assets.mapSpecialCharacter;
            // Convert to a list of characters
            List<String> chars = input.split('');
            //chars.remove(0);
            // Replace characters
            for(Integer i = 0; i < chars.size(); i++) {
                if(skipWhiteSpace && chars[i] == ' ') continue;
                if(mapSpecialCharacter.containsKey(chars[i])) {
                    chars[i] = mapSpecialCharacter.get(chars[i]);
                }
            }
            // Convert back to a string
            return String.join(chars, '');
        } catch(Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, new BBApps_ErrorCustomFields(ERR_CONVERT_SPECIAL_CHAR_FAILED));
            return input;
        }
    }
}