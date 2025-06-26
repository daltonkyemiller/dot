pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

import "../../config" as Config
import "../../components" as UI
import "../../services" as Services

LazyLoader {
    activeAsync: Services.Visibilities.popups[Services.Visibilities.Popup.AppLauncher]

    PanelWindow {
        id: root

        property var apps: Services.Apps.fuzzySearch(input.text).slice(0, 15)
        property int selectedIndex: 0

        WlrLayershell.namespace: "dkm_blur_ignorealpha"
        WlrLayershell.layer: WlrLayer.Overlay
        // HyprlandWindow.opacity: 0.9

        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }
        exclusionMode: ExclusionMode.Ignore

        visible: Services.Visibilities.popups[Services.Visibilities.Popup.AppLauncher]

        Connections {
            target: Services.Visibilities
            function onPopupStateChanged(name, value) {
                if (name !== Services.Visibilities.Popup.AppLauncher) {
                    return;
                }
                if (value) {
                    return;
                }
                exitAnimation.start();
            }
        }
        focusable: true

        ClippingRectangle {
            id: launcherContent
            anchors.centerIn: parent

            ParallelAnimation {
                id: enterAnimation
                running: true

                NumberAnimation {
                    target: launcherContent
                    property: "scale"
                    from: 0.5
                    to: 1
                    duration: 500
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.Animation.anim.curves.standard
                }

                NumberAnimation {
                    target: launcherContent
                    property: "anchors.verticalCenterOffset"
                    from: 200
                    to: 0
                    duration: 500
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.Animation.anim.curves.standard
                }

                NumberAnimation {
                    target: launcherContent
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 300
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.Animation.anim.curves.standard
                }
            }

            ParallelAnimation {
                id: exitAnimation
                NumberAnimation {
                    target: launcherContent
                    property: "scale"
                    from: 1
                    to: 0.5
                    duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.Animation.anim.curves.standard
                }

                NumberAnimation {
                    target: launcherContent
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 150
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.Animation.anim.curves.standard
                }

                onFinished: {
                    root.visible = false;
                }
            }
            opacity: 0

            implicitHeight: !input.text ? 50 : 500
            implicitWidth: 500
            border.color: Config.Theme.colors.border
            border.width: Config.Theme.style.borderWidth
            color: Config.Theme.colors.bg
            clip: true
            radius: Config.Theme.style.radius.md
            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Config.Animation.anim.curves.standard
                }
            }

            Item {
                id: inputContainer
                implicitHeight: 50
                implicitWidth: 500
                UI.StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 10
                    visible: !input.text
                    text: "Search..."
                    color: Config.Theme.colors.muted
                }

                UI.StyledTextInput {
                    id: input
                    anchors.verticalCenter: parent.verticalCenter
                    x: 10
                    width: parent.width
                    activeFocusOnTab: true
                    focus: true
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Up) {
                            if (root.selectedIndex === 0) {
                                root.selectedIndex = root.apps.length - 1;
                                return;
                            }
                            root.selectedIndex--;
                        }
                        if (event.key === Qt.Key_Down) {
                            if (root.selectedIndex === root.apps.length - 1) {
                                root.selectedIndex = 0;
                                return;
                            }
                            root.selectedIndex++;
                        }

                        if (event.key === Qt.Key_Return) {
                            const app = root.apps[root.selectedIndex];
                            Services.Apps.launch(root.apps[root.selectedIndex]);
                            Services.Visibilities.setPopupState(Services.Visibilities.Popup.AppLauncher, false);
                        }

                        if (event.key === Qt.Key_Escape) {
                            Services.Visibilities.setPopupState(Services.Visibilities.Popup.AppLauncher, false);
                        }
                    }
                }
            }

            Rectangle {
                y: input.parent.height
                height: Config.Theme.style.borderWidth
                width: parent.width
                color: Config.Theme.colors.border
            }

            ListView {
                id: app_list
                y: input.parent.height
                implicitWidth: parent.width
                implicitHeight: parent.height - input.parent.height
                clip: true
                model: ScriptModel {
                    values: root.apps
                }

                // cacheBuffer: QsWindow.window?.screen.height ?? 0
                orientation: ListView.Vertical
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.selectedIndex
                highlightFollowsCurrentItem: false
                onCurrentIndexChanged: {
                    app_list.positionViewAtIndex(root.selectedIndex, ListView.Center);
                }

                add: Transition {
                    SequentialAnimation {
                        PropertyAction {
                            property: "opacity"
                            value: 0
                        }

                        ParallelAnimation {
                            // PauseAnimation {}
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 200
                            }
                            NumberAnimation {
                                property: "scale"
                                from: 0.5
                                to: 1
                                duration: 200

                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Config.Animation.anim.curves.standard
                            }
                        }
                    }
                }
                remove: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 200
                    }
                }

                displaced: Transition {
                    PropertyAction {
                        properties: "scale, opacity"
                        value: 1
                    }
                    NumberAnimation {
                        property: "y"
                        duration: 300

                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Config.Animation.anim.curves.standard
                    }
                }

                // Add a vertical scrollbar
                ScrollBar.vertical: ScrollBar {
                    active: true // Always show scrollbar when content overflows
                    policy: ScrollBar.AsNeeded
                }

                delegate: AppItem {
                    selected: root.selectedIndex === index
                }
            }
        }
    }
}
