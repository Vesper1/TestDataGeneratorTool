({
	/** Init. */
	init : function(component, event, helper) {
		helper.getObjectNames(component, event, helper);
	},

	/** Copy tp clipboard. */
	copyToClipboard : function(component, event, helper) {
		const constants = helper.getConstantObject();
		let eventSource = event.getSource();
		let elementId = eventSource.getLocalId();
		let testDataTextarea = document.querySelector('#' + elementId).select();

		document.execCommand('copy');
		window.getSelection().removeAllRanges();

		eventSource.set('v.iconName', constants.CHECK_ICON);

		setTimeout(function() {
			eventSource.set('v.iconName', constants.COPY_TO_CLIPBOARD_ICON);
		}, 2000);
	},

	/** Get data from apex. */
	getData : function(component, event, helper) {
		helper.getData(component, event, helper);
	},

	/** Toggle arrow box. Show and hidex object blocks.*/
	toggleArrowBox : function(component, event, helper) {
		const constants = helper.getConstantObject();
		let target = event.currentTarget;
		let targetId = target.dataset.value;

		switch(targetId) {
			case constants.CONVERT_TO_LIST_BLOCK:
				helper.toggleDisplayBlock(constants.CONVERT_TO_LIST_BLOCK);
				helper.toggleIcon(
					component,
					constants.LIST_ARROW_BUTTON_ID,
					constants.ARROW_RIGHT_ICON,
					constants.ARROW_DOWN_ICON
				);
				break;
		}
	},

	/** Replace test text to list text. */
	convertItemsToList : function(component, event, helper) {
		helper.convertItemsToList(component, event, helper);
	},

	/** Add or remove fields from SOQL query input. */
	handleObjectFieldsCheckbox : function(component, event, helper) {
		helper.handleObjectFieldsCheckbox(component, event, helper);
	},

	/** Hide spinner. */
	hideSpinner : function (component, event) {
		component.set('v.showSpinner', false);
	},

	/** Show spinner. */
	showSpinner : function (component, event) {
		component.set('v.showSpinner', true);
	},

	/** Search fields. */
	handleFieldsSearchKeyUp : function (component, event, helper) {
		let searchWord = component.find('enter-search').get('v.value');
		let fieldData = component.get('v.fieldData');
		let matchedData = helper.searchItems(searchWord, fieldData);

		component.set('v.fieldDataFounded', matchedData);

		helper.setTimer(component, callback, 500);

		function callback() {
			helper.checkQueryFieldsCheckbox();
		}
	},

	onKeyUpFromInput : function(component, event, helper) {
		const constants = helper.getConstantObject();
		let searchWord = document.querySelector(constants.FROM_INPUT_ID).value;
		let objectNames = component.get('v.objectNames');
		let matchedData = helper.searchItems(searchWord, objectNames);

		component.set('v.objectNamesFounded', matchedData);

		helper.toggleIcon(component, constants.OBJECT_NAMES_BLOCK, constants.THREE_DOTS_ICON, constants.CLOSE_ICON, true);
		// Permanent display block.
		helper.toggleDisplayBlock(constants.OBJECT_NAMES_BLOCK, true);
		checkObjectNameFromInput();

		function checkObjectNameFromInput() {
			for ( let i = 0; i < objectNames.length; i++ ) {
				if ( searchWord === objectNames[i].name ) {
					helper.toggleDisabled(component, true, constants.SELECT_INPUT_ID, constants.OBJECT_FIELDS_BLOCK);
					helper.toggleDisableGenerateButton(component, true);
					helper.getObjectFields(component, event, helper);
					helper.setSOQL();

					return;
				}

				helper.toggleDisabled(component, false, constants.SELECT_INPUT_ID, constants.OBJECT_FIELDS_BLOCK);
				helper.toggleDisableGenerateButton(component, false);
			}
		}
	},

	toggleThreeDotsWindow : function(component, event, helper) {
		const constants = helper.getConstantObject();
		let eventSource = event.getSource();
		let targetId = eventSource.getLocalId();

		helper.changeDisplayAndIcon(component, targetId, constants.THREE_DOTS_ICON, constants.CLOSE_ICON);
	},

	onObjectNamesBlur : function(component, event, helper) {
		const constants = helper.getConstantObject();
		let eventTarget = event.target;
		let objectName = eventTarget.id;
		let datasetValue = eventTarget.dataset.value;
		let threeDotsIcon = component.find(datasetValue);
		let fromInput = document.querySelector(constants.FROM_INPUT_ID);
		fromInput.value = objectName;

		threeDotsIcon.set('v.iconName', constants.THREE_DOTS_ICON);

		// Permanent display none.
		helper.toggleDisplayBlock(datasetValue, false);
		// Change disable in SQOL input
		helper.toggleDisabled(component, true, constants.SELECT_INPUT_ID, constants.OBJECT_FIELDS_BLOCK);
		helper.toggleDisableGenerateButton(component, true);
		helper.getObjectFields(component, event, helper);
		helper.setSOQL();
	},

	onInputDataFactoryBlur : function(component, event, helper) {
		const constants = helper.getConstantObject();
		let eventTarget = event.target;
		let id = eventTarget.id;
		let value = eventTarget.value;

		helper.toggleDisabled(component, value, constants.FROM_INPUT_ID, constants.OBJECT_NAMES_BLOCK);
	},

	onSelectInputKeyUp : function(component, event, helper) {
		helper.setTimer(component, callback, 500);

		function callback() {
			helper.checkQueryFieldsCheckbox();
			helper.setSOQL();
		}
	}
})