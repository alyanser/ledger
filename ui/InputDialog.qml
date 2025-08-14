import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Dialog {
	id: inputDialog
	focus: true
	modal: true

	anchors.centerIn: parent
	width: parent.width * 0.9
	height: parent.height * 0.7

	property int _fontSize: 13
	property bool wasSubmitted: false

	background: Rectangle {
		color: Material.background
		radius: 8
		border.width: 0
	}

	signal newRecordAdded(var record)

	onVisibleChanged: {

		if(visible) {
			autocompleteBy = "inputDialog";

			if(nameField.text.length === 0) {
				nameField.forceActiveFocus();
			} else if(phoneField.text.length === 0) {
				phoneField.forceActiveFocus();
			} else if(baleField.text.length === 0) {
				baleField.forceActiveFocus();
			} else if(weightField.text.length === 0) {
				weightField.forceActiveFocus();
			} else if(rateField.text.length === 0) {
				rateField.forceActiveFocus();
			} else if(amountPaidField.text.length === 0) {
				amountPaidField.forceActiveFocus();
			}

		} else {
			autocompleteBy = "";
			autocompletePopup.close();

			if(wasSubmitted) {
				clearAllInputs();
				wasSubmitted = false;
			}
		}
	}

	Connections {
		target: firebase

		function onAddRecordResponse(record) {

			if(record.error) {
				snackbar.showError("Error adding record.");
			} else {
				newRecordAdded(record);
				inputDialog.close();
				snackbar.showInfo("Record added successfully.");
				wasSubmitted = true;
			}

			loadingPopup.close();
		}

	}

	function populateAutocomplete(data) {
		autocompletePopup.close();
		autocompleteModel.clear();

		if(data.error) {
			snackbar.showError("Error fetching users.");
			return;
		}

		if(data.empty) {
			return;
		}

		data.users.forEach(user => {

			autocompleteModel.append({
				name: user.name,
				phone: user.phone
			});
		});

		autocompletePopup.open();
	}

	Connections {
		target: nameField

		function onFocusChanged() {


			if(nameField.focus && nameField.text.length > 0) {
				firebase.get_users(nameField.text);
			} else {
				autocompletePopup.close();
			}
		}
	}

	function clearAllInputs() {
		nameField.text = "";
		phoneField.text = "";
		baleField.text = "";
		weightField.text = "";
		rateField.text = "";
		amountPaidField.text = "";
		nameField.forceActiveFocus();
	}

	Rectangle {
		anchors.fill: parent
		color: Material.background

		ColumnLayout {
			anchors.fill: parent
			spacing: 10

			Label {
				text: qsTr("Add Entry")
				font.pointSize: 26
				font.bold: true
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignHCenter
				Layout.alignment: Qt.AlignHCenter
			}

			Item {
				Layout.fillWidth: true
				Layout.preferredHeight: 10
			}

			RowLayout {
				spacing: 20

				Label {
					text: "Name"
					Layout.alignment: Qt.AlignLeft
					Layout.preferredWidth: 100
					font.pointSize: _fontSize
					horizontalAlignment: Text.AlignHCenter
				}

				TextField {
					id: nameField
					Layout.fillWidth: true
					placeholderText: "Enter name"
					font.pointSize: _fontSize
					horizontalAlignment: Text.AlignHCenter
					validator: RegularExpressionValidator { regularExpression: /^[a-zA-Z ]+$/ }
					property bool suppress: false

					onTextChanged: {

						if(suppress) {
							return;
						}

						if(text.length > 0) {
							firebase.get_users(nameField.text);
						} else {
							autocompletePopup.close();
						}
					}
				}

				Popup {
					id: autocompletePopup
					width: nameField.width
					x: nameField.x
					y: nameField.y + nameField.height
					modal: false
					focus: false

					background: Rectangle {
						color: "#4b4b4b"
						radius: 4
					}

					contentItem: ListView {
						id: autocompleteListView
						model: autocompleteModel

						clip: true
						width: parent.width
						implicitHeight: Math.min(contentHeight, inputDialog.height * 0.7)

						delegate: Column {
							width: ListView.view.width
							spacing: 0

							Item {
								width: parent.width
								height: 35

								MouseArea {
									id: itemMouse
									anchors.fill: parent
									hoverEnabled: true

									onClicked: {
										const nameVal = model.name;
										const phoneVal = model.phone;

										nameField.suppress = true;
										nameField.text = nameVal;
										nameField.suppress = false;

										autocompletePopup.close();

										if(phoneVal) {
											phoneField.text = phoneVal;
											baleField.forceActiveFocus();
										} else {
											phoneField.text = "";
											phoneField.forceActiveFocus();
										}
									}
								}

								Text {
									text: name
									width: parent.width
									horizontalAlignment: Text.AlignHCenter
									verticalAlignment: Text.AlignVCenter
									font.pointSize: _fontSize
									color: itemMouse.containsMouse ? Material.accent : Material.foreground

									Behavior on color {
										ColorAnimation {
											duration: 150
										}
									}
								}
							}

							Rectangle {
								width: parent.width
								color: "gray"
								height: index < autocompleteModel.count - 1 ? 1 : 0
							}

							Item {
								width: parent.width
								height: index < autocompleteModel.count - 1 ? 10 : 0
							}
						}
					}
				}

				ListModel {
					id: autocompleteModel
				}

				Label {
					text: "Phone"
					Layout.alignment: Qt.AlignLeft
					Layout.preferredWidth: 100
					font.pointSize: _fontSize
					horizontalAlignment: Text.AlignHCenter
				}

				TextField {
					id: phoneField
					Layout.fillWidth: true
					placeholderText: "Enter Phone Number"
					font.pointSize: _fontSize
					horizontalAlignment: Text.AlignHCenter
					validator: RegularExpressionValidator { regularExpression: /^[\d+\-]+$/ }
				}
			}

			RowLayout {
				spacing: 20

				Label {
					text: "Bale Sold"
					Layout.alignment: Qt.AlignLeft
					Layout.preferredWidth: 100
					font.pointSize: _fontSize
					horizontalAlignment: Text.AlignHCenter
				}

				TextField {
					id: baleField
					Layout.fillWidth: true
					placeholderText: "Enter bale Amount"
					font.pointSize: _fontSize
					horizontalAlignment: Text.AlignHCenter
					validator: IntValidator { bottom: 0; top: baleAmount }
				}

				Label {
					text: "Weight Sold"
					Layout.alignment: Qt.AlignLeft
					Layout.preferredWidth: 100
					font.pointSize: _fontSize
				}

				TextField {
					id: weightField
					Layout.fillWidth: true
					placeholderText: "Enter Bale Weight (kg)"
					font.pointSize: _fontSize
					horizontalAlignment: Text.AlignHCenter
					validator: IntValidator { bottom: 0; top: baleWeight }
				}
			}

			RowLayout {
				spacing: 20

				Label {
					text: "Rate"
					Layout.alignment: Qt.AlignLeft
					font.pointSize: _fontSize
					Layout.preferredWidth: 100
					horizontalAlignment: Text.AlignHCenter
				}

				TextField {
					id: rateField
					Layout.fillWidth: true
					font.pointSize: _fontSize
					placeholderText: "Enter Rate per kg"
					horizontalAlignment: Text.AlignHCenter
					validator: DoubleValidator { bottom: 0.0  }

					Keys.onPressed: (event) => {

						if(event.key == Qt.Key_Tab) {
							event.accepted = true;
							amountPaidField.focus = true;
						}
					}
				}

				Label {
					text: "Amount"
					Layout.alignment: Qt.AlignLeft
					Layout.preferredWidth: 100
					font.pointSize: _fontSize
					horizontalAlignment: Text.AlignHCenter
				}

				TextField {
					id: amountField
					Layout.fillWidth: true
					placeholderText: "Total Amount"
					font.pointSize: _fontSize
					horizontalAlignment: Text.AlignHCenter
					readOnly: true

					text: {
						if(weightField.text && rateField.text) {
							return parseInt((parseFloat(weightField.text) * parseFloat(rateField.text)))
						}

						return "";
					}
				}
			}

			RowLayout {
				spacing: 20

				Label {
					text: "Amount Paid"
					Layout.alignment: Qt.AlignLeft
					Layout.preferredWidth: 100
					font.pointSize: _fontSize
					horizontalAlignment: Text.AlignHCenter
				}

				TextField {
					id: amountPaidField
					Layout.fillWidth: true
					placeholderText: "Enter Amount Paid"
					font.pointSize: _fontSize
					horizontalAlignment: Text.AlignHCenter
					validator: IntValidator { bottom: 0 }

					Keys.onPressed: (event) => {

						if(event.key == Qt.Key_Tab) {
							event.accepted = true;
							nameField.forceActiveFocus();
						} else if(event.key == Qt.Key_Backtab) {
							event.accepted = true;
							rateField.forceActiveFocus();
						}
					}
				}
			}

			RowLayout {
				spacing: 80

				Button {
					text: "Clear"
					font.pointSize: _fontSize - 2
					Layout.alignment: Qt.AlignHCenter
					onClicked: clearAllInputs();
					Layout.preferredWidth: 100
				}

				Button {
					id: submitButton
					text: "Submit"
					font.pointSize: _fontSize + 1
					Layout.alignment: Qt.AlignHCenter
					Layout.fillWidth: true

					onClicked: {

						if(!nameField.text) {
							nameField.forceActiveFocus();
							return;
						} else if(!baleField.text) {
							baleField.forceActiveFocus();
							return;
						} else if(!weightField.text) {
							weightField.forceActiveFocus();
							return;
						} else if(!rateField.text) {
							rateField.forceActiveFocus();
							return;
						} else if(!amountPaidField.text) {
							amountPaidField.forceActiveFocus();
							return;
						}

						{
							const baleFieldValue = parseInt(baleField.text);

							if(baleFieldValue > baleAmount) {
								snackbar.showError("Bale amount exceeds available stock.");
								baleField.forceActiveFocus();
								return;
							}
						}

						{
							const weightFieldValue = parseInt(weightField.text);

							if(weightFieldValue > baleWeight) {
								snackbar.showError("Bale weight exceeds available stock.");
								weightField.forceActiveFocus();
								return;
							}
						}

						loadingPopup.open();

						const record = {
							name: nameField.text,
							phone: phoneField.text,
							baleSold: parseInt(baleField.text),
							weightSold: parseInt(weightField.text),
							rate: parseFloat(rateField.text),
							amount: parseInt(amountField.text),
							receivedAmount: parseInt(amountPaidField.text),
							date: getDate()
						};

						firebase.add_record(record)
					}
				}

				Button {
					text: "Cancel"
					font.pointSize: _fontSize - 2
					Layout.alignment: Qt.AlignHCenter
					Layout.preferredWidth: 100
					onClicked: inputDialog.close();
				}
			}
		}
	}
}
