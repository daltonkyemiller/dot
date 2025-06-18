import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config" as Config
import "../../services" as Services
import "../../components" as UI

Rectangle {
    id: root
    implicitWidth: Services.Visibilities.drawers[Services.Visibilities.Drawer.Right] ? 500 : 0
    implicitHeight: parent.height
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    border.color: Config.Theme.colors.border
    border.width: Config.Theme.style.borderWidth
    color: Config.Theme.colors.bg
    clip: true
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Config.Animation.anim.curves.emphasized
        }
    }
    // y: Config.BarConfig.height
    HoverHandler {
        onHoveredChanged: {
            // console.log(hovered);
            Services.Visibilities.setDrawerState(Services.Visibilities.Drawer.Right, hovered);
        }
    }

    UI.StyledText {
        anchors.centerIn: parent
        text: "Right"
    }
}
