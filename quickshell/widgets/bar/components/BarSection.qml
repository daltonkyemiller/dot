import Quickshell
import QtQuick
import "../../../config" as Config

Rectangle {
    id: root

    radius: Config.Theme.style.radius.md
    color: Config.Theme.colors.bg

    implicitWidth: childrenRect.width
    implicitHeight: parent.height
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Config.Animation.anim.curves.standard
        }
    }
    clip: true

    border {
        width: Config.Theme.style.borderWidth
        color: Config.Theme.colors.border
    }
}
