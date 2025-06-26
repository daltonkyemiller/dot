pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../components" as UI
import "../../config" as Config
import "../../services" as Services

PanelWindow {
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "dkm_blur_ignorealpha"
    color: "transparent"
    anchors.right: true
    anchors.left: true
    anchors.top: true
    anchors.bottom: true

    mask: Region {
        item: content
    }

    Item {
        id: content
        property var notifications: [...Services.Notifications.notifications.map(notif => notif)].reverse()

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Config.BarConfig.height + 10
        anchors.rightMargin: 10
        implicitWidth: childrenRect.width
        implicitHeight: notifications.length > 0 ? childrenRect.height : 0
        clip: true
        // visible: notifications.length > 0

        ListView {
            id: list
            interactive: false
            clip: true
            spacing: list.isActivated ? 10 : -120

            implicitWidth: Config.Notification.width
            onCountChanged: {

                // get QQuickItem which is a root element which hosts delegate items
                var root = list.visibleChildren[0];
                var listViewHeight = 0;
                // var listViewWidth = 0;

                // iterate over each delegate item to get their sizes
                for (var i = 0; i < root.visibleChildren.length; i++) {
                    listViewHeight += root.visibleChildren[i].height;
                    // listViewWidth = Math.max(listViewWidth, root.visibleChildren[i].width);
                }

                list.height = listViewHeight;
                // list.width = listViewWidth;
            }

            model: ScriptModel {
                values: content.notifications
            }

            property bool isActivated: false

            // cacheBuffer: QsWindow.window?.screen.height ?? 0

            displaced: Transition {
                NumberAnimation {
                    property: "y"
                    duration: 300

                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.Animation.anim.curves.standard
                }
            }

            remove: Transition {
                SequentialAnimation {
                    PropertyAction {
                        property: "z"
                        value: 0
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: 200
                        }
                        NumberAnimation {
                            property: "scale"
                            to: 0.5
                            duration: 200

                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Config.Animation.anim.curves.standard
                        }
                    }
                }
            }

            add: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "y"
                        from: -20
                        duration: 200
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Config.Animation.anim.curves.standard
                    }
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 200
                    }
                }
            }

            delegate: NotificationItem {
                isActivated: list.isActivated
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    list.isActivated = true;
                }
                onExited: {
                    list.isActivated = false;
                }
                preventStealing: true
                onClicked: e => {
                    e.accepted = false;
                }
                onPressed: e => {
                    e.accepted = false;
                }
            }
            Behavior on spacing {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.Animation.anim.curves.standard
                }
            }
        }
    }
}
