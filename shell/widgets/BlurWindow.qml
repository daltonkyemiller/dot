import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../services" as Services
import "../config" as Config

PanelWindow {
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "dkm_blur"
    HyprlandWindow.opacity: 0.92
    visible: !!Services.Visibilities.popups[Services.Visibilities.Popup.AppLauncher]
    color: Qt.rgba(Config.Theme.colors.bg.r, Config.Theme.colors.bg.g, Config.Theme.colors.bg.b, 0.5)
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
}
