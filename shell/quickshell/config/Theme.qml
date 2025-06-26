pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    readonly property Colors colors: Colors {}
    readonly property Style style: Style {}

    component Colors: QtObject {
        property color fg: Qt.rgba(242 / 255, 236 / 255, 188 / 255, 1)
        property color muted: Qt.rgba(107 / 255, 106 / 255, 97 / 255, 1)
        property color bg: Qt.rgba(24 / 255, 22 / 255, 22 / 255, 0.7)
        property color border: Qt.rgba(107 / 255, 106 / 255, 97 / 255, 1)
    }
    component Style: QtObject {
        id: style
        property real fontSize: 12
        property QtObject fontSizes: QtObject {
            property real xs: style.fontSize - 2
            property real sm: style.fontSize - 1
            property real md: style.fontSize
            property real lg: style.fontSize + 6
            property real xl: style.fontSize + 12
            property real xxl: style.fontSize + 18
        }
        property QtObject radius: QtObject {
            property real xs: 2
            property real sm: 4
            property real md: 6
            property real lg: 10
        }
        property real borderWidth: 1
        property QtObject iconSizes: QtObject {
            property real xs: 20
            property real sm: 24
            property real md: 32
            property real lg: 48
            property real xl: 64
            property real xxl: 96
        }
    }
}
