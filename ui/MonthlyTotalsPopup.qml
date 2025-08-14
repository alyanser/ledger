import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Popup {
	id: root
	modal: true
	focus: true

	anchors.centerIn: parent
	width: parent.width * 0.6
	height: parent.height * 0.6

	property int _fontSize: 15

	background: Rectangle {
		color: Material.background
		radius: 8
		border.width: 0
	}

	property int totalBaleSold: 0
	property int totalWeightSold: 0
	property int totalAmount: 0
	property int totalReceivedAmount: 0

	function show(data) {
		const monthName = Qt.locale().monthName(data.month - 1);
		headingLabel.text = qsTr("Monthly Totals - %1").arg(monthName);

		totalBaleSold = data.totalBaleSold;
		totalWeightSold = data.totalWeightSold;
		totalAmount = data.totalAmount;
		totalReceivedAmount = data.totalReceivedAmount;

		open();
	}

	Rectangle {
		anchors.fill: parent
		color: Material.background

		ColumnLayout {
			anchors.fill: parent

			Label {
				id: headingLabel
				text: ""
				font.pointSize: 24
				font.bold: true
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignHCenter
				Layout.alignment: Qt.AlignHCenter
			}

			ColumnLayout {
				spacing: 20
				Layout.leftMargin: 30
				Layout.rightMargin: 30

				RowLayout {
					Layout.fillWidth: true
					Layout.fillHeight: true

					Label {
						Layout.fillWidth: true
						text: "Total Bales Sold"
						Layout.alignment: Qt.AlignLeft
						Layout.preferredWidth: 100
						font.pointSize: _fontSize
						horizontalAlignment: Text.AlignHCenter
					}

					TextField {
						id: totalBaleField
						text: formatNumber(totalBaleSold)
						Layout.fillWidth: true
						font.pointSize: _fontSize
						readOnly: true
						horizontalAlignment: Text.AlignHCenter
					}
				}

				RowLayout {
					Layout.fillWidth: true
					Layout.fillHeight: true

					Label {
						Layout.fillWidth: true
						text: "Total Weight Sold"
						Layout.alignment: Qt.AlignLeft
						Layout.preferredWidth: 100
						font.pointSize: _fontSize
						horizontalAlignment: Text.AlignHCenter
					}

					TextField {
						id: totalWeightField
						text: formatNumber(totalWeightSold)
						Layout.fillWidth: true
						readOnly: true
						font.pointSize: _fontSize
						horizontalAlignment: Text.AlignHCenter
					}
				}

				RowLayout {
					Layout.fillWidth: true
					Layout.fillHeight: true

					Label {
						Layout.fillWidth: true
						text: "Total Amount"
						Layout.alignment: Qt.AlignLeft
						Layout.preferredWidth: 100
						font.pointSize: _fontSize
						horizontalAlignment: Text.AlignHCenter
					}

					TextField {
						id: totalAmountField
						text: formatNumber(totalAmount)
						Layout.fillWidth: true
						readOnly: true
						font.pointSize: _fontSize
						horizontalAlignment: Text.AlignHCenter
					}
				}

				RowLayout {
					Layout.fillWidth: true
					Layout.fillHeight: true

					Label {
						Layout.fillWidth: true
						text: "Total Amount Received"
						Layout.alignment: Qt.AlignLeft
						Layout.preferredWidth: 100
						font.pointSize: _fontSize
						horizontalAlignment: Text.AlignHCenter
					}

					TextField {
						id: totalReceivedField
						text: formatNumber(totalReceivedAmount)
						Layout.fillWidth: true
						readOnly: true
						font.pointSize: _fontSize
						horizontalAlignment: Text.AlignHCenter
					}
				}
			}
		}
	}
}
