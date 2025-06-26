pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    property var drawers: ({})
    property var popups: ({})
    property var indicators: ({})

    enum Popup {
        AppLauncher = 0
    }

    enum Drawer {
        Left = 0,
        Right = 1
    }

    enum Indicator {
        Recording = 0
    }

    function setDrawerState(name, value) {
        let newValue;
        if (typeof value === "function") {
            newValue = value(root.drawers[name]);
        } else {
            newValue = value;
        }
        root.drawers[name] = newValue;
        drawerStateChanged(name, newValue);
        drawersChanged();
    }

    function setPopupState(name, value) {
        let newValue;
        if (typeof value === "function") {
            newValue = value(root.popups[name]);
        } else {
            newValue = value;
        }
        root.popups[name] = newValue;
        popupStateChanged(name, newValue);
        popupsChanged();
    }
    function setIndicatorState(name, value) {
        let newValue;
        if (typeof value === "function") {
            newValue = value(root.indicators[name]);
        } else {
            newValue = value;
        }
        root.indicators[name] = newValue;
        indicatorStateChanged(name, newValue);
        indicatorsChanged();
    }

    signal drawerStateChanged(int name, bool value)
    signal popupStateChanged(int name, bool value)
    signal indicatorStateChanged(int name, bool value)
}
