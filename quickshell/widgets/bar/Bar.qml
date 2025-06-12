pragma ComponentBehavior: Bound

import "../../config" as Config
import "components" as BarComponents

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData
            color: "transparent"
            WlrLayershell.namespace: "dkm_blur_ignorealpha"

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top: 5
                left: 20
                right: 20
            }

            implicitHeight: 40

            BarComponents.BarSection {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }

                Row {
                    spacing: 10
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    BarComponents.Media {}
                }
            }

            BarComponents.BarSection {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                }

                Row {
                    spacing: 10
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    BarComponents.Clock {
                        id: clock
                    }
                }
            }
        }
    }
}
