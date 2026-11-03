// Кнопки внизу экрана: Сон, Перезагрузка, Выключение.
import QtQuick

Row {
    id: power
    property real s: 1
    property string fontFamily: "Inter"
    spacing: 28 * s

    Repeater {
        model: [
            { label: "Сон", icon: "icons/sleep.svg", action: "suspend", can: sddm.canSuspend },
            { label: "Перезагрузка", icon: "icons/restart.svg", action: "reboot", can: sddm.canReboot },
            { label: "Выключение", icon: "icons/power.svg", action: "powerOff", can: sddm.canPowerOff }
        ]
        Column {
            visible: modelData.can
            spacing: 6 * power.s
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 40 * power.s; height: width; radius: width / 2
                color: area.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.14)
                Image {
                    anchors.centerIn: parent
                    source: modelData.icon
                    width: 18 * power.s; height: width
                    sourceSize { width: width; height: height }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm[modelData.action]()
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.label
                color: Qt.rgba(1, 1, 1, 0.85)
                font { family: power.fontFamily; pixelSize: 12 * power.s }
            }
        }
    }
}
