import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Popup {
	id: baleDialog
	focus: true
	modal: true
	anchors.centerIn: parent

	width: parent.width * 0.6
	height: parent.height * 0.7

	property int baleAmount;
	property int baleWeight;

	Component.onCompleted: {
		if(typeof firebase !== 'undefined') {
			loadingPopup.show();
			firebase.get_bale();
		}
	}

	background: Rectangle {
		color: Material.background
		radius: 8
		border.width: 0
	}

	onVisibleChanged: {

		if (visible) {
			baleAmountField.text = "";
			baleWeightField.text = "";
		}
	}

	Rectangle {
		anchors.fill: parent
		color: Material.background

		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 20

			Label {
				text: qsTr("Bale Management")
				font.pointSize: 26
				font.bold: true
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignHCenter
				Layout.alignment: Qt.AlignHCenter
			}

			Label {
				text: qsTr("Bale Amount")
				font.pointSize: 24
				font.bold: true
				Layout.fillWidth: true
			}

			RowLayout {
				Layout.fillWidth: true
				Layout.fillHeight: true
				spacing: 20

				TextField {
					id: baleAmountField
					placeholderText: qsTr("Enter new amount")
					font.pointSize: 14
					Layout.fillWidth: true
					Layout.maximumWidth: 400
					validator: IntValidator { bottom: 0 }
				}

				Label {
					text: qsTr("Existing Amount: ") + formatNumber(baleAmount)
					font.pointSize: 14
				}
			}

			Label {
				text: qsTr("Bale Weight")
				font.pointSize: 24
				font.bold: true
				Layout.fillWidth: true
				Layout.alignment: Qt.AlignLeft
			}

			RowLayout {
				Layout.fillWidth: true
				Layout.fillHeight: true
				spacing: 20

				TextField {
					id: baleWeightField
					placeholderText: qsTr("Enter new weight")
					font.pointSize: 14
					Layout.fillWidth: true
					Layout.maximumWidth: 400
					validator: IntValidator { bottom: 0 }
				}

				Label {
					text: qsTr("Existing Weight: ") + formatNumber(baleWeight) + qsTr(" kg(s)")
					font.pointSize: 14
				}

			}

			RowLayout {
				Layout.fillWidth: true
				Layout.fillHeight: true
				Layout.alignment: Qt.AlignHCenter
				spacing: 40

				Button {
					id: updateButton
					text: qsTr("Update")
					font.pointSize: 16
					Layout.fillWidth: true
					Layout.alignment: Qt.AlignHCenter
					Layout.preferredWidth: 100

					Keys.onReturnPressed: clicked();
					Keys.onEnterPressed: clicked();

					onClicked: {
						var newbaleAmount;
						var newbaleWeight;

						if(baleAmountField.text.length > 0) {
							newbaleAmount = parseInt(baleAmountField.text);
						}

						if(baleWeightField.text.length > 0) {
							newbaleWeight = parseInt(baleWeightField.text);
						}

						if(!newbaleAmount && !newbaleWeight) {
							baleAmountField.forceActiveFocus();
							return;
						}

						loadingPopup.show();

						const amountToSet = newbaleAmount || baleAmount;
						const weightToSet = newbaleWeight || baleWeight;

						firebase.set_bale(amountToSet, weightToSet);
					}
				}

				Button {
					text: qsTr("Cancel")
					font.pointSize: 12
					Layout.fillWidth: true
					Layout.alignment: Qt.AlignHCenter
					Layout.preferredWidth: 100

					Keys.onReturnPressed: clicked();
					Keys.onEnterPressed: clicked();
					onClicked: baleDialog.close();
				}
			}
		}
	}
}
