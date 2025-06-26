pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    readonly property list<DesktopEntry> applications: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    readonly property list<var> prepped: applications.map(a => ({
                name: a.name,
                icon: a.icon
            }))

    function fuzzySearch(text) {
        return applications.filter(a => a.name.toLowerCase().includes(text.toLowerCase()))
    }

    function launch(app: DesktopEntry) {
        launchProcess.app = app;
        launchProcess.startDetached()
    }

    Process {
        running: false
        id: launchProcess
        property DesktopEntry app

        command: ["gtk-launch", `${app?.id}.desktop`]
    }
}
