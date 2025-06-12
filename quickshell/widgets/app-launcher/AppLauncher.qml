pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import "../../config" as Config
import "../../components" as UI
import "../../services" as Services

PanelWindow {
    id: root

    property list<DesktopEntry> apps: Services.Apps.fuzzySearch(input.text)
    property int selectedIndex: 0

    WlrLayershell.namespace: "dkm_blur"
    WlrLayershell.layer: WlrLayer.Overlay

    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Ignore

    visible: Services.Visibilities.appLauncher

    onVisibleChanged: {
        if (visible) {
            input.focus = true;
            input.text = "";
            root.selectedIndex = 0;
            enter_animation.start();
        } else {}
    }
    focusable: true

    ClippingRectangle {
        id: launcher_content

        ParallelAnimation {
            id: enter_animation
            NumberAnimation {
                target: launcher_content
                property: "scale"
                from: 0.5
                to: 1
                duration: 300
                easing.type: Easing.InOutCirc
            }

            NumberAnimation {
                target: launcher_content
                property: "opacity"
                from: 0
                to: 1
                duration: 300
                easing.type: Easing.InOutSine
            }
        }
        opacity: 0

        implicitHeight: 600
        implicitWidth: 500
        border.color: Config.Theme.colors.border
        border.width: Config.Theme.style.borderWidth
        anchors.centerIn: parent
        color: Config.Theme.colors.bg
        clip: true
        radius: Config.Theme.style.radius.md

        Item {
            implicitHeight: 50
            implicitWidth: 500
            UI.StyledTextInput {
                id: input
                anchors.verticalCenter: parent.verticalCenter
                x: 10
                width: parent.width
                activeFocusOnTab: true
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
                        Services.Visibilities.appLauncher = false;
                    }
                    if (event.key === Qt.Key_Escape) {
                        Services.Visibilities.appLauncher = false;
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
            model: root.apps
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: root.selectedIndex
            highlightFollowsCurrentItem: false
            onCurrentIndexChanged: {
                app_list.positionViewAtIndex(root.selectedIndex, ListView.Center);
                // app_list.contentY =
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
