// Круглый аватар: картинка в тёмном круге, как в макете (лого AXON занимает 58%).
import QtQuick
import QtQuick.Effects

Item {
    id: avatar
    property real size: 80
    property url source: "logo.png"
    property bool selected: false
    readonly property bool isLogo: String(source).indexOf("logo.png") >= 0

    width: size
    height: size

    Rectangle {
        id: circle
        anchors.fill: parent
        radius: width / 2
        gradient: Gradient {
            GradientStop { position: 0; color: "#1d2a44" }
            GradientStop { position: 1; color: "#0b1120" }
        }
        border { width: avatar.selected ? 2 : 1; color: avatar.selected ? "white" : Qt.rgba(1, 1, 1, 0.18) }
    }

    Image {
        id: photo
        anchors.centerIn: parent
        width: avatar.isLogo ? parent.width * 0.58 : parent.width
        height: width
        source: avatar.source
        sourceSize { width: width * 2; height: height * 2 }
        fillMode: avatar.isLogo ? Image.PreserveAspectFit : Image.PreserveAspectCrop
        visible: avatar.isLogo
    }

    // фото пользователя обрезаем по кругу
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: width / 2
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: photo
        source: photo
        visible: !avatar.isLogo
        maskEnabled: true
        maskSource: mask
    }
}
