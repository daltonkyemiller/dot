pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property int defaultTimeoutMs: 5000
    property int defaultUrgentTimeoutMs: defaultTimeoutMs * 2
    property int width: 400
}
