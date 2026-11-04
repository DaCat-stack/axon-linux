// AXON — окно входа (SDDM, Qt 6). Вариант C из login-screen.html:
// верхняя панель как в Ubuntu + стеклянная карточка как на маке.
import QtQuick
import QtQuick.Effects

Item {
    id: root
    width: 1920
    height: 1080

    // 1 px макета (экран 1200×675) → px этого экрана, × uiScale из theme.conf (0.7 — одобрено на 1920×1080)
    readonly property real s: height / 675 * (Number(config.uiScale) > 0 ? Number(config.uiScale) : 0.7)
    readonly property string fontFamily: config.font || "Inter"

    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background || "background.png"
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        anchors.fill: wallpaper
        source: wallpaper
        blurEnabled: true
        blurMax: 64
        blur: 0.45
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(5 / 255, 8 / 255, 15 / 255, 0.25) }

    // карточка и панели — только на основном экране, на остальных лишь обои
    Loader {
        anchors.fill: parent
        active: primaryScreen
        sourceComponent: Item {
            TopBar {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                s: root.s
                fontFamily: root.fontFamily
            }
            LoginCard {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.47 - height / 2
                s: root.s
                fontFamily: root.fontFamily
            }
            PowerBar {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.045
                s: root.s
                fontFamily: root.fontFamily
            }
        }
    }

    // плавное появление после экрана загрузки
    Rectangle {
        anchors.fill: parent
        color: "#07090d"
        NumberAnimation on opacity { from: 1; to: 0; duration: 400; easing.type: Easing.OutCubic }
    }
}
