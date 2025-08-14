import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Controls.Material
import Qt.labs.qmlmodels

ApplicationWindow {
	id: mainWindow
	visible: true
	title: "Ledger"

	width: screen.width * 0.9
	height: screen.height * 0.8
	x: (screen.width - width) / 2
	y: (screen.height - height) / 2

	Material.theme: Material.Dark
	Material.accent: Material.Orange

	property int _fontSize: 13

	property int baleAmount: 0;
	property int baleWeight: 0;

	property int day: datePickerDialog.selectedDay;
	property int month: datePickerDialog.selectedMonth;
	property int year: datePickerDialog.selectedYear;

	property int totalWeightSold: 0;
	property int totalBaleSold: 0;
	property int totalAmount: 0;
	property int totalReceivedAmount: 0;

	property string successColor: "#A5D6A7";
	property string errorColor: "#EF9A9A";
	property string autocompleteBy: "";
	property bool suppressClosingLoadingPopup: false

	Component.onCompleted: {
		suppressClosingLoadingPopup = false;
		loadingPopup.open();
		firebase.get_daily_records(getDate());
	}

	function getDate() {
		const paddedMonth = String(month).padStart(2, '0')
		const paddedDay = String(day).padStart(2, '0')
		return paddedDay + "-" + paddedMonth + "-" + year;
	}

	function formatNumber(value) {
		return Number(value).toLocaleString(Qt.locale("en_IN"), 'f', 0);
	}

	Connections {
		target: firebase

		function onGetUsersResponse(data) {

			if(autocompleteBy === "inputDialog") {
				inputDialog.populateAutocomplete(data);
			} else if(autocompleteBy === "namedPopup") {
				namedRecordPopup.populateAutocomplete(data);
			}
		}

		function onDeleteRecordResponse(response) {

			if(response.error) {
				snackbar.showError("Failed to delete record.");
			} else {
				snackbar.showInfo("Record deleted successfully.");

				totalAmount += response.totalAmountDelta;
				totalBaleSold += response.totalBaleSoldDelta;
				totalWeightSold += response.totalWeightSoldDelta;
				totalReceivedAmount += response.totalReceivedAmountDelta;

				baleAmount += response.baleAmountDelta;
				baleWeight += response.baleWeightDelta;

				central.removeRow(response.docID)
			}

			loadingPopup.hide();
		}

		function onGetBaleResponse(response)  {

			if(!response.error) {
				baleAmount = response.baleAmount;
				baleWeight = response.baleWeight;
			} else {
				snackbar.showError("Failed to load bale data.");
			}

			if(!suppressClosingLoadingPopup) {
				loadingPopup.hide();
			} else {
				suppressClosingLoadingPopup = false;
			}
		}

		function onSetBaleResponse(response)  {

			if(response.error) {
				snackbar.showError("Failed to update bale data.");
			} else {
				baleAmount = response.baleAmount;
				baleWeight = response.baleWeight;
				snackbar.showInfo("Bale data updated successfully.");
				baleDialog.close();
			}

			loadingPopup.hide();
		}

		function onGetDailyRecordsResponseMetadata(data) {

			if(data.error) {
				snackbar.showError("Error fetching records.");
				loadingPopup.close();
				return;
			}

			if(data.empty) {
				totalAmount = 0;
				totalBaleSold = 0;
				totalWeightSold = 0;
				totalReceivedAmount = 0;

				central.clearModel();
				loadingPopup.close();
			} else {
				totalAmount = data.totalAmount;
				totalBaleSold = data.totalBaleSold;
				totalWeightSold = data.totalWeightSold;
				totalReceivedAmount = data.totalReceivedAmount;
			}
		}

		function onGetDailyRecordsResponse(records) {

			if(records.error) {
				snackbar.showError("Error fetching records.");
			} else {
				central.setModel(records);
			}

			loadingPopup.close();
		}
	}

	DatePickerDialog {
		id: datePickerDialog

		onDateChanged: {
			loadingPopup.open();
			central.clearModel();
			firebase.get_daily_records(getDate());
		}
	}


	InputDialog {
		id: inputDialog

		onNewRecordAdded: (record) => {
			totalBaleSold += record.baleSold;
			totalWeightSold += record.weightSold;
			totalAmount += record.amount;
			totalReceivedAmount += record.receivedAmount;
			baleAmount -= record.baleSold;
			baleWeight -= record.weightSold;

			central.addRecord(record);
		}
	}

	NamedRecordPopup {
		id: namedRecordPopup
	}

	UserRecordPopup {
		id: userRecordPopup
	}

	MonthlyTotalsPopup {
		id: monthlyTotalsPopup
	}

	LoadingPopup {
		id: loadingPopup
	}

	BaleDialog {
		id: baleDialog
		baleAmount: mainWindow.baleAmount
		baleWeight: mainWindow.baleWeight
	}

	Rectangle {
		id: snackbar
		width: parent.width * 0.8
		height: 48
		radius: 18
		color: "#323232"
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 30
		opacity: 0
		visible: false
		border.width: 0
		parent: Overlay.overlay
		z: 100000

		Behavior on opacity {
			NumberAnimation { duration: 500 }
		}

		Text {
			id: infoText
			anchors.centerIn: parent
			text: snackbar.message
			color: Material.foreground
			font.pointSize: 14
		}

		property string message: ""

		Timer {
			id: hideTimer
			interval: 3000

			onTriggered: {
				snackbar.opacity = 0
				hideTimer.stop()
			}
		}

		function showInfo(msg) {
			snackbar.color = successColor;
			infoText.color = "#E8F5E9A";
			message = msg;
			visible = true;
			opacity = 1;
			hideTimer.restart();
		}

		function showError(msg) {
			snackbar.color = Material.color(Material.error);
			infoText.color = "white";

			message = msg;
			visible = true;
			opacity = 1;
			hideTimer.restart();
		}

		onOpacityChanged: {
			if(opacity === 0) {
				visible = false
			}
		}
	}

	ColumnLayout {
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		spacing: 20

		ToolBar {
			id: toolBar
			Layout.fillWidth: true
			contentHeight: 60

			background: Rectangle {
				color: "#4b4b4b"
				border.width: 0
			}

			RowLayout {
				anchors.fill: parent
				spacing: 40
				anchors.leftMargin: 30
				anchors.rightMargin: 30

				Button {
					id: inputDialogButton
					Layout.alignment: Qt.AlignCenter
					font.pointSize: 12
					Layout.fillWidth: true
					Layout.preferredWidth: 300

					text: qsTr("Add Entry");

					onClicked: {
						inputDialog.open();
					}
				}

				Button {
					id: namedRecordButton
					Layout.alignment: Qt.AlignCenter
					font.pointSize: 12
					Layout.fillWidth: true
					Layout.preferredWidth: 300

					text: qsTr("Customer Record");

					onClicked: {
						namedRecordPopup.open();
					}
				}

				Button {
					id: datePickButton
					Layout.alignment: Qt.AlignCenter
					font.pointSize: 12
					Layout.fillWidth: true
					Layout.preferredWidth: 300

					text: qsTr(day + "/" + month + "/" + year);

					onClicked: {
						datePickerDialog.open();
					}
				}

				Button {
					id: baleButton
					Layout.alignment: Qt.AlignCenter
					font.pointSize: 12
					Layout.fillWidth: true
					Layout.preferredWidth: 300

					text: qsTr("Bale in Stock: ") + formatNumber(baleWeight) + " kg"

					onClicked: {
						baleDialog.open();
					}
				}
			}
		}

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.leftMargin: 20
			Layout.rightMargin: 20
			spacing: 20


			RowLayout {
				spacing: 20
				Layout.fillWidth: true

				Card {
					Layout.fillWidth: true
					Layout.preferredHeight: 80
					
					ColumnLayout {
						anchors.centerIn: parent
						spacing: 5

						Text {
							id: totalBaleText
							text: formatNumber(totalBaleSold)
							font.pointSize: _fontSize + 6
							font.weight: Font.Bold
							color: Material.accent
							Layout.alignment: Qt.AlignHCenter
						}

						Text {
							text: "Total Bales Sold"
							font.pointSize: _fontSize - 1
							color: Material.foreground
							Layout.alignment: Qt.AlignHCenter
						}
					}
				}
			
				Card {
					Layout.fillWidth: true
					Layout.preferredHeight: 80

					ColumnLayout {
						anchors.centerIn: parent
						spacing: 5
						
						Text {
							id: totalWeightText
							text: formatNumber(totalWeightSold)
							font.pointSize: _fontSize + 6
							font.weight: Font.Bold
							color: Material.accent
							Layout.alignment: Qt.AlignHCenter
						}

						Text {
							text: "Total Weight Sold (kg)"
							font.pointSize: _fontSize - 1
							color: Material.foreground
							Layout.alignment: Qt.AlignHCenter
						}
					}
				}

				Card {
					Layout.fillWidth: true
					Layout.preferredHeight: 80

					ColumnLayout {
						anchors.centerIn: parent
						spacing: 5
						
						Text {
							id: totalAmountText
							text: formatNumber(totalAmount)
							font.pointSize: _fontSize + 6
							font.weight: Font.Bold
							color: Material.accent
							Layout.alignment: Qt.AlignHCenter
						}

						Text {
							text: "Total Amount"
							font.pointSize: _fontSize - 1
							color: Material.foreground
							Layout.alignment: Qt.AlignHCenter
						}
					}
				}

				Card {
					Layout.fillWidth: true
					Layout.preferredHeight: 80

					ColumnLayout {
						anchors.centerIn: parent
						spacing: 5
						
						Text {
							id: totalReceivedText
							text: formatNumber(totalReceivedAmount)
							font.pointSize: _fontSize + 6
							font.weight: Font.Bold
							color: Material.accent
							Layout.alignment: Qt.AlignHCenter
						}

						Text {
							text: "Total Received Amount"
							font.pointSize: _fontSize - 1
							color: Material.foreground
							Layout.alignment: Qt.AlignHCenter
						}
					}
				}
			}

			component Card: Rectangle {
				radius: 14
				color: "#4b4b4b"
			}

			Central {
				id: central
			}
		}
	}
}
