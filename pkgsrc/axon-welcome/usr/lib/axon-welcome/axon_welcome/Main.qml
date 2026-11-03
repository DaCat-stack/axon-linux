// Окно приветствия AXON: три карточки пресетов + «Позже».
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: win
    required property QtObject backend
    required property var presets

    width: 960
    height: 560
    minimumWidth: 760
    minimumHeight: 480
    visible: true
    title: "Добро пожаловать в AXON"
    color: "#0f141f"
    font.family: "Inter"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 6

        RowLayout {
            spacing: 14
            Image {
                source: "file:///usr/share/pixmaps/axon-logo.png"
                sourceSize { width: 44; height: 44 }
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
            }
            Label {
                text: "Добро пожаловать в AXON"
                color: "white"
                font { pixelSize: 26; weight: Font.Bold }
            }
        }
        Label {
            text: "Выбери свой стиль — поменять можно в любой момент"
            color: "#9aa3b2"
            font.pixelSize: 15
            Layout.bottomMargin: 18
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 18

            Repeater {
                model: win.presets
                Rectangle {
                    id: card
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 16
                    color: hover.hovered ? "#1a2232" : "#151b28"
                    border { width: 1; color: hover.hovered ? "#2f86f0" : "#263044" }
                    HoverHandler { id: hover }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12
                        Image {
                            source: "file://" + card.modelData.preview
                            fillMode: Image.PreserveAspectFit
                            Layout.fillWidth: true
                            Layout.preferredHeight: width * 9 / 16
                        }
                        Label {
                            text: card.modelData.title
                            color: "white"
                            font { pixelSize: 17; weight: Font.DemiBold }
                        }
                        Item { Layout.fillHeight: true }
                        Button {
                            id: pick
                            text: "Выбрать"
                            Layout.fillWidth: true
                            onClicked: win.backend.apply(card.modelData.id)
                            contentItem: Label {
                                text: pick.text; color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                font { pixelSize: 14; weight: Font.DemiBold }
                            }
                            background: Rectangle {
                                radius: 9
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: "#28a8a8" }
                                    GradientStop { position: 1; color: "#2f86f0" }
                                }
                                opacity: pick.down ? 0.8 : 1
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.topMargin: 16
            Label {
                text: "Окно можно открыть снова: меню → «AXON: стиль рабочего стола»"
                color: "#6b7588"
                font.pixelSize: 12
                Layout.fillWidth: true
            }
            Button {
                text: "Позже"
                flat: true
                onClicked: win.backend.later()
            }
        }
    }
}
