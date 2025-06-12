import Quickshell
import QtQuick
import Quickshell.Io
import "../components"
import "../services"

Scope {
    Shortcut {
        name: "toggle-app-launcher"
        onPressed: {
            Visibilities.appLauncher = !Visibilities.appLauncher;
        }
    }
}
