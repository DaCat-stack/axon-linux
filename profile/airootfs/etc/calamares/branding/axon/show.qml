// AXON: слайды во время установки (меняются каждые 6 секунд)
import QtQuick
import calamares.slideshow 1.0

Presentation {
    id: presentation

    function onActivate() { timer.running = true }
    function onLeave() { timer.running = false }

    Timer {
        id: timer
        interval: 6000
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    component AxonSlide: Slide {
        id: slide
        property string heading
        property string body
        Rectangle {
            anchors.fill: parent
            radius: 12
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#0f1d33" }
                GradientStop { position: 1; color: "#0b1324" }
            }
            border { width: 1; color: "#2c3546" }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 34
                spacing: 26
                Image {
                    source: "logo.png"
                    width: 90; height: 90
                    sourceSize { width: 180; height: 180 }
                    anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: slide.width - 220
                    spacing: 6
                    Text { text: slide.heading; color: "white"; font { pixelSize: 20; weight: Font.DemiBold } }
                    Text { text: slide.body; color: "#9aa3b2"; font.pixelSize: 14; wrapMode: Text.WordWrap; width: parent.width }
                }
            }
        }
    }

    AxonSlide { heading: "Игры из Steam"; body: "Steam и Proton уже установлены — большинство игр с Windows запускаются в один клик." }
    AxonSlide { heading: "Программы Windows"; body: "Двойной клик по .exe — и он откроется через Wine. Для лаунчеров есть Lutris." }
    AxonSlide { heading: "Твой стиль"; body: "При первом запуске выбери раскладку: Windows, Mac или Ubuntu. Поменять можно в любой момент." }
    AxonSlide { heading: "Магазин приложений"; body: "Discover — всё ставится в пару кликов, как в магазине на телефоне." }
}
