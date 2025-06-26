import QtQuick
import QtQuick.Controls
import "../config" as Config

Item {
    id: root
    implicitHeight: Config.Theme.style.iconSizes.md
    implicitWidth: Config.Theme.style.iconSizes.md
    property alias icon: btn.icon
    property alias pressed: btn.pressed
    signal clicked

    Button {
        id: btn
        anchors.centerIn: parent
        background: Item {}
        icon.width: parent.width
        icon.height: parent.height
        icon.color: Config.Theme.colors.fg
        onClicked: root.clicked()
    }
}
