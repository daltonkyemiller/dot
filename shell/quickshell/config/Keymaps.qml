import Quickshell
import QtQuick
import Quickshell.Io
import "../components"
import "../services"

Scope {
    Shortcut {
        name: "toggle-app-launcher"
        onPressed: {
            Visibilities.setPopupState(Visibilities.Popup.AppLauncher, p => !p);
        }
    }

    Shortcut {
        name: "toggle-left-drawer"
        onPressed: {
            Visibilities.setDrawerState(Visibilities.Drawer.Left, p => !p);
        }
    }

    Shortcut {
        name: "toggle-right-drawer"
        onPressed: {
            Visibilities.setDrawerState(Visibilities.Drawer.Right, p => !p);
        }
    }

    Shortcut {
        name: "toggle-recording-indicator"
        onPressed: {
            Visibilities.setIndicatorState(Visibilities.Indicator.Recording, p => !p);
        }
    }
}
