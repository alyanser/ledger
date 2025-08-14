import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Popup {
	id: root
	modal: true
	focus: true

	anchors.centerIn: parent
	width: parent.width * 0.9
	height: parent.height * 0.8

	property int _fontSize: 13

	background: Rectangle {
		color: Material.background
		radius: 15
		border.width: 0
	}

	function clearModel() {
		recordModel.clear();
	}

	property int totalBaleSold: 0
	property int totalWeightSold: 0
	property int totalAmount: 0
	property int totalReceivedAmount: 0
	property int debt: 0
	property string name: ""
	property string phone: ""

	function setMetadata(data) {

		if(data.error) {
			snackbar.showError("Error fetching records.");
			return;
		}

		if(data.empty) {
			snackbar.showInfo("No records found for this customer.");
			clearModel();
			return;
		}

		name = data.name;
		phone = data.phone;
		totalBaleSold = data.totalBaleSold;
		totalWeightSold = data.totalWeightSold;
		totalAmount = data.totalAmount;
		totalReceivedAmount = data.totalReceivedAmount;
		debt = data.debt;
	}

	function setModel(data) {
		recordModel.clear();

		if(data.empty) {
			return;
		}

		data.records.forEach(function(item) {

			recordModel.append({
				docID: item.docID,
				baleSold: item.baleSold,
				weightSold: item.weightSold,
				rate: item.rate.toFixed(1),
				amount: item.amount,
				receivedAmount: item.receivedAmount,
				date: item.date
			});
		});
	}

	Rectangle {
		anchors.fill: parent
		color: Material.background

		ColumnLayout {
			anchors.fill: parent
			spacing: 10

			Label {
				text: qsTr("Customer Record")
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
				Layout.leftMargin: 30
				Layout.rightMargin: 30

				Label {
					text: "Name"
					Layout.alignment: Qt.AlignLeft
					Layout.preferredWidth: 100
					font.pointSize: _fontSize
					horizontalAlignment: Text.AlignHCenter
				}

				TextField {
					id: nameField
					text: name
					Layout.fillWidth: true
					font.pointSize: _fontSize
					readOnly: true
					horizontalAlignment: Text.AlignHCenter
					validator: RegularExpressionValidator { regularExpression: /^[a-zA-Z\s]+$/ }
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
					text: phone
					Layout.fillWidth: true
					readOnly: true
					font.pointSize: _fontSize
					horizontalAlignment: Text.AlignHCenter
					validator: RegularExpressionValidator { regularExpression: /^[\d+\-]+$/ }
				}
			}

			RowLayout {
				spacing: 20
				Layout.fillWidth: true
				Layout.fillHeight: true

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
							id: totalReceivedAmountText
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

			Card {
				Layout.fillWidth: true
				Layout.preferredHeight: 80
				
				ColumnLayout {
					anchors.centerIn: parent
					spacing: 5

					Text {
						id: debtText
						text: formatNumber(debt)
						font.pointSize: _fontSize + 6
						font.weight: Font.Bold
						color: debt > 0 ? errorColor : successColor
						Layout.alignment: Qt.AlignHCenter
					}

					Text {
						text: "Total Debt"
						font.pointSize: _fontSize - 1
						color: Material.foreground
						Layout.alignment: Qt.AlignHCenter
					}
				}
			}

			ColumnLayout {
				Layout.fillWidth: true
				Layout.fillHeight: true
				spacing: 0

				RowLayout {
					Layout.fillWidth: true
					Layout.preferredHeight: 50
					spacing: 0

					Repeater {
						model: ["Date", "Bale Sold", "Weight Sold", "Rate", "Amount", "Recv Amount", "Pending Amount" ]

						delegate: TextField {
							id: headerTextField
							text: modelData
							readOnly: true
							Layout.fillWidth: true
							horizontalAlignment: Text.AlignHCenter
							font.pointSize: _fontSize + 1
							font.bold: true
							Component.onCompleted: cursorPosition = 0
						}
					}
				}

				ListView {
					Layout.fillWidth: true
					Layout.fillHeight: true
					clip: true
					orientation: ListView.Vertical

					ListModel {
						id: recordModel
					}

					model: recordModel

					delegate: Item {
						width: ListView.view.width
						height: 60

						RowLayout {
							spacing: 0
							anchors.fill: parent

							TextField {
								text: model.date
								readOnly: true
								horizontalAlignment: Text.AlignHCenter
								font.pointSize: _fontSize
								Layout.fillWidth: true
							}

							TextField {
								text: formatNumber(model.baleSold)
								readOnly: true
								horizontalAlignment: Text.AlignHCenter
								font.pointSize: _fontSize
								Layout.fillWidth: true
							}

							TextField {
								text: formatNumber(model.weightSold)
								readOnly: true
								horizontalAlignment: Text.AlignHCenter
								font.pointSize: _fontSize
								Layout.fillWidth: true
							}

							TextField {
								text: model.rate
								readOnly: true
								horizontalAlignment: Text.AlignHCenter
								font.pointSize: _fontSize
								Layout.fillWidth: true
							}

							TextField {
								text: formatNumber(model.amount)
								readOnly: true
								horizontalAlignment: Text.AlignHCenter
								font.pointSize: _fontSize
								Layout.fillWidth: true
							}

							TextField {
								text: formatNumber(model.receivedAmount)
								readOnly: true
								horizontalAlignment: Text.AlignHCenter
								font.pointSize: _fontSize
								Layout.fillWidth: true
							}

							TextField {
								text: formatNumber(model.amount - model.receivedAmount)
								readOnly: true
								horizontalAlignment: Text.AlignHCenter
								font.pointSize: _fontSize
								Layout.fillWidth: true
								color: model.amount - model.receivedAmount > 0 ? errorColor : successColor
							}
						}
					}
				}
			}
		}
	}
}
