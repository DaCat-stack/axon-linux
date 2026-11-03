// Стеклянная карточка: часы, дата, аватар, имя, пароль; кружки пользователей, если их больше одного.
import QtQuick
import QtQuick.Effects

Rectangle {
    id: card
    property real s: 1
    property string fontFamily: "Inter"

    property int current: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property string userName: ""
    property string realName: ""
    property string userIcon: ""

    width: column.width + 72 * s
    height: column.height + 44 * s
    radius: 24 * s
    color: Qt.rgba(1, 1, 1, 0.08)
    border { width: Math.max(1, s); color: Qt.rgba(1, 1, 1, 0.14) }
    transform: Translate { id: shake }

    // своя иконка пользователя или лого AXON, если стоит стандартная от SDDM
    function avatarFor(icon) {
        return (!icon || String(icon).indexOf("/usr/share/sddm/faces/") >= 0) ? "logo.png" : icon
    }

    // данные выбранного пользователя из userModel
    Repeater {
        model: userModel
        Item {
            Binding { restoreMode: Binding.RestoreNone; when: index === card.current; target: card; property: "userName"; value: model.name }
            Binding { restoreMode: Binding.RestoreNone; when: index === card.current; target: card; property: "realName"; value: model.realName }
            Binding { restoreMode: Binding.RestoreNone; when: index === card.current; target: card; property: "userIcon"; value: model.icon }
        }
    }

    Column {
        id: column
        anchors.centerIn: parent
        spacing: 0

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"
            font { family: card.fontFamily; pixelSize: 46 * card.s; weight: Font.Bold; letterSpacing: -card.s }
        }
        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 4 * card.s
            bottomPadding: 16 * card.s
            color: "white"
            opacity: 0.8
            font { family: card.fontFamily; pixelSize: 15 * card.s }
        }
        Timer {
            interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
                const now = new Date()
                clock.text = Qt.formatTime(now, "HH:mm")
                const d = Qt.locale("ru_RU").toString(now, "dddd, d MMMM")
                date.text = d.charAt(0).toUpperCase() + d.slice(1)
            }
        }

        Avatar {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 80 * card.s
            source: card.avatarFor(card.userIcon)
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 12 * card.s
            text: card.realName || card.userName
            color: "white"
            font { family: card.fontFamily; pixelSize: 20 * card.s; weight: Font.DemiBold }
        }

        Item { width: 1; height: 14 * card.s }

        Rectangle {
            id: field
            anchors.horizontalCenter: parent.horizontalCenter
            width: 240 * card.s
            height: 36 * card.s
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.14)
            border { width: Math.max(1, card.s); color: Qt.rgba(1, 1, 1, 0.18) }

            TextInput {
                id: password
                anchors { left: parent.left; leftMargin: 16 * card.s; right: go.left; rightMargin: 8 * card.s; verticalCenter: parent.verticalCenter }
                color: "white"
                echoMode: TextInput.Password
                passwordCharacter: "●"
                clip: true
                focus: true
                font { family: card.fontFamily; pixelSize: 14 * card.s }
                Keys.onReturnPressed: card.login()
                Keys.onEnterPressed: card.login()
                Component.onCompleted: forceActiveFocus()
            }
            Text {
                anchors.fill: password
                verticalAlignment: Text.AlignVCenter
                visible: password.text.length === 0
                text: "Введите пароль"
                color: Qt.rgba(1, 1, 1, 0.6)
                font: password.font
            }
            Rectangle {
                id: go
                anchors { right: parent.right; rightMargin: 4 * card.s; verticalCenter: parent.verticalCenter }
                width: 28 * card.s; height: width; radius: width / 2
                color: goArea.containsMouse ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(1, 1, 1, 0.22)
                Image {
                    anchors.centerIn: parent
                    source: "icons/arrow.svg"
                    width: 16 * card.s; height: width
                    sourceSize { width: width; height: height }
                }
                MouseArea { id: goArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.login() }
            }
        }

        // кружки пользователей — только если пользователей больше одного
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: userModel.count > 1
            topPadding: 14 * card.s
            spacing: 10 * card.s
            Repeater {
                model: userModel
                Avatar {
                    size: 44 * card.s
                    source: card.avatarFor(model.icon)
                    selected: index === card.current
                    opacity: selected ? 1 : 0.55
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { card.current = index; password.text = ""; password.forceActiveFocus() }
                    }
                }
            }
        }
    }

    function login() {
        sddm.login(userName, password.text, sessionModel.lastIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
            shakeAnim.restart()
            password.forceActiveFocus()
        }
    }

    // неверный пароль: поле трясётся (±8 px макета, 400 мс)
    SequentialAnimation {
        id: shakeAnim
        loops: 1
        NumberAnimation { target: shake; property: "x"; to: -8 * card.s; duration: 80 }
        NumberAnimation { target: shake; property: "x"; to: 8 * card.s; duration: 80 }
        NumberAnimation { target: shake; property: "x"; to: -8 * card.s; duration: 80 }
        NumberAnimation { target: shake; property: "x"; to: 8 * card.s; duration: 80 }
        NumberAnimation { target: shake; property: "x"; to: 0; duration: 80 }
    }
}
