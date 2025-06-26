import QtQuick
import "../config"

Text {
    id: root

    property bool animate: false
    property string animateProp: "scale"
    property real animateFrom: 0
    property real animateTo: 1

    color: Theme.colors.fg
    renderType: Text.NativeRendering
    textFormat: Text.PlainText

    Behavior on color {
        ColorAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
            easing.bezierCurve: [0.25, 0.1, 0.25, 1]
        }
    }
}
