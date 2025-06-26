import Quickshell
import Quickshell.Io
import QtQuick
import "../../../config" as Config
import "../../../components" as Components

Item {
    id: root
    property string time

    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height

    Components.StyledText {
        text: root.time || "Loading..."
    }

    Process {
        id: dateProc
        command: ["date", "+%I:%M %p - %A"]
        running: true

        stdout: SplitParser {
            onRead: data => root.time = data
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: dateProc.running = true
    }
}
