import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import Qt.labs.qmlmodels

Item {
	id: root
	Layout.fillWidth: true
	height: Window.height - 200

	Connections {
		target: firebase

		function onGetMonthlyTotalsResponse(data) {

			if(data.error) {
				snackbar.showError("Error fetching monthly totals.");
				loadingPopup.close();
				return;
			}

			monthlyTotalsPopup.show(data);
			loadingPopup.close();
		}

		function onGetUserRecordsResponseMetadata(data) {

			if(data.error) {
				snackbar.showError("Error fetching records.");
				loadingPopup.close();
				return;
			}

			if(data.empty) {
				snackbar.showError("Customer does not exist in the database.");
				loadingPopup.close();
				namedRecordPopup.focusNameField();
				return;
			}

			userRecordPopup.setMetadata(data);
		}

		function onGetUserRecordsResponse(data) {

			if(data.error) {
				snackbar.showError("Error fetching records.");
			} else if(!data.empty) {
				namedRecordPopup.close();
				userRecordPopup.setModel(data);
				userRecordPopup.open();
			} else {
				snackbar.showError("Customer exists but has no records (This should not happen!).");
			}

			loadingPopup.close();
		}
	}

	function clearModel() {
		recordModel.clear();
	}

	function removeRow(docID) {

		for(let i = 0; i < recordModel.count; i++) {

			if(recordModel.get(i).docID === docID) {
				recordModel.remove(i);
				return;
			}
		}
	}

	function setModel(data) {
		recordModel.clear();

		if(data.empty) {
			return;
		}

		data.records.forEach(function(item) {

			recordModel.append({
				docID: item.docID,
				name: item.name,
				baleSold: item.baleSold,
				weightSold: item.weightSold,
				rate: item.rate.toFixed(1),
				amount: item.amount,
				receivedAmount: item.receivedAmount
			});
		});
	}

	function addRecord(record) {

		recordModel.append({
			docID: record.docID,
			name: record.name,
			baleSold: record.baleSold,
			weightSold: record.weightSold,
			rate: record.rate.toFixed(1),
			amount: record.amount,
			receivedAmount: record.receivedAmount
		});
	}

	Menu {
		id: totalsMenu
		font.pointSize: _fontSize - 2

		MenuItem {
			text: "Get Monthly Totals"

			onTriggered: {
				loadingPopup.open();
				firebase.get_monthly_totals(month, year);
			}
		}
	}

	function recordUnderMouse() {

		for(let i = 0; i < recordList.count; ++i) {
			let item = recordList.itemAtIndex(i);

			if(item && item.containsMouse) {
				return true;
			}
		}

		return false;
	}

	MouseArea {
		id: mouseArea
		anchors.fill: parent
		acceptedButtons: Qt.RightButton
		propagateComposedEvents: true

		onClicked: function(mouse) {

			if(mouse.button === Qt.RightButton) {

				if(!recordUnderMouse()) {
					mouse.accepted = true;
					totalsMenu.popup(Qt.point(mouse.x, mouse.y));
					return;
				}
			}

			mouse.accepted = false;
		}
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: 0

		RowLayout {
			Layout.fillWidth: true
			Layout.preferredHeight: 50
			spacing: 0

			Repeater {
				model: [ "Name", "Bale Sold", "Weight Sold", "Rate", "Amount", "Recv Amount", "Pending Amount" ]

				delegate: TextField {
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
			id: recordList
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
				property int selectedIndex: -1

				Component.onCompleted: {
					nameTextField.cursorPosition = 0;
				}

				RowLayout {
					spacing: 0
					anchors.fill: parent

					TextField {
						id: nameTextField
						text: model.name
						readOnly: true
						horizontalAlignment: Text.AlignHCenter
						font.pointSize: _fontSize
						Layout.fillWidth: true
						color: selectedIndex === index ? Material.accent : Material.foreground

						Behavior on color {
							ColorAnimation {
								duration: 200
								easing.type: Easing.InOutQuad
							}
						}
					}

					TextField {
						text: formatNumber(model.baleSold)
						readOnly: true
						horizontalAlignment: Text.AlignHCenter
						font.pointSize: _fontSize
						Layout.fillWidth: true
						color: selectedIndex === index ? Material.accent : Material.foreground

						Behavior on color {
							ColorAnimation {
								duration: 200
								easing.type: Easing.InOutQuad
							}
						}
					}

					TextField {
						text: formatNumber(model.weightSold)
						readOnly: true
						horizontalAlignment: Text.AlignHCenter
						font.pointSize: _fontSize
						Layout.fillWidth: true
						color: selectedIndex === index ? Material.accent : Material.foreground

						Behavior on color {
							ColorAnimation {
								duration: 200
								easing.type: Easing.InOutQuad
							}
						}
					}

					TextField {
						text: model.rate
						readOnly: true
						horizontalAlignment: Text.AlignHCenter
						font.pointSize: _fontSize
						Layout.fillWidth: true
						color: selectedIndex === index ? Material.accent : Material.foreground

						Behavior on color {
							ColorAnimation {
								duration: 200
								easing.type: Easing.InOutQuad
							}
						}
					}

					TextField {
						text: formatNumber(model.amount)
						readOnly: true
						horizontalAlignment: Text.AlignHCenter
						font.pointSize: _fontSize
						Layout.fillWidth: true
						color: selectedIndex === index ? Material.accent : Material.foreground

						Behavior on color {
							ColorAnimation {
								duration: 200
								easing.type: Easing.InOutQuad
							}
						}
					}

					TextField {
						text: formatNumber(model.receivedAmount)
						readOnly: true
						horizontalAlignment: Text.AlignHCenter
						font.pointSize: _fontSize
						Layout.fillWidth: true
						color: selectedIndex === index ? Material.accent : Material.foreground

						Behavior on color {
							ColorAnimation {
								duration: 200
								easing.type: Easing.InOutQuad
							}
						}
					}

					TextField {
						id: pendingTextField
						text: formatNumber(model.amount - model.receivedAmount)
						readOnly: true
						horizontalAlignment: Text.AlignHCenter
						font.pointSize: _fontSize
						Layout.fillWidth: true
						color: selectedIndex === index ? Material.accent :
							(model.amount - model.receivedAmount) > 0 ? errorColor : successColor

						Behavior on color {
							ColorAnimation {
								duration: 200
								easing.type: Easing.InOutQuad
							}
						}
					}
				}

				MouseArea {
					anchors.fill: parent

					acceptedButtons: Qt.RightButton
					propagateComposedEvents: true
					preventStealing: true
					hoverEnabled: true

					onClicked:(mouse) => {

						if(mouse.button === Qt.RightButton) {
							contextMenu.popup(Qt.point(mouse.x, mouse.y));
							mouse.accepted = true;
							selectedIndex = index;
						} else {
							mouse.accepted = false;
						}
					}
				}

				Menu {
					id: contextMenu
					onClosed: selectedIndex = -1;
					font.pointSize: _fontSize - 2

					MenuItem {
						text: "View Details"

						onTriggered: {
							loadingPopup.open()
							firebase.get_user_records(model.name)
						}
					}

					MenuItem {
						text: "Print"

						onTriggered: {
							snackbar.showInfo("Printing is not implemented yet.");
						}
					}

					MenuSeparator {}

					MenuItem {
						text: "Delete"

						onTriggered: {
							confirmPopup.open();
						}
					}

					Popup {
						id: confirmPopup
						focus: true
						modal: true
						visible: false
						anchors.centerIn: Overlay.overlay
						width: root.width * 0.7
						height: root.height * 0.3
						closePolicy: Popup.NoAutoClose

						background : Rectangle {
							color: Material.background
							radius: 10
							border.width: 0
						}

						ColumnLayout {
							anchors.fill: parent
							spacing: 0

							Text {
								Layout.alignment: Qt.AlignHCenter
								text: qsTr("Are you sure you want to delete this record?")
								color: Material.color(Material.Error)
								font.bold: true
								font.pointSize: _fontSize + 2
							}

							RowLayout {
								Layout.fillWidth: true
								Layout.fillHeight: true
								Layout.alignment: Qt.AlignHCenter
								spacing: 20

								Button {
									Layout.preferredWidth: 200
									Layout.alignment: Qt.AlignHCenter
									font.pointSize: _fontSize
									text: qsTr("Yes")

									onClicked: {
										loadingPopup.open();

										const data = {
											date: getDate(),
											docID: model.docID,
											baleSold: model.baleSold,
											weightSold: model.weightSold,
											amount: model.amount,
											name: model.name,
											receivedAmount: model.receivedAmount,
										};

										firebase.delete_record(data);
									}
								}

								Button {
									Layout.preferredWidth: 200
									Layout.alignment: Qt.AlignHCenter
									text: qsTr("No")
									font.pointSize: _fontSize
									onClicked: confirmPopup.close();
								}
							}
						}
					}

					MenuSeparator {}

					MenuItem {
						text: "Get Monthly Totals"

						onTriggered: {
							loadingPopup.open();
							firebase.get_monthly_totals(month, year);
						}
					}
				}
			}
		}
	}

}
