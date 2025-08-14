import QtQuick 2.15

Item {
	id: spinner
	width: 32
	height: 32

	property color color: "orange"
	property int lineCount: 12
	property int lineWidth: 3
	property int lineLength: 10

	RotationAnimator on rotation {
		from: 0
		to: 360
		duration: 1000
		loops: Animation.Infinite
		easing.type: Easing.Linear
	}

	Repeater {
		model: lineCount

		Rectangle {
			width: spinner.lineWidth
			height: spinner.lineLength
			radius: spinner.lineWidth / 2
			color: Qt.rgba(spinner.color.r, spinner.color.g, spinner.color.b, index / spinner.lineCount)
			anchors.centerIn: parent

			transform: [
				Translate { y: -spinner.height / 2 + spinner.lineLength / 2 },
				Rotation {
					angle: 360 / spinner.lineCount * index
					origin.x: spinner.width / 2
					origin.y: spinner.height / 2
				}
			]
		}
	}
}

