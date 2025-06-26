//@ pragma IconTheme Adwaita-Dalton

import Quickshell
import Quickshell.Wayland
import QtQuick
import "widgets"
import "widgets/bar"
import "widgets/drawers" as Drawers
import "widgets/app-launcher"
import "widgets/notifications"
import "config"
import "services" as Services

ShellRoot {
    Bar {}
    AppLauncher {}
    Notifications {}
    Drawers.Wrapper {}

    // Helpers
    BlurWindow {}

    // Config
    Keymaps {}
}
