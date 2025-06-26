import QtQuick
import Quickshell
import "../../../components" as UI
import "../../../services" as Services

Item {
    id: root
    implicitHeight: parent.height
    implicitWidth: childrenRect.width + 20

    UI.StyledText {
        id: text
        anchors.centerIn: parent
        width: Math.min(text.implicitWidth, 300)
        text: Services.Hyprland.activeClient?.title || ""
        elide: Text.ElideRight
        // wrapMode: Text.Wrap
    }
}
