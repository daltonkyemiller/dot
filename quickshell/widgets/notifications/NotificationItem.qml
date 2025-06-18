pragma ComponentBehavior: Bound

import Quickshell
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

    implicitHeight: Config.Notification.height
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
        implicitHeight: parent.height
        implicitWidth: parent.width
        radius: Config.Theme.style.radius.md

        color: root.bg
        border.color: Config.Theme.colors.border
        border.width: Config.Theme.style.borderWidth

        ColumnLayout {
            width: parent.width
            height: parent.height
            RowLayout {
                Layout.preferredHeight: 30
                Layout.margins: 10
                implicitWidth: parent.width
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
                        root.modelData.remove()
                    }

                    //close icon
                    icon.name: "window-close"
                }
            }

            UI.StyledText {
                id: summary
                Layout.fillWidth: true
                Layout.fillHeight: true

                padding: 10
                text: root.modelData.summary
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
            }
        }
    }
}
