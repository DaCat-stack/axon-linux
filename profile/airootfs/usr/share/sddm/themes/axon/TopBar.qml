// Верхняя панель: слева лого + AXON, справа раскладка (клик — следующая), сеть, звук.
import QtQuick

Item {
    id: bar
    property real s: 1
    property string fontFamily: "Inter"
    height: 34 * s

    Row {
        anchors { left: parent.left; leftMargin: 16 * bar.s; verticalCenter: parent.verticalCenter }
        spacing: 8 * bar.s
        Image {
            source: "logo.png"
            width: 18 * bar.s; height: width
            sourceSize.width: 64
            fillMode: Image.PreserveAspectFit
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: "AXON"
            color: "white"
            font { family: bar.fontFamily; pixelSize: 13 * bar.s; weight: Font.Bold; letterSpacing: 13 * bar.s * 0.2 }
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        anchors { right: parent.right; rightMargin: 16 * bar.s; verticalCenter: parent.verticalCenter }
        spacing: 16 * bar.s
        opacity: 0.9

        Text {
            id: layout
            visible: keyboard.layouts.length > 0
            text: visible ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : ""
            color: "white"
            font { family: bar.fontFamily; pixelSize: 13 * bar.s }
            anchors.verticalCenter: parent.verticalCenter
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6 * bar.s
                cursorShape: Qt.PointingHandCursor
                onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
            }
        }
        Repeater {
            model: ["icons/wifi.svg", "icons/volume.svg"]
            Image {
                source: modelData
                width: 15 * bar.s; height: width
                sourceSize { width: width; height: height }
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
