({
	getData : function(component, event, helper) {
		const constans = this.getConstantObject();
		let soqlSelect = document.querySelector(constans.SELECT_INPUT_ID);
		let objectFields = this.cleanSOQLfields(soqlSelect.value);
		let soqlFrom = document.querySelector(constans.FROM_INPUT_ID);
		let objectName = this.cleanSOQLfields(soqlFrom.value);
		let soqlQuery = 'SELECT ' + objectFields + ' FROM '+ objectName;
		let dataFactoryName = document.querySelector(constans.DATA_FACTORY_INPUT_ID).value;
		let	action = component.get('c.getTestData');

		soqlSelect.value = objectFields;
		soqlFrom.value = objectName;

		action.setParams({
			'dataFactoryName' : dataFactoryName,
			'soqlQuery' : soqlQuery,
			'objectName' : objectName,
			'objectFields' : objectFields
		});

		action.setCallback(this, function(response) {
			let state = response.getState();

			if (state === 'SUCCESS') {
				let result = JSON.parse(response.getReturnValue());

				this.setTextToTextarea(result.testData);
				this.setSOQL();
				this.enableReadonlyItems(constans.TEST_DATA_TEXTAREA_ID);

				component.set('v.objectData', result);
				component.set('v.isShowSettings', true);
				component.set('v.replacedObjectData', result.testData);

				this.setTimer(component, callback, 500);

				function callback() {
					helper.checkQueryFieldsCheckbox()
				}
			}

			if (state === 'ERROR') {
				let errors = action.getError();
				let message = Array.isArray(errors) ? errors[0].message : errors;
				let commonMessage = 'Oops, something went wrong. Please, check your SOQL query!';
				let errorMessage = message.includes('Error ID') ? commonMessage : message;

				alert(errorMessage);
			}
		});

		$A.enqueueAction(action);
	},

	getObjectNames : function(component, event, helper) {
		let	action = component.get('c.getAllObjects');

		action.setCallback(this, function(response) {
			let state = response.getState();

			if (state === 'SUCCESS') {
				let result = JSON.parse(response.getReturnValue());

				component.set('v.objectNames', result);
				component.set('v.objectNamesFounded', result);
			}

			if (state === 'ERROR') {
				let commonMessage = 'Oops, something went wrong. Please, reload page.';

				alert(errorMessage);
			}
		});

		$A.enqueueAction(action);
	},

	getObjectFields : function(component, event, helper) {
		const constans = this.getConstantObject();
		let	action = component.get('c.getAllObjectsFields');
		let objectName = document.querySelector(constans.FROM_INPUT_ID).value;

		action.setParams({
			'objectName' : objectName
		});

		action.setCallback(this, function(response) {
			let state = response.getState();

			if (state === 'SUCCESS') {
				let result = JSON.parse(response.getReturnValue());

				component.set('v.fieldData', result);
				component.set('v.fieldDataFounded', result);
			}

			if (state === 'ERROR') {
				let commonMessage = 'Oops, something went wrong. Please, reload page.';

				alert(commonMessage);
			}
		});

		$A.enqueueAction(action);
	},

	setSOQL : function() {
		const constans = this.getConstantObject();
		let query = document.querySelector(constans.QUERY_INPUT_ID);
		let soqlFields = document.querySelector(constans.SELECT_INPUT_ID).value;
		soqlFields = this.cleanSOQLfields(soqlFields);
		console.log('soqlFields', soqlFields);

		if ( !soqlFields ) {
			soqlFields = 'Id';
		}

		let soqlFrom = document.querySelector(constans.FROM_INPUT_ID).value;
		soqlFrom = this.cleanSOQLfields(soqlFrom);
		let soqlQuery = constans.SELECT_QUERY_WORD + ' ' + soqlFields + ' \n' + constans.FROM_QUERY_WORD + ' ' + soqlFrom;

		this.enableReadonlyItems(constans.QUERY_INPUT_ID);

		query.value = soqlQuery;
	},

	convertItemsToList : function(component, event, helper) {
		let eventTarget = event.target;
		let checkboxId = eventTarget.id;
		let isChecked = eventTarget.checked;
		let objectData = component.get('v.objectData');
		let checkboxesId = objectData.generatedObjectsName;
		let listText = objectData.testListData;
		let text = objectData.testData;

		// If checked ALL checkbox.
		if ( checkboxId === 'doAllList' ) {
			if ( isChecked ) {
				component.set('v.replacedObjectData', listText);

				this.setTextToTextarea(listText);
				this.setValueToAllCheckboxes(checkboxesId, true);

				return;
			}

			component.set('v.replacedObjectData', text);

			this.setValueToAllCheckboxes(checkboxesId, false);
			this.setTextToTextarea(text);

			return;
		}

		// If only one checkbox is checked.
		listText = listText.split('\n\n');
		text = text.split('\n\n');

		if ( isChecked ) {
			checkboxId += 'List';
			this.replaceTextByIndex(component, listText, checkboxId);
		} else {
			this.replaceTextByIndex(component, text, checkboxId);
		}
	},

	setValueToAllCheckboxes : function(checkboxesId, isChecked) {
		checkboxesId.forEach(function(item) {
			item = item.trim();

			let itemId = document.getElementById(item);

			if ( !itemId ) {
				return;
			}

			itemId.checked = isChecked;
		});
	},

	replaceTextByIndex : function(component, array, checkboxId) {
		checkboxId += ' = ';
		let wantedIndex;
		let regexp = new RegExp(checkboxId, 'ig');
		let replacedObjectDataText = component.get('v.replacedObjectData');
		replacedObjectDataText = replacedObjectDataText.split('\n\n');

		array.forEach(function(item, index) {
			if ( item.match(regexp) ) {
				wantedIndex = index;

				return;
			}
		});

		replacedObjectDataText[wantedIndex] = array[wantedIndex];
		replacedObjectDataText = replacedObjectDataText.join('\n\n');

		component.set('v.replacedObjectData', replacedObjectDataText);

		this.setTextToTextarea(replacedObjectDataText);
	},

	setTextToTextarea : function(data) {
		const constans = this.getConstantObject();
		let testDataTextarea = document.querySelector(constans.TEST_DATA_TEXTAREA_ID);
		testDataTextarea.value = data;
	},

	handleObjectFieldsCheckbox : function(component, event, helper) {
		const constans = this.getConstantObject();
		let eventTarget = event.target;
		let checkBoxId = (eventTarget.id).trim();
		let isChecked = eventTarget.checked;
		let soqlQuery = document.querySelector(constans.SELECT_INPUT_ID);
		let splitedSoqlQuery = soqlQuery.value;
		splitedSoqlQuery = splitedSoqlQuery.replace(/\s+/g, '');
		splitedSoqlQuery = splitedSoqlQuery.split(',');

		if ( isChecked ) {
			let array = splitedSoqlQuery.map(item => item.toLowerCase());

			splitedSoqlQuery.push(checkBoxId);
		} else {
			let index = splitedSoqlQuery.indexOf(checkBoxId);

			if (index == -1) {
				return;
			}

			splitedSoqlQuery.splice(index, 1);
		}

		// Remove empty array items.
		splitedSoqlQuery = splitedSoqlQuery.filter(Boolean);

		soqlQuery.value = splitedSoqlQuery.toString();

		this.setSOQL();
	},

	getIndexOf : function(word, array) {
		let index = array.map(item => item.toLowerCase());
		index = index.indexOf(word);

		return index;
	},

	checkQueryFieldsCheckbox : function() {
		const constans = this.getConstantObject();
		let soqlFields = document.querySelector(constans.SELECT_INPUT_ID);
		let splitedFields = soqlFields.value;
		splitedFields = splitedFields.split(',');

		this.setValueToAllCheckboxes(splitedFields, true);
	},

	cleanSOQLfields : function(fields) {
		let splitedSoqlQuery = fields.replace(/\s+/g, '');
		splitedSoqlQuery = splitedSoqlQuery.split(',');

		splitedSoqlQuery = splitedSoqlQuery.filter(Boolean);

		return splitedSoqlQuery.toString();
	},

	searchItems : function(subject, objects) {
		let matches = [];
		let regexp = new RegExp(subject, 'ig');
		let objectKeys = Object.keys(objects[0]);

		for (let i = 0; i < objects.length; i++) {
			let isMatched = false;

			for (let key in objects[i]) {
				let objectValue = String(objects[i][key]);

				objectValue.match(regexp) ? isMatched = true : false;
			}

			isMatched ? matches.push(objects[i]) : false;
		}

		return matches;
	},

	toggleDisplayBlock : function(id, isDisplay) {
		id = '#' + id;
		let toggleText = document.querySelector(id);
		let style = toggleText.style;

		if ( style.display === 'none' || style.display == '' || isDisplay) {
			style.display = 'inline-block';

			return;
		}

		style.display = 'none';
	},

	/** Toggle icon. */
	toggleIcon : function(component, id, iconBefore, iconAfter, permanentDisplay) {
		let item = component.find(id);
		let iconName = item.get('v.iconName');

		if ( iconName === iconBefore || permanentDisplay ) {
			item.set('v.iconName', iconAfter);

			return;
		}

		item.set('v.iconName', iconBefore);
	},

	/** Toggle the disable attribute and change icon. */
	changeDisplayAndIcon : function(component, iconId, iconBefore, iconAfter, isChanged) {
		this.toggleDisplayBlock(iconId, isChanged);
		this.toggleIcon(component, iconId, iconBefore, iconAfter, isChanged);
	},

	/** Toggle the disable attribute in the all inputs and icons. */
	toggleDisabled : function(component, isData, inputId, iconId) {
		let item = document.querySelector(inputId);
		let iconItem = component.find(iconId);

		if ( isData ) {
			item.removeAttribute('disabled');
			iconItem.set('v.disabled', 'false');
		} else {
			item.setAttribute('disabled', 'true');
			iconItem.set('v.disabled', 'true');
			item.value = '';
		}

	},

	/** Toggle the disable attribute in the generateTestDataButton button. */
	toggleDisableGenerateButton : function(component, value) {
		let generateButton = component.find('generateTestDataButton');

		if ( value ) {
			generateButton.set('v.disabled', false);
		} else {
			generateButton.set('v.disabled', true);
		}
	},

	/** Set disable to false, only for readonly elements. */
	enableReadonlyItems : function(itemId) {
		let item = document.querySelector(itemId);

		item.removeAttribute('disabled');
	},

	/** Get all constants. */
	getConstantObject : function() {
		const constantObject = {
			'DATA_FACTORY_INPUT_ID' : '#dataFactoryName',
			'SELECT_INPUT_ID' : '#select',
			'FROM_INPUT_ID' : '#from',
			'QUERY_INPUT_ID' : '#query',
			'TEST_DATA_TEXTAREA_ID' : '#testDataTextarea',
			'CONVERT_TO_LIST_BLOCK' : 'convertToList',
			'OBJECT_FIELDS_BLOCK' : 'objectFields',
			'OBJECT_NAMES_BLOCK' : 'objectNames',
			'LIST_ARROW_BUTTON_ID' :'listArrow',
			'FIELDS_ARROW_ID' : 'fieldsArrow',
			'THREE_DOTS_ICON' : 'utility:threedots',
			'COPY_TO_CLIPBOARD_ICON' : 'utility:copy_to_clipboard',
			'CLOSE_ICON' : 'utility:close',
			'CHECK_ICON' : 'utility:check',
			'ARROW_RIGHT_ICON' : 'utility:chevronright',
			'ARROW_DOWN_ICON' : 'utility:chevrondown',
			'SELECT_QUERY_WORD' : 'SELECT',
			'FROM_QUERY_WORD' : 'FROM'
		}

		return constantObject;
	},

	/** Set timeout. */
	setTimer : function(component, callback, time) {
		let	timer = component.get('v.timer');

		clearTimeout(timer);

		timer = setTimeout(
			$A.getCallback(callback), time
		);

		component.set('v.timer', timer);
	},

	onObjectNamesBlur : function(component, event, helper) {
		const constants = this.getConstantObject();
		let eventTarget = event.target;
		let objectName = eventTarget.id;
		let datasetValue = eventTarget.dataset.value;
		let threeDotsIcon = component.find(datasetValue);
		let fromInput = document.querySelector(constants.FROM_INPUT_ID);
		fromInput.value = objectName;

		threeDotsIcon.set('v.iconName', constants.THREE_DOTS_ICON);

		// Permanent display none.
		this.toggleDisplayBlock(datasetValue, false);
		// Change disable in SQOL input
		this.toggleDisabled(component, true, constants.SELECT_INPUT_ID, constants.OBJECT_FIELDS_BLOCK);
		this.toggleDisableGenerateButton(component, true);
		this.getObjectFields(component, event);
		this.setSOQL();
	}
})