import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Popup {
	id: root
	modal: true
	focus: true

	anchors.centerIn: parent
	width: parent.width * 0.5
	height: parent.height * 0.5

	property int _fontSize: 15
	property bool wasSubmitted: false

	background: Rectangle {
		color: Material.background
		radius: 12
		border.width: 0
	}

	onVisibleChanged: {

		if(visible) {
			autocompleteBy = "namedPopup";
			nameField.forceActiveFocus();

			if(nameField.text.length > 0) {
				firebase.get_users(nameField.text);
			} else {
				autocompletePopup.close();
			}

		} else {
			autocompleteBy = "";
			autocompletePopup.close();

			if(wasSubmitted) {
				nameField.text = "";
			}

			wasSubmitted = false;
		}

		nameField.forceActiveFocus();
	}

	function focusNameField() {
		nameField.forceActiveFocus();
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

	Rectangle {
		anchors.fill: parent
		color: Material.background

		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 20

			Label {
				id: headingLabel
				text: "Customer Record"
				font.pointSize: 24
				font.bold: true
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignHCenter
				Layout.alignment: Qt.AlignHCenter
			}

			Item {
				Layout.fillWidth: true
				Layout.preferredHeight: 15
			}

			TextField {
				id: nameField
				Layout.fillWidth: true
				placeholderText: "Enter customer's name"
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
					implicitHeight: Math.min(contentHeight, Window.height * 0.5)

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

									nameField.suppress = true;
									nameField.text = nameVal;
									nameField.suppress = false;

									autocompletePopup.close();
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

			Item {
				Layout.fillWidth: true
				Layout.preferredHeight: 10
			}

			RowLayout {
				Layout.fillWidth: true
				Layout.preferredHeight: 50
				spacing: 30
				Layout.leftMargin: 25
				Layout.rightMargin: 25

				Button {
					id: submitButton
					text: "Get Record"
					Layout.fillWidth: true
					Layout.alignment: Qt.AlignHCenter
					font.pointSize: _fontSize

					onClicked: {

						if(nameField.text.length === 0) {
							nameField.forceActiveFocus();
							return;
						}

						wasSubmitted = true;
						loadingPopup.open();

						firebase.get_user_records(nameField.text);
					}
				}

				Button {
					id: cancelButton
					text: "Cancel"
					Layout.fillWidth: true
					Layout.alignment: Qt.AlignHCenter
					font.pointSize: _fontSize

					onClicked: root.close();
				}
			}
		}
	}
}
