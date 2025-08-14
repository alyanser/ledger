import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Controls.Material

ApplicationWindow {
	id: passwordDialog
	title: qsTr("Login")
	flags: Qt.WindowStaysOnTopHint | Qt.WindowCloseButtonHint | Qt.Dialog
	visible: true
	width: screen.width * 0.4
	height: screen.height * 0.3
	x: (screen.width - width) / 2
	y: (screen.height - height) / 2

	Material.theme: Material.Dark
	Material.accent: Material.Orange

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 20
		spacing: 10

		Text {
			Layout.alignment: Qt.AlignHCenter
			text: qsTr("Enter Password")
			font.pixelSize: 20
			font.bold: true
			color: Material.foreground
		}

		RowLayout {
			spacing: 20

			TextField {
				id: passwordField
				focus: true
				Layout.alignment: Qt.AlignHCenter
				Layout.fillWidth: true
				placeholderText: qsTr("Password")
				echoMode: TextInput.Password
				font.pointSize: 12
				horizontalAlignment: TextInput.AlignHCenter
				verticalAlignment: TextInput.AlignVCenter
				onAccepted: okButton.clicked();
			}

			Button {
				id: showPasswordButton
				Layout.preferredWidth: 80
				text: qsTr("Show")

				onClicked: {
					if(passwordField.echoMode === TextInput.Password) {
						passwordField.echoMode = TextInput.Normal;
						showPasswordButton.text = qsTr("Hide");
					} else {
						passwordField.echoMode = TextInput.Password;
						showPasswordButton.text = qsTr("Show");
					}
				}
			}
		}

		Button {
			id: okButton
			Layout.alignment: Qt.AlignHCenter
			Layout.preferredWidth: 200
			font.bold: true
			font.pointSize: 12
			text: qsTr("OK")


			onClicked: {

				if(!passwordField.text.length) {
					passwordField.forceActiveFocus();
					invalidPassword = true;
					return;
				}

				if(password_auth.validate_password(passwordField.text)) {
					passwordDialog.close();
					return;
				}

				invalidPasswordPopup.open();
			}
		}
	}

	Popup {
		id: invalidPasswordPopup
		focus: true
		anchors.centerIn: parent
		width: parent.width * 0.5
		height: parent.height * 0.4
		closePolicy: Popup.NoAutoClose

		FocusScope {
			anchors.fill: parent
			focus: true

			Keys.onReturnPressed: invalidPasswordPopup.close();
			Keys.onEscapePressed: invalidPasswordPopup.close();

			ColumnLayout {
				anchors.fill: parent

				Text {
					Layout.alignment: Qt.AlignHCenter
					text: qsTr("Invalid Password")
					color: Material.color(Material.Error)
					font.bold: true
					font.pointSize: 12
				}

				Button {
					Layout.alignment: Qt.AlignHCenter
					text: qsTr("OK")
					onClicked: invalidPasswordPopup.close();
				}
			}
		}
	}
}
