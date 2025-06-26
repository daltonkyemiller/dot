pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property var mainPlayer: Mpris.players.values.find(p => p.isPlaying) || Mpris.players.values[0]

    property string title: {
        if (!mainPlayer)
            return "";

        if (!mainPlayer.trackTitle && !mainPlayer.trackArtist) {
            return "";
        }

        if (mainPlayer.trackTitle && !mainPlayer.trackArtist) {
            return mainPlayer.trackTitle;
        }

        return mainPlayer.trackTitle + " - " + mainPlayer.trackArtist;
    }
}
