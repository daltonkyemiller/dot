import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris as MpriService
import Quickshell.Widgets
import "../../../config" as Config
import "../../../components" as UI
import "../../../services" as Services

Row {
    id: root
    spacing: 10

    required property PanelWindow window

    ClippingRectangle {
        width: 25
        height: 25
        radius: Config.Theme.style.radius.sm
        anchors.verticalCenter: parent.verticalCenter
        visible: !!Services.Media.title && Services.Media.mainPlayer?.trackArtUrl
        Image {
            id: art
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: Services.Media.mainPlayer?.trackArtUrl || ""
        }
    }

    UI.StyledText {
        id: title
        width: Math.min(title.implicitWidth, 400)
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: Services.Media.title || "Nothing playing"
    }

    UI.AppIcon {
        visible: !!Services.Media.title
        anchors.verticalCenter: parent.verticalCenter
        icon.name: Services.Media.mainPlayer?.isPlaying ? "media-playback-pause" : "media-playback-start"
        onClicked: Services.Media.mainPlayer.togglePlaying()
    }
}
