/**
*  Class name  :   UnitTestData.cls
*  Created by  :   Taras Spilchuk
*  Created on  :   November 27, 2018
*  Description :   Class for create unit test data.
*  Test class  :   UnitTestDataTest.cls.
*/
public without sharing class UnitTestData {
	public String queryString {get; set;}
	public String readyTestData;
	public String readyListTestData;
	public List<String> generatedObjectsName {get; set;}
	public String testDataFactoryName {get; set;}
	private Map<String, String> objectDataByName {get; set;}

	@AuraEnabled
	public static String getAllObjects() {
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
		List<ObjectWrapper> objectWrapperList = new List<ObjectWrapper>();

		for(Schema.SObjectType objectType : globalDescribe.values()){
			String objectName = objectType.getDescribe().getName();
			ObjectWrapper objectWrapper = new ObjectWrapper(objectName);

			objectWrapperList.add(objectWrapper);
		}

		return JSON.serialize(objectWrapperList);
	}

	@AuraEnabled
	public static String getAllObjectsFields(String objectName) {
		UnitTestData unitTestData = new UnitTestData();
		List<FiedlWrapper> fiedlWrapperList = unitTestData.prepareFiedlWrapper(objectName);

		return JSON.serialize(fiedlWrapperList);
	}

	@AuraEnabled
	public static String getTestData(String dataFactoryName, String soqlQuery, String objectName, String objectFields) {
		UnitTestData unitTestData = new UnitTestData();
		unitTestData.queryString = soqlQuery;
		unitTestData.testDataFactoryName = dataFactoryName;
		unitTestData.generateTestText(objectName, objectFields);

		String testData = unitTestData.readyTestData;
		String testListData = unitTestData.readyListTestData;
		Boolean isBlankTestData = String.isBlank(testData) || String.isBlank(testListData) ? true : false;

		if ( !isBlankTestData ) {
			testData = testData.substring(2);
			testListData = testListData.substring(2);
		}

		DataWrapper dataWrapper = new DataWrapper(
			objectName,
			unitTestData.generatedObjectsName,
			testData,
			testListData
		);

		return JSON.serialize(dataWrapper);
	}

	/**
	 * Generate unit test text.
	 *
	 * @param objectName  the object name.
	 * @param fields      the object feields.
	 */
	public void generateTestText(String objectName, String fields) {
		readyTestData = '';
		readyListTestData = '';
		generatedObjectsName = new List<String>();
		objectDataByName = new Map<String, String>();

		List<String> fieldsFromQuery = fields.split('\\,');

		checkData(objectName);

		Map<String, String> objectData = prepapeSoqlFieldsByObject(objectName, fieldsFromQuery);
		objectDataByName = objectData;

		for (String keyItem : objectData.keySet()) {
			List<String> referenceObjectDataFields = objectData.get(keyItem).split('\\,');

			generateTextForQuery(keyItem, referenceObjectDataFields);
		}
	}

	/**
	 * Prepare fields by object name.
	 *
	 * @param objectName       the object name.
	 * @param fieldsFromQuery  the splited  object feields.
	 * @return                 prepared fields by object name.
	 */
	private Map<String, String> prepapeSoqlFieldsByObject(String objectName, List<String> fieldsFromQuery) {
		Map<String, String> objectData = new Map<String, String>();
		Boolean isIdFieldInQuery = !fieldsFromQuery.contains('Id') ? fieldsFromQuery.contains('id') : false;

		if ( !isIdFieldInQuery ) {
			checkIsContainsKey(objectData, objectName, 'Id');
		}

		for (String fieldItem : fieldsFromQuery) {
			if ( fieldItem.contains('.') ) {
				prepareReferenceSoqlFields(objectName, objectData, fieldItem);
			} else {
				checkIsContainsKey(objectData, objectName, fieldItem);
			}
		}

		return objectData;
	}

	/**
	 * Prepare the name of the reference fields.
	 *
	 * @param objectName  the object name.
	 * @param objectData  prepared object data.
	 * @param fieldItem   the reference field.
	 */
	private void prepareReferenceSoqlFields(String objectName, Map<String, String> objectData, String fieldItem) {
		List<String> splitedFieldItem = fieldItem.split('\\.');
		String splitedObjectName = splitedFieldItem[0];
		String splitedObjectField = splitedFieldItem[1];

		if ( fieldItem.contains('__r') ) {
			splitedObjectName = splitedObjectName.replace('__r', '__c');
		} else {
			splitedObjectName = splitedFieldItem[0] + 'Id';
		}

		String referenceObjectName = getReferenceObjectName(objectName, splitedObjectName);

		checkIsContainsKey(objectData, referenceObjectName, splitedObjectField);
		checkIsContainsKey(objectData, objectName, splitedObjectName);
	}

	/**
	 * Get object name from reference field.
	 *
	 * @param objectName  the object name.
	 * @param fieldItem   the reference field.
	 * @return            return object name.
	 */
	private String getReferenceObjectName(String objectName, String fieldItem) {
		Schema.DescribeFieldResult describeFieldResult = getDescribeFieldResult(objectName, fieldItem);
		String referenceObjectName = String.valueOf(describeFieldResult.getReferenceTo()[0]);

		return referenceObjectName;
	}

	/**
	 * Check duplicated fields.
	 *
	 * @param objectData    prepared object data.
	 * @param objectNameKey the reference field.
	 * @param objectField   the object field.
	 */
	private void checkIsContainsKey(Map<String, String> objectData, String objectNameKey, String objectField) {
		Boolean isContainsKey = objectData.containsKey(objectNameKey);

		if ( !isContainsKey ) {
			objectData.put(objectNameKey, objectField);

			return;
		}

		String field = objectData.get(objectNameKey);

		if ( field.contains(objectField) ) {
			return;
		}

		field += ',' + objectField;

		objectData.put(objectNameKey, field);
	}

	// OBJECT DATA MANIPULATIONS.

	/**
	 * Get object data.
	 *
	 * @param objectName   object name.
	 * @return             return object data information.
	 */
	private DescribeSObjectResult getObjectData(String objectName) {
		DescribeSObjectResult objectData = Schema.getGlobalDescribe().get(objectName).getDescribe();

		return objectData;
	}

	/**
	 * Get all object fields.
	 *
	 * @param objectName   object name.
	 * @return             return object fields.
	 */
	private Map<String, Schema.SObjectField> getObjectFields(String objectName) {
		Map<String, Schema.SObjectField> objectFields = getObjectData(objectName).fields.getMap();

		return objectFields;
	}


	/**
	 * Prepare FiedlWrapper.
	 *
	 * @param objectName   object name.
	 * @return             return object fields.
	 */
	private List<FiedlWrapper> prepareFiedlWrapper(String objectName) {
		Map<String, Schema.SObjectField> objectFieldsMap = getObjectFields(objectName);
		List<FiedlWrapper> fiedlWrapperList = new List<FiedlWrapper>();

		for (String fieldItem : objectFieldsMap.keySet()) {
			Schema.DescribeFieldResult describeFieldResult = getDescribeFieldResult(objectName, fieldItem);

			//if ( !describeFieldResult.isUpdateable() ) {
			//	continue;
			//}

			String fieldName = String.valueOf(describeFieldResult.getName());
			String fieldType = String.valueOf(describeFieldResult.getType());
			String fieldLabel = String.valueOf(describeFieldResult.getLabel());
			FiedlWrapper fiedlWrapperItem = new FiedlWrapper(fieldName, fieldType, fieldLabel);

			fiedlWrapperList.add(fiedlWrapperItem);
		}

		return fiedlWrapperList;
	}

	/**
	 * Get mandatory fields.
	 *
	 * @param objectFields object fields.
	 * @return             return object mandatory fields.
	 */
	private List<String> getMandatoryFields(Map<String, Schema.SObjectField> objectFields) {
		List<String> mandatoryFields = new List<String>();

		for (String fieldItem : objectFields.keySet()) {
			Schema.SObjectField fieldData = objectFields.get(fieldItem);
			Schema.DescribeFieldResult fieldDescribe = fieldData.getDescribe();
			String field = String.valueOf(objectFields.get(fieldItem));

			if (!fieldDescribe.isNillable() &&
				fieldDescribe.type != Schema.DisplayType.BOOLEAN &&
				!fieldDescribe.isDefaultedOnCreate() &&
				fieldDescribe.isCreateable()
			) {
				mandatoryFields.add(field);
			}
		}

		return mandatoryFields;
	}

	/**
	 * Prepare object name. Remove '__c' and etc.
	 *
	 * @param objectName  object name.
	 * @return             return preapred object.
	 */
	private String prepareObjectName(String objectName) {
		String cleanObjectName = 'test' + objectName.replaceAll('__(c|C)$|__|_', '');

		return cleanObjectName;
	}

	/**
	 * Prepare object name. Remove '__c' and etc.
	 *
	 * @param objectName  object name.
	 * @return             return preapred object.
	 */
	private String prepareObjectNameWithoutTest(String objectName) {
		String cleanObjectName = objectName.replaceAll('__(c|C)$|__|_', '');

		return cleanObjectName;
	}

	// PREPARE OBJECT FIELDS.

	/**
	 * Get field information.
	 *
	 * @param objectName  object name.
	 * @param fieldItem   object field.
	 * @return            return information about field.
	 */
	public Schema.DescribeFieldResult getDescribeFieldResult(String objectName, String fieldItem) {
		Map<String, Schema.SObjectField> fieldsMap = getObjectFields(objectName);
		Schema.SObjectField fieldData = fieldsMap.get(fieldItem);
		Schema.DescribeFieldResult field = fieldData.getDescribe();

		return field;
	}

	/**
	 * Prepare feild value.
	 *
	 * @param objectName  object name.
	 * @param fieldItem   object field.
	 * @return            return prepared field by type.
	 */
	private String prepareFieldValue(String objectName, String fieldItem) {
		Schema.DescribeFieldResult describeFieldResult = getDescribeFieldResult(objectName, fieldItem);

		return setFieldValueByType(objectName, describeFieldResult);
	}

	/**
	 * Set field value by type.
	 *
	 * @param objectName  object name.
	 * @param field       object field.
	 * @return            return prepared field value by type.
	 */
	private String setFieldValueByType(String objectName, Schema.DescribeFieldResult field) {
		String fieldType = String.valueof(field.getType());
		String fieldName = String.valueof(field.getName());
		String fieldDefaultValue = String.valueof(field.getDefaultValue());
		Boolean isfieldDefaultValue = field.isDefaultedOnCreate();

		if ( String.isBlank(fieldDefaultValue) ) {
			isfieldDefaultValue = false;
		}

		switch on fieldType {
			when 'STRING', 'TEXTAREA', 'ADDRESS' {
				return fieldName + ' = ' + '\''
					+ (isfieldDefaultValue ? fieldDefaultValue : 'Test ' + fieldName) + '\'';
			}
			when 'INTEGER', 'FAX', 'PHONE', 'PERCENT' {
				return fieldName + ' = ' + (isfieldDefaultValue ? fieldDefaultValue : '123');
			}
			when 'DOUBLE', 'CURRENCY' {
				return fieldName + ' = ' + (isfieldDefaultValue ? fieldDefaultValue : '1.0');
			}
			when 'BOOLEAN', 'CHECKBOX' {
				return fieldName + ' = ' + '\''
					+ (isfieldDefaultValue ? fieldDefaultValue : 'false') + '\'';
			}
			when 'DATE' {
				return fieldName + ' = ' + 'Date.today().format()';
			}
			when 'DATETIME', 'TIME' {
				return fieldName + ' = ' + 'DateTime.now()';
			}
			when 'PICKLIST' {
				return fieldName + ' = ' + '\''
					+ (isfieldDefaultValue ? fieldDefaultValue : field.getPicklistValues()[0].getValue()) + '\'';
			}
			when 'EMAIL' {
				return fieldName + ' = ' + '\'' + 'test@email.com' + '\'';
			}
			when 'REFERENCE' {
				String referenceObjectName = String.valueOf(field.getReferenceTo()[0]);
				Boolean isObjectCreatable = checkIsObjectCreatable(referenceObjectName);
				String preparedReferenceObjectName = prepareObjectName(referenceObjectName);

				if (objectName == referenceObjectName) {
					preparedReferenceObjectName = preparedReferenceObjectName + 'Parent';
				}

				if ( !isObjectCreatable ) {
					prepareSOQLForNonCreateableField(referenceObjectName);
				} else {
					generateReferenceObjectText(objectName, referenceObjectName);
				}

				return fieldName + ' = ' + preparedReferenceObjectName + '.Id';
			}
			when 'URL' {
				return fieldName + ' = ' + '\'' + 'www.testURL.com' + '\'';
			}
			when else {
				return fieldName + ' = ' + '\' \'';
			}
		}
	}

	/**
	 * Check if is object name in test data text.
	 *
	 * @param referenceObjectName  reference object name.
	 * @return                     return true if test text contain object name.
	 */
	private Boolean isObjectNameInText(String referenceObjectName) {
		String text = readyTestData.replaceAll('\n+', '');

		if ( text.contains(referenceObjectName) ) {
			return true;
		}

		return false;
	}

	/**
	 * Check if is blank object name or TestDataFactory class name.
	 *
	 * @param objectName   object name.
	 */
	private void checkData(String objectName) {
		String errorMessage;

		if ( String.isBlank(objectName) ) {
			errorMessage = 'Please, enter the object name.';

			generateException(errorMessage);
		}

		if ( String.isBlank(testDataFactoryName) ) {
			errorMessage = 'Please, enter the data factory class name.';

			generateException(errorMessage);
		}
	}

	/**
	 * Check if is the object creatable.
	 *
	 * @param objectName   object name.
	 */
	private Boolean checkIsObjectCreatable(String objectName) {
		Schema.DescribeSObjectResult describeSObjectResult = getObjectData(objectName);
		Boolean isObjectCreatable = describeSObjectResult.isCreateable();

		if ( isObjectCreatable ) {
			return true;
		}

		return false;
	}

	/**
	 * Generate exception.
	 *
	 * @param errorMessage   the error message.
	 */
	private void generateException(String errorMessage) {
		AuraHandledException auraHandledException = new AuraHandledException(errorMessage);
		auraHandledException.setMessage(errorMessage);

		throw auraHandledException;
	}

	/**
	 * Generate test for SOQL query.
	 *
	 * @param objectName   object name.
	 * @param fields       object fields.
	 */
	private void generateTextForQuery(String objectName, List<String> fields) {
		Boolean isObjectCreatable = checkIsObjectCreatable(objectName);

		if ( !isObjectCreatable ) {
			prepareSOQLForNonCreateableField(objectName, fields);

			return;
		}

		Map<String, Schema.SObjectField> objectFields = getObjectFields(objectName);
		List<String> mandatoryFields = getMandatoryFields(objectFields);

		checkDuplicateInMadatoryField(fields, mandatoryFields);

		String preparedObjectName = prepareObjectName(objectName);
		Boolean isObjectName = isObjectNameInText(preparedObjectName);

		if ( isObjectName ) {
			return;
		}

		createTextAndListText(objectName, preparedObjectName, mandatoryFields);
	}

	/**
	 * Generate test for SOQL query.
	 *
	 * @param objectName   object name.
	 * @param referenceObjectName   object name.
	 */
	private void generateReferenceObjectText(String objectName, String referenceObjectName) {
		String preparedObjectName = prepareObjectName(referenceObjectName);
		Boolean isObjectName = isObjectNameInText(preparedObjectName);

		if ( isObjectName ) {
			return;
		}

		Map<String, Schema.SObjectField> fieldsMap = getObjectFields(referenceObjectName);
		List<String> mandatoryFields = getMandatoryFields(fieldsMap);
		List<String> objectFields = new List<String>();
		String mapFields = objectDataByName.get(referenceObjectName);
		Boolean isBlankField = String.isBlank(mapFields);

		if ( !isBlankField ) {
			objectFields = mapFields.split('\\,');

			if (objectName == referenceObjectName) {
				objectFields.clear();
				preparedObjectName = preparedObjectName + 'Parent';
			}

			checkDuplicateInMadatoryField(objectFields, mandatoryFields);
		}

		createTextAndListText(referenceObjectName, preparedObjectName, mandatoryFields);
	}

	/**
	 * Cgeck duplicates in mandatory fields.
	 *
	 * @param fields            all object fields.
	 * @param mandatoryFields   mandatory object fields.
	 */
	private void checkDuplicateInMadatoryField(List<String> fields, List<String> mandatoryFields){
		for (String fieldsItem : fields) {
			Boolean isContain = mandatoryFields.contains(fieldsItem);

			if ( isContain ) {
				continue;
			}

			mandatoryFields.add(fieldsItem);
		}
	}

	/**
	 * Generate test text.
	 *
	 * @param objectName           object name.
	 * @param preparedObjectName   prepared object name.
	 * @param mandatoryFields      mandatory object fields.
	 */
	private void createTextAndListText(String objectName, String preparedObjectName, List<String> mandatoryFields) {
		String text = createText(objectName, preparedObjectName, mandatoryFields);
		String listText = createListText(objectName, preparedObjectName, mandatoryFields);

		addText(text, listText);
	}

	/**
	 * Add text to readyTestData and readyListTestData.
	 *
	 * @param text        the test text.
	 * @param listText    the test list text.
	 */
	private void addText(String text, String listText) {
		readyTestData += text;
		readyListTestData += listText;
	}

	// GENERATE UNIT TEST TEXT.
	/**
	 * Prepare test text for non creatable object.
	 *
	 * @param objectName   object name.
	 */
	private void prepareSOQLForNonCreateableField(String objectName) {
		String readyObjectName = prepareObjectName(objectName);
		Boolean isObjectInText = isObjectNameInText(readyObjectName);

		if ( isObjectInText ) {
			return;
		}

		String text = '\n\n' + objectName + ' ' + readyObjectName + ' = [\n' +
		'\tSELECT Id\n' +
		'\tFROM ' + objectName + '\n' +
		'\tLIMIT 1\n' +
		'];';

		addText(text, text);
	}

	/**
	 * Prepare test text for non creatable object.
	 *
	 * @param objectName   object name.
	 * @param fields       object fields.
	 */
	private void prepareSOQLForNonCreateableField(String objectName, List<String> fields) {
		String readyObjectName = prepareObjectName(objectName);
		Boolean isObjectInText = isObjectNameInText(readyObjectName);
		Integer i = 0;

		if ( isObjectInText ) {
			return;
		}

		String text = '\n\n' + objectName + ' ' + readyObjectName + ' = [\n' + '\tSELECT ';

		for (String fieldItem : fields) {
			i++;
			text += i== 1 ? fieldItem : ', ' + fieldItem;
		}

		text += '\n\tFROM ' + objectName + '\n' +
		'\tLIMIT 1\n' +
		'];';

		addText(text, text);
	}

	/**
	 * Generate test text (not list text).
	 *
	 * @param objectName           object name.
	 * @param preparedObjectName   prepared object name.
	 * @param objectFields         object fields.
	 * @return                     return test text.
	 */
	public String createText(String objectName, String preparedObjectName, List<String> objectFields) {
		String objectNameWithoutTest =  prepareObjectNameWithoutTest(objectName);
		String text = '\n\n' + objectName + ' ' + preparedObjectName + ' = (' + objectName + ') ' +
			 + testDataFactoryName + '.createSObject(\n\tnew ' + objectName + '(';
		text += prepareFieldText(objectName, objectFields);
		text += '\n\t';
		text += '), ' + '\'' + testDataFactoryName + '.' + objectNameWithoutTest + 'Defaults\', true\n);';

		addObjectNameToList(preparedObjectName);

		return text;
	}

	/**
	 * Generate test list text.
	 *
	 * @param objectName           object name.
	 * @param preparedObjectName   prepared object name.
	 * @param objectFields         object fields.
	 * @return                     return test list text.
	 */
	public String createListText(String objectName, String preparedObjectName, List<String> objectFields) {
		String objectNameWithoutTest =  prepareObjectNameWithoutTest(objectName);
		preparedObjectName += 'List';

		String text = '\n\n' + 'List<' + objectName + '> ' + preparedObjectName + ' = ' +
			 + testDataFactoryName + '.createSObjectList(\n\tnew ' + objectName + '(';

		text += prepareFieldText(objectName, objectFields);
		text += '\n\t';
		text += '), 5, ' + '\'' + testDataFactoryName + '.' + objectNameWithoutTest + 'Defaults\', true\n);';

		return text;
	}

	/**
	 * Prepare field test text..
	 *
	 * @param objectName           object name.
	 * @param objectFields         object fields.
	 * @return                     return field test text.
	 */
	private String prepareFieldText(String objectName, List<String> objectFields) {
		Integer i = 0;
		String fieldText = '';

		for (String fieldsItem : objectFields) {
			if (fieldsItem.toLowerCase() == 'id') {
				continue;
			}

			i++;
			fieldText += '\n\t\t' + prepareFieldValue(objectName, fieldsItem);

			if ( i == objectFields.size() ) {
				break;
			}

			fieldText += ',';
		}

		return fieldText;
	}

	/**
	 * Add object name to list.
	 *
	 * @param objectName           object name.
	 */
	private void addObjectNameToList(String objectName) {
		Boolean isObjectNameInList = generatedObjectsName.contains(objectName);

		if ( !isObjectNameInList ) {
			generatedObjectsName.add(objectName);
		}
	}

	// WRAPPERS
	public class DataWrapper {
		public String sObjectName;
		public List<String> generatedObjectsName;
		public String testData;
		public String testListData;

		public DataWrapper(String sObjectName, List<String> generatedObjectsName, String testData, String testListData) {
			this.sObjectName = sObjectName;
			this.generatedObjectsName = generatedObjectsName;
			this.testData = testData;
			this.testListData = testListData;
		}
	}

	public class FiedlWrapper {
		public String name;
		public String type;
		public String label;

		public FiedlWrapper(String name, String type, String label) {
			this.name = name;
			this.type = type;
			this.label = label;
		}
	}

	public class ObjectWrapper {
		public String name;

		public ObjectWrapper(String name) {
			this.name = name;
		}
	}
}