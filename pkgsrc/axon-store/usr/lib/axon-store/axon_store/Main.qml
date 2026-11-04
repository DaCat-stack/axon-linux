// Магазин AXON — по макету store.html: разделы слева, карточки, «Вернуть как было».
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: win
    required property QtObject store
    property string section: "themes"
    property string toast: ""

    width: 1100
    height: 700
    minimumWidth: 860
    minimumHeight: 560
    visible: true
    title: "Магазин AXON"
    color: "#0f141f"
    font.family: "Inter"

    Connections {
        target: win.store
        function onMessage(text) { win.toast = text; toastTimer.restart() }
    }
    Timer { id: toastTimer; interval: 3500; onTriggered: win.toast = "" }

    function shown() {
        return store.items.filter(i => section === "mine" ? i.installed : i.section === section)
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // --- разделы ---
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 220
            color: "#0b1020"
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 2
                RowLayout {
                    Layout.bottomMargin: 14
                    spacing: 10
                    Image { source: "file:///usr/share/pixmaps/axon-logo.png"; sourceSize { width: 30; height: 30 } }
                    ColumnLayout {
                        spacing: 0
                        Label { text: "Магазин AXON"; color: "white"; font { pixelSize: 15; weight: Font.Bold } }
                        Label {
                            text: win.store.checked ? "проверено на Plasma " + win.store.plasmaVersion : "проверенное оформление"
                            color: "#8892a4"; font.pixelSize: 11
                        }
                    }
                }
                Repeater {
                    model: win.store.sections
                    delegate: SectionButton {
                        required property var modelData
                        label: modelData.icon + "  " + modelData.title
                        count: win.store.items.filter(i => i.section === modelData.id).length
                        active: win.section === modelData.id
                        onClicked: win.section = modelData.id
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: "#1c2333"; Layout.topMargin: 8; Layout.bottomMargin: 8 }
                SectionButton {
                    label: "✔  Установлено"
                    count: win.store.items.filter(i => i.installed).length
                    active: win.section === "mine"
                    onClicked: win.section = "mine"
                }
                Item { Layout.fillHeight: true }
            }
        }

        // --- витрина ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 16
                Label {
                    text: win.section === "mine" ? "Установлено"
                        : (win.store.sections.find(s => s.id === win.section) || {}).title || ""
                    color: "white"; font { pixelSize: 19; weight: Font.Bold }
                    Layout.fillWidth: true
                }
                Button {
                    text: "↺ Вернуть как было"
                    onClicked: win.store.revert()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 16; Layout.rightMargin: 16
                implicitHeight: bannerText.implicitHeight + 18
                radius: 10
                color: win.store.checked ? Qt.rgba(40/255, 168/255, 168/255, 0.12) : Qt.rgba(1, 0.78, 0.34, 0.10)
                border.color: win.store.checked ? Qt.rgba(40/255, 168/255, 168/255, 0.35) : Qt.rgba(1, 0.78, 0.34, 0.35)
                Label {
                    id: bannerText
                    anchors.fill: parent; anchors.margins: 9
                    wrapMode: Text.WordWrap
                    color: win.store.checked ? "#bfece9" : "#ffe3a3"
                    text: win.store.checked
                        ? "✔ Всё в магазине проверено этой ночью на KDE Plasma " + win.store.plasmaVersion + " — ничего не сломается после обновления."
                        : "Каталог проверок сейчас недоступен (нет интернета?) — показано всё, что есть."
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 16
                clip: true
                GridLayout {
                    width: parent.width
                    columns: Math.max(1, Math.floor(width / 280))
                    columnSpacing: 14; rowSpacing: 14
                    Repeater {
                        model: win.shown()
                        delegate: StoreCard {
                            required property var modelData
                            item: modelData
                            Layout.fillWidth: true
                            onInstall: win.store.install(modelData.id)
                            onApply: win.store.apply(modelData.id)
                            onRemove: win.store.remove(modelData.id)
                        }
                    }
                    Label {
                        visible: win.shown().length === 0
                        text: win.section === "mine" ? "Пока ничего не установлено" : "Скоро здесь появится подборка"
                        color: "#6b7588"
                    }
                }
            }
        }
    }

    // всплывающее сообщение
    Rectangle {
        visible: win.toast !== ""
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 20 }
        radius: 10; color: "#1a2130"; border.color: "#2c3546"
        width: toastLabel.implicitWidth + 32; height: 40
        Label { id: toastLabel; anchors.centerIn: parent; text: win.toast; color: "white" }
    }

    component SectionButton: Rectangle {
        id: sb
        property string label
        property int count
        property bool active
        signal clicked
        Layout.fillWidth: true
        implicitHeight: 36
        radius: 9
        color: active ? "#1d3557" : (hover.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
        HoverHandler { id: hover }
        TapHandler { onTapped: sb.clicked() }
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
            Label { text: sb.label; color: sb.active ? "white" : "#aab3c2"; Layout.fillWidth: true }
            Label { text: sb.count; color: "#6b7588"; font.pixelSize: 11 }
        }
    }

    component StoreCard: Rectangle {
        id: card
        property var item
        signal install
        signal apply
        signal remove
        implicitHeight: 270
        radius: 12
        color: "#151b28"
        border.color: cardHover.hovered ? "#2f86f0" : "#263044"
        HoverHandler { id: cardHover }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 130
                topLeftRadius: 12; topRightRadius: 12
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: (card.item.preview.gradient || ["#0f1624"])[0] }
                    GradientStop { position: 1; color: (card.item.preview.gradient || ["#0f1624", "#0f1624"])[1] }
                }
                Rectangle {
                    visible: !!card.item.preview.window
                    x: parent.width * 0.14; y: parent.height * 0.16
                    width: parent.width * 0.6; height: parent.height * 0.52; radius: 6
                    color: card.item.preview.window || "transparent"
                    Rectangle { width: parent.width; height: 10; radius: 6; color: card.item.preview.accent || "transparent" }
                }
                Row {
                    visible: !!card.item.preview.dots
                    anchors { left: parent.left; bottom: parent.bottom; margins: 12 }
                    spacing: 5
                    Repeater {
                        model: card.item.preview.dots || []
                        Rectangle { required property string modelData; width: 18; height: 18; radius: 5; color: modelData }
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 12
                spacing: 4
                Label { text: card.item.name; color: "white"; font { pixelSize: 15; weight: Font.Bold } }
                Label { text: card.item.author; color: "#8892a4"; font.pixelSize: 12 }
                Label {
                    text: card.item.description; color: "#aab3c2"; font.pixelSize: 12
                    wrapMode: Text.WordWrap; Layout.fillWidth: true; maximumLineCount: 2; elide: Text.ElideRight
                }
                Label { text: "✔ Проверено"; color: "#3ddc97"; font.pixelSize: 11 }
                Item { Layout.fillHeight: true }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Button {
                        Layout.fillWidth: true
                        enabled: !card.item.busy
                        highlighted: true
                        text: card.item.busy ? "Подожди…" : (card.item.installed ? "Применить" : "Установить")
                        onClicked: card.item.installed ? card.apply() : card.install()
                    }
                    Button {
                        visible: card.item.installed && !card.item.busy
                        text: "Удалить"
                        onClicked: card.remove()
                    }
                }
            }
        }
    }
}
