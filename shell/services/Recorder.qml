pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool recording: false

    Process {
        id: process
        running: true

        command: ["pgrep", "-x", "wf-recorder"]
        onExited: code => {
            root.recording = code === 0;
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            process.running = true;
        }
    }
}
