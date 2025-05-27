import { Gtk } from "astal/gtk4";
import Wp from "gi://AstalWp";
import { Variable } from "astal";

const audio = Wp.get_default()?.audio;

export const VolumeIndicator = () => {
  // Convert from 0-1 range to 0-100 for the progress bar
  const value = Variable(
    audio?.defaultSpeaker?.volume ? audio.defaultSpeaker.volume * 100 : 0,
  );
  const iconName = Variable("speaker-symbolic");

  const updateIcon = (volumePercent: number, muted: boolean = false) => {
    if (muted || volumePercent === 0) {
      iconName.set("audio-volume-muted-symbolic");
    } else if (volumePercent < 33) {
      iconName.set("audio-volume-low-symbolic");
    } else if (volumePercent < 66) {
      iconName.set("audio-volume-medium-symbolic");
    } else {
      iconName.set("audio-volume-high-symbolic");
    }
  };

  if (audio?.defaultSpeaker) {
    // Initial icon update
    const initialVolume = Math.round(audio.defaultSpeaker.volume * 100);
    updateIcon(initialVolume, audio.defaultSpeaker.mute || false);

    // Connect to the specific speaker's notify signal for volume changes
    audio.defaultSpeaker.connect("notify::volume", (speaker: Wp.Endpoint) => {
      const volumePercent = Math.round(speaker.volume * 100);
      print("Volume changed:", volumePercent + "%");
      value.set(volumePercent);
      updateIcon(volumePercent, speaker.mute || false);
    });

    // Listen for mute changes
    audio.defaultSpeaker.connect("notify::mute", (speaker: Wp.Endpoint) => {
      const volumePercent = Math.round(speaker.volume * 100);
      updateIcon(volumePercent, speaker.mute || false);
    });

    // Also listen for default speaker changes
    audio.connect("notify::default-speaker", () => {
      if (audio.defaultSpeaker) {
        const volumePercent = Math.round(audio.defaultSpeaker.volume * 100);
        value.set(volumePercent);
        updateIcon(volumePercent, audio.defaultSpeaker.mute || false);

        // Re-connect to the new speaker's volume changes
        audio.defaultSpeaker.connect(
          "notify::volume",
          (speaker: Wp.Endpoint) => {
            const volumePercent = Math.round(speaker.volume * 100);
            print("Volume changed:", volumePercent + "%");
            value.set(volumePercent);
            updateIcon(volumePercent, speaker.mute || false);
          },
        );

        audio.defaultSpeaker.connect("notify::mute", (speaker: Wp.Endpoint) => {
          const volumePercent = Math.round(speaker.volume * 100);
          updateIcon(volumePercent, speaker.mute || false);
        });
      }
    });
  }

  return (
    <window
      setup={(self) => {
        value.subscribe((v) => {
          if (v > 0) {
            self.set_visible(true);
            setTimeout(() => {
              self.set_visible(false);
            }, 1000);
          }
        });
      }}
    >
      <box spacing={8}>
        <box>
          <image icon-name={iconName} />
        </box>
        <box>
          <Gtk.LevelBar />
        </box>
      </box>
    </window>
  );
};
