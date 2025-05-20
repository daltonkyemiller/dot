import { App, Astal, Gdk, Gtk } from "astal/gtk4";
import { GLib, Variable, bind } from "astal";
import Network from "gi://AstalNetwork";
import Battery from "gi://AstalBattery";
import Mpris from "gi://AstalMpris";
import Hyprland from "gi://AstalHyprland";
import { styleToCss, truncate } from "../../lib/utils";
import { ACCENT_COLORS } from "../../lib/theme";
import { changeBrightness } from "../../lib/color";
import QuickSettings from "../quick-settings";

function Time({ format = "%I:%M - %A" }) {
  const time = Variable<string>("").poll(
    1000,
    () => GLib.DateTime.new_now_local().format(format)!,
  );

  return (
    <label cssClasses={["Time"]} onDestroy={() => time.drop()} label={time()} />
  );
}

function BatteryLevel() {
  const bat = Battery.get_default();

  return (
    <box visible={bind(bat, "isPresent")}>
      <image iconName={bind(bat, "batteryIconName")} />
      <label
        label={bind(bat, "percentage").as((p) => `${Math.floor(p * 100)} %`)}
      />
    </box>
  );
}

function Workspaces() {
  const hyprland = Hyprland.get_default();
  const workspacesBinding = bind(hyprland, "workspaces");
  const activeWorkspaceBinding = bind(hyprland, "focusedWorkspace");

  return (
    <box cssClasses={["workspaces"]}>
      {activeWorkspaceBinding.as((w) => {
        let color = ACCENT_COLORS[(w.id - 1) % ACCENT_COLORS.length];

        color = changeBrightness(color, 0.2);

        let displayName: string;
        if (w.name !== String(w.id)) {
          displayName = `${w.name} (${w.id})`;
        } else {
          displayName = w.name;
        }

        return (
          <label
            cssClasses={["workspace"]}
            cssName={styleToCss({
              color,
            })}
          >
            {displayName}
          </label>
        );
      })}
    </box>
  );
}

function Wifi() {
  const network = Network.get_default();
  const wifi = bind(network, "wifi");

  return (
    <box visible={wifi.as(Boolean)}>
      {wifi.as(
        (wifi) =>
          wifi && (
            <button cssClasses={["wifi-button"]}>
              <box>
                <image
                  tooltipText={bind(wifi, "ssid").as(String)}
                  cssClasses={["wifi"]}
                  iconName={bind(wifi, "iconName")}
                  focusOnClick
                />
              </box>
            </button>
          ),
      )}
    </box>
  );
}

function Media() {
  const mpris = Mpris.get_default();

  return (
    <box cssClasses={["media"]}>
      {bind(mpris, "players").as((ps) => {
        const player = ps[0];
        const label = bind(player, "metadata").as(
          () => `${player.title} - ${player.artist}`,
        );

        return player ? (
          <box spacing={10}>
            <image
              file={bind(player, "coverArt")}
              cssClasses={["cover"]}
              valign={Gtk.Align.CENTER}
            />
            <label
              cssClasses={["title"]}
              widthRequest={100}
              tooltipText={label}
              label={label.as((l) => truncate(l, 60, true))}
            />
            <button
              tooltipText="Play/Pause"
              onClick={() => {
                player.play_pause();
              }}
            >
              <image
                iconName={bind(player, "playbackStatus").as((f) => {
                  const isPlaying = f === Mpris.PlaybackStatus.PLAYING;
                  return isPlaying
                    ? "media-playback-pause-symbolic"
                    : "media-playback-start-symbolic";
                })}
              />
            </button>
          </box>
        ) : (
          <label label="Nothing Playing" />
        );
      })}
    </box>
  );
}

function Right() {
  const popoverOpen = Variable(false);

  QuickSettings({ open: popoverOpen });

  return (
    <button
      halign={Gtk.Align.END}
      onClick={() => {
        popoverOpen.set(!popoverOpen.get());
      }}
    >
      <box spacing={10} hexpand halign={Gtk.Align.END}>
        <BatteryLevel />
        <Wifi />
        <Time />
      </box>
    </button>
  );
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor;

  return (
    <window
      name="status-bar"
      namespace="dkm_blur_ignorealpha_statusbar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={App}
    >
      <centerbox>
        <box hexpand halign={Gtk.Align.START} spacing={5}>
          <Workspaces />
        </box>
        <Media />

        <Right />
      </centerbox>
    </window>
  );
}
