pragma ComponentBehavior: Bound

import "components" as BarComponents
import "../../components" as UI
import "../../config" as Config
import "../../services" as Services

import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PanelWindow {
    id: root
    property var modelData
    screen: modelData
    color: "transparent"
    WlrLayershell.namespace: "dkm_blur_ignorealpha"

    anchors {
        top: true
        left: true
        right: true
    }

    margins.top: 5

    component DrawerTrigger: Rectangle {
        id: drawerTrigger
        required property int drawer
        property bool hovered: false
        implicitHeight: parent.height
        implicitWidth: 20
        radius: Config.Theme.style.radius.md
        color: hovered ? Config.Theme.colors.border : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.Animation.anim.curves.standard
            }
        }
        MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            onClicked: {
                Services.Visibilities.setDrawerState(drawer, p => !p);
            }
            onEntered: {
                drawerTrigger.hovered = true;
            }
            onExited: {
                drawerTrigger.hovered = false;
            }
        }
    }

    implicitHeight: Config.BarConfig.height

    DrawerTrigger {
        id: leftDrawerTrigger
        drawer: Services.Visibilities.Drawer.Left
    }

    BarComponents.BarSection {
        id: activeWindow
        implicitHeight: parent.height
        implicitWidth: childrenRect.width
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: leftDrawerTrigger.right
        BarComponents.ActiveWindow {}
    }

    BarComponents.BarSection {
        id: media
        implicitHeight: parent.height
        implicitWidth: childrenRect.width
        anchors.horizontalCenter: parent.horizontalCenter

        HoverHandler {
            onHoveredChanged: {
                Services.Visibilities.setDrawerState("media", hovered);
            }
        }

        BarComponents.Media {
            window: root
            padding: 10
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    BarComponents.BarSection {
        anchors.right: rightDrawerTrigger.left
        Row {
            spacing: 10
            padding: 10
            height: parent.height

            BarComponents.RecordingIndicator {
                id: recordingIndicator
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                visible: Services.Recorder.recording
                width: 1
                height: parent.height - parent.padding * 2
                anchors.verticalCenter: parent.verticalCenter
                color: Config.Theme.colors.border
            }
            BarComponents.Battery {
                id: battery
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 1
                height: parent.height - parent.padding * 2
                anchors.verticalCenter: parent.verticalCenter
                color: Config.Theme.colors.border
            }

            BarComponents.Clock {
                id: clock

                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    DrawerTrigger {
        id: rightDrawerTrigger
        anchors.right: parent.right
        drawer: Services.Visibilities.Drawer.Right
    }
}
