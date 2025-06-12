import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris as MpriService
import Quickshell.Widgets
import "../../../config" as Config
import "../../../components" as UI

Row {
    id: root
    spacing: 10

    property MpriService.MprisPlayer mainPlayer: MpriService.Mpris.players.values[0]

    ClippingRectangle {
        width: 25
        height: 25
        radius: Config.Theme.style.radius.sm
        anchors.verticalCenter: parent.verticalCenter
        Image {
            id: art
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: root.mainPlayer.trackArtUrl
        }
    }

    UI.StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: root.mainPlayer.trackArtist + " - " + root.mainPlayer.trackTitle
    }

    UI.AppIcon {
        anchors.verticalCenter: parent.verticalCenter
        icon.name: root.mainPlayer.isPlaying ? "media-playback-pause" : "media-playback-start"
        onClicked: root.mainPlayer.togglePlaying()
    }
}
