import Quickshell
import QtQuick
import "../../../config" as Config

Rectangle {
    id: root

    property var paddingY: 10
    property var paddingX: 10

    radius: Config.Theme.style.radius.md
    color: Config.Theme.colors.bg
    implicitWidth: childrenRect.width + paddingX * 2
    implicitHeight: parent.height

    border {
        width: Config.Theme.style.borderWidth
        color: Config.Theme.colors.border
    }
}
