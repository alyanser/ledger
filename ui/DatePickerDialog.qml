import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Controls.Material

Dialog {
	id: datePickerDialog
	focus: true
	modal: true

	anchors.centerIn: parent
	width: parent.width * 0.7
	height: parent.height * 0.8

	property int tempDay: new Date().getDate()
	property int tempMonth: new Date().getMonth() + 1
	property int tempYear: new Date().getFullYear()

	property int selectedDay: new Date().getDate()
	property int selectedMonth: new Date().getMonth() + 1
	property int selectedYear: new Date().getFullYear()

	background: Rectangle {
		color: Material.background
		radius: 8
		border.width: 0
	}

	signal dateChanged()
	Component.onCompleted: {
		dayTextField.focus = true;
	}

	contentItem: FocusScope {
		focus: true

		Keys.onPressed: (event) => {

			if(event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
				validateDate();
			} else if(event.key === Qt.Key_Escape) {
				datePickerDialog.close();
			}
		}

		Rectangle {
			anchors.fill: parent
			color: Material.background

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: 20
				spacing: 50

				Button {
					id: selectButton
					text: qsTr("Select Date")
					font.pointSize: 12
					Layout.alignment: Qt.AlignHCenter
					Layout.preferredHeight: 70
					Layout.preferredWidth: parent.width / 3

					onClicked: {
						validateDate();
					}
				}

				RowLayout {
					Layout.fillWidth: true
					Layout.fillHeight: true
					spacing: 20

					TextField {
						id: dayTextField
						placeholderText: "Date"
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						font.pointSize: 16
						validator: IntValidator { bottom: 1; top: 31 }

						onTextChanged: {
							if(text) {
								tempDay = parseInt(text)
								dayListView.positionViewAtIndex(tempDay - 1, ListView.Center);
							}
						}
					}

					TextField {
						id: monthTextField
						placeholderText: "Month"
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						font.pointSize: 16
						validator: IntValidator { bottom: 1; top: 12 }

						onTextChanged: {
							if(text) {
								tempMonth = parseInt(text);
								monthListView.positionViewAtIndex(tempMonth - 1, ListView.Center);
							}
						}
					}

					TextField {
						id: yearTextField
						placeholderText: "Year"
						Layout.fillWidth: true
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						font.pointSize: 16
						validator: IntValidator { bottom: 2000; top: 2050 }

						onTextChanged: {
							if(text) {
								tempYear = parseInt(text);
								yearListView.positionViewAtIndex(tempYear - 2000, ListView.Center);
							}
						}
					}
				}

				RowLayout {
					Layout.fillWidth: true
					Layout.fillHeight: true
					Layout.alignment: Qt.AlignHCenter

					ListModel {
						id: dayModel

						Component.onCompleted: {

							for(var i = 1; i <= 31; i++) {
								dayModel.append({ day: i });
							}
						}
					}

					ListModel {
						id: monthModel

						Component.onCompleted: {

							for(var i = 1; i <= 12; ++i) {
								monthModel.append({ month: i });
							}
						}
					}

					ListModel {
						id: yearModel

						Component.onCompleted: {

							for(var i = 2000; i <= 2050; ++i) {
								yearModel.append({ year: i });
							}
						}
					}

					ListView {
						id: dayListView
						Layout.fillWidth: true
						Layout.fillHeight: true

						model: dayModel
						orientation: ListView.Vertical

						delegate: Item {
							width: ListView.view.width
							height: 50

							Label {
								text: model.day
								anchors.centerIn: parent
								color: model.day === tempDay ? Material.accent : Material.foreground
								font.pointSize: model.day === tempDay ? 16 : 12

								SequentialAnimation on scale {
									id: jiggleAnimDay
									running: false
									loops: 1
									NumberAnimation { to: 1.4; duration: 100; easing.type: Easing.OutQuad }
									NumberAnimation { to: 0.8; duration: 100; easing.type: Easing.InOutQuad }
									NumberAnimation { to: 1.0; duration: 100; easing.type: Easing.OutQuad }
								}
							}

							MouseArea {
								anchors.fill: parent

								onClicked: {
									jiggleAnimDay.start();
									tempDay = modelData;
									dayTextField.text = tempDay;
								}
							}
						}
					}

					ListView {
						id: monthListView
						Layout.fillHeight: true
						Layout.fillWidth: true

						model: monthModel

						orientation: ListView.Vertical

						delegate: Item {
							width: ListView.view.width
							height: 50

							Label {
								id: monthLabel
								text: model.month
								anchors.centerIn: parent
								color: model.month === tempMonth ? Material.accent : Material.foreground
								font.pointSize: model.month === tempMonth ? 16 : 12

								SequentialAnimation on scale {
									id: jiggleAnim
									running: false
									loops: 1
									NumberAnimation { to: 1.4; duration: 100; easing.type: Easing.OutQuad }
									NumberAnimation { to: 0.8; duration: 100; easing.type: Easing.InOutQuad }
									NumberAnimation { to: 1.0; duration: 100; easing.type: Easing.OutQuad }
								}
							}

							MouseArea {
								anchors.fill: parent

								onClicked: {
									jiggleAnim.start();

									monthTextField.text = modelData;
									tempMonth = modelData;
								}
							}
						}
					}

					ListView {
						id: yearListView
						Layout.fillHeight: true
						Layout.fillWidth: true
						orientation: ListView.Vertical
						model: yearModel

						delegate: Item {
							width: ListView.view.width
							height: 50

							Label {
								id: yearLabel
								text: model.year
								anchors.centerIn: parent
								color: model.year === tempYear ? Material.accent : Material.foreground
								font.pointSize: model.year === tempYear ? 16 : 12

								SequentialAnimation on scale {
									id: jiggleAnimYear
									running: false
									loops: 1
									NumberAnimation { to: 1.4; duration: 100; easing.type: Easing.OutQuad }
									NumberAnimation { to: 0.8; duration: 100; easing.type: Easing.InOutQuad }
									NumberAnimation { to: 1.0; duration: 100; easing.type: Easing.OutQuad }
								}
							}

							MouseArea {
								anchors.fill: parent

								onClicked: {
									jiggleAnimYear.start();
									tempYear = modelData;
									yearTextField.text = tempYear;
								}
							}
						}
					}
				}

			}

		}
	}

	onVisibleChanged: {

		if(visible) {
			snapTimer.restart();
		}
	}

	Timer {
		id: snapTimer
		interval: 30
		repeat: false
		running: false

		onTriggered: {

			if(datePickerDialog.visible) {
				dayListView.positionViewAtIndex(selectedDay - 1, ListView.Center)
				monthListView.positionViewAtIndex(selectedMonth, ListView.Center)
				yearListView.positionViewAtIndex(selectedYear - 2000, ListView.Center)

				dayTextField.text = selectedDay.toString();
				monthTextField.text = selectedMonth.toString();
				yearTextField.text = selectedYear.toString();
			}
		}
	}

	function validateDate() {

		if(tempYear < 2000 || tempYear > 2050) {
			snackbar.showError("Invalid Date.");
			return;
		}

		const date = new Date(tempYear, tempMonth - 1, tempDay);

		if(tempYear === date.getFullYear() && tempMonth === date.getMonth() + 1 && tempDay === date.getDate()) {
			selectedDay = tempDay;
			selectedMonth = tempMonth;
			selectedYear = tempYear;

			datePickerDialog.close();
			dateChanged()
		} else {
			snackbar.showError("Invalid Date.");
		}
	}
}
