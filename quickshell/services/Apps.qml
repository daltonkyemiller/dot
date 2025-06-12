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
        const foo =  applications.filter(a => a.name.toLowerCase().includes(text.toLowerCase()))
        return foo
    }

    function launch(app: DesktopEntry) {
        launchProcess.app = app;
        launchProcess.startDetached()
    }

    Process {
        id: launchProcess
        property DesktopEntry app

        command: ["gtk-launch", `${app.id}.desktop`]
    }
}
