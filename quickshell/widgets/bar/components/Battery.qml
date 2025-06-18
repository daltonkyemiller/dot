import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../../../components" as UI
import "../../../config" as Config

Item {
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height

    Row {
        spacing: 2

        UI.AppIcon {
            icon.name: UPower.displayDevice.iconName

            implicitHeight: Config.Theme.style.iconSizes.xs
            implicitWidth: Config.Theme.style.iconSizes.xs
        }

        UI.StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(UPower.displayDevice.percentage * 100) + "%"
        }
    }
}
