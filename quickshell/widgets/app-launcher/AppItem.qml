import QtQuick
import Quickshell
import "../../components" as UI
import QtQuick.Controls

Item {
    id: root
    required property DesktopEntry modelData
    required property int index
    required property bool selected
    property alias button: button

    implicitWidth: parent.width
    implicitHeight: 50
    clip: true

    property alias row: row

    Button {
        id: button
        implicitWidth: parent.width
        implicitHeight: parent.height
        flat: true
        highlighted: root.selected
        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            x: 20
            transformOrigin: Item.Left
            Image {
                width: 30
                height: 30
                anchors.verticalCenter: parent.verticalCenter
                source: {
                    if (root.modelData.icon.startsWith("file://")) {
                        return root.modelData.icon;
                    }
                    return Quickshell.iconPath(root.modelData.icon);
                }
            }
            UI.StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.modelData.name
            }
        }
    }
}
