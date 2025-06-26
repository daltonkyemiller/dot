import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "dkm_blur_ignorealpha"

    mask: Region {
        regions: [
            Region {
                item: leftDrawer
            },
            Region {
                item: rightDrawer
            }
        ]
    }

    LeftDrawer {
        id: leftDrawer
    }

    RightDrawer {
        id: rightDrawer
    }
}

