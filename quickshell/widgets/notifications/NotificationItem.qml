pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import "../../services" as Services
import "../../components" as UI
import "../../config/" as Config

Item {
    id: root
    required property Services.Notifications.Notif modelData
    required property int index
    required property bool isActivated
    property var bg: Qt.rgba(Config.Theme.colors.bg.r, Config.Theme.colors.bg.g, Config.Theme.colors.bg.b, 1)

    implicitHeight: childrenRect.height
    implicitWidth: parent.width

    z: 100 - index

    scale: isActivated ? 1 : 1 - (index * 0.1)
    clip: true

    Behavior on scale {
        NumberAnimation {
            duration: 200
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Config.Animation.anim.curves.standard
        }
    }

    Rectangle {
        implicitHeight: childrenRect.height
        implicitWidth: parent.width
        radius: Config.Theme.style.radius.md

        color: root.bg
        border.color: Config.Theme.colors.border
        border.width: Config.Theme.style.borderWidth

        ColumnLayout {
            width: parent.width
            RowLayout {
                Layout.preferredHeight: 30
                Layout.margins: 10
                Layout.fillWidth: true
                // implicitWidth: parent.width
                UI.StyledText {
                    id: title
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: root.modelData.appName
                    font.weight: Font.Bold
                    font.pixelSize: 16
                }
                UI.AppIcon {
                    Layout.alignment: Qt.AlignVCenter

                    implicitWidth: Config.Theme.style.iconSizes.xs
                    implicitHeight: Config.Theme.style.iconSizes.xs
                    onClicked: {
                        root.modelData.remove();
                    }

                    //close icon
                    icon.name: "window-close"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Config.Theme.style.borderWidth
                color: Config.Theme.colors.border
            }

            UI.StyledText {
                id: summary
                Layout.fillWidth: true

                padding: 10
                text: root.modelData.summary
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
            }

            UI.StyledText {
                id: body
                Layout.fillWidth: true
                visible: root.modelData.body.length > 0

                padding: 11
                text: root.modelData.body
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: root.modelData.notification.actions.length ? 40 : 0
                Layout.margins: root.modelData.notification.actions.length ? 10 : 0

                orientation: ListView.Horizontal
                model: ScriptModel {
                    values: root.modelData.notification.actions
                }
                delegate: Button {
                    required property NotificationAction modelData
                    padding: 10
                    text: modelData.text
                    onClicked: modelData.invoke()
                }
            }
        }
    }
}
