pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    readonly property Colors colors: Colors {}
    readonly property Style style: Style {}

    component Colors: QtObject {
        property color fg: Qt.rgba(242 / 255, 236 / 255, 188 / 255, 1)
        property color bg: Qt.rgba(24 / 255, 22 / 255, 22 / 255, 0.8)
        property color border: Qt.rgba(107 / 255, 106 / 255, 97 / 255, 1)
    }
    component Style: QtObject {
        property real fontSize: 12
        property QtObject radius: QtObject {
            property real xs: 2
            property real sm: 4
            property real md: 6
            property real lg: 10
        }
        property real borderWidth: 1
        property real iconSize: 32
    }
}
