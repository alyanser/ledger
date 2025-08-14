import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Controls.Material

Popup {
	id: loadingPopup
	modal: true
	focus: true
	dim: false
	closePolicy: Popup.NoAutoClose

	x: (parent.width - width) / 2
	y: (parent.height - height) / 2

	background: Rectangle {
		color: "transparent"
	}

	Spinner {}

	function show() { visible = true }
	function hide() { visible = false }
}
