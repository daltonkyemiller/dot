import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "../../../config" as Config
import "../../../services" as Services

Item {
    id: container
    visible: Services.Recorder.recording
    implicitWidth: 20
    implicitHeight: 20
    Rectangle {
        id: animatedRect
        anchors.fill: parent
        radius: width / 2
        color: Qt.rgba(1, 0, 0, 0.5)
        SequentialAnimation {
            running: true
            loops: Animation.Infinite
            ParallelAnimation {
                NumberAnimation {
                    target: animatedRect
                    property: "scale"
                    to: 1.5
                    duration: 1000
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.Animation.anim.curves.standard
                }
                NumberAnimation {
                    target: animatedRect
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 1000
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.Animation.anim.curves.standard
                }
            }
            NumberAnimation {
                target: animatedRect
                property: "scale"
                to: 1
                duration: 1000
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Animation.anim.curves.standard
            }
        }
    }
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.7
        height: parent.height * 0.7
        radius: width / 2
        color: Qt.rgba(1, 0, 0, 1)
    }
}
