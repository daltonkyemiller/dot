import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import "../config" as Config
import "../services" as Services
import "../components" as UI

Item {
    id: root
    anchors.fill: parent
    clip: false

    UI.StyledText {
        text: Services.Mouse.mouseX
    }
}
