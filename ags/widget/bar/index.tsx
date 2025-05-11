import { App, Astal, Gdk, Gtk } from "astal/gtk3";
import { GLib, Variable, bind } from "astal";
import Network from "gi://AstalNetwork";
import Battery from "gi://AstalBattery";
import Mpris from "gi://AstalMpris";
import Hyprland from "gi://AstalHyprland";
import { styleToCss, truncate } from "../../lib/utils";
import { ACCENT_COLORS } from "../../lib/theme";
import { changeBrightness } from "../../lib/color";


function Time({ format = "%I:%M - %A" }) {
  const time = Variable<string>("").poll(
    1000,
    () => GLib.DateTime.new_now_local().format(format)!,
  );

  return (
    <label className="Time" onDestroy={() => time.drop()} label={time()} />
  );
}

function BatteryLevel() {
  const bat = Battery.get_default();

  return (
    <box visible={bind(bat, "isPresent")}>
      <icon icon={bind(bat, "batteryIconName")} />
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
    <box className="workspaces">
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
            className="workspace"
            css={styleToCss({
              color,
              // border: `1px solid ${color}`,
              // color,
            })}
          >
            {displayName}
          </label>
        );
      })}
      {/* {workspacesBinding.as((workspaces) => { */}
      {/*   return workspaces.map((workspace, i) => { */}
      {/*     return <label>{workspace.name}</label>; */}
      {/*   }); */}
      {/* })} */}
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
            <button className="wifi-button">
              <icon
                tooltipText={bind(wifi, "ssid").as(String)}
                className="wifi"
                icon={bind(wifi, "iconName")}
                focusOnClick
              />
            </button>
          ),
      )}
    </box>
  );
}

function Media() {
  const mpris = Mpris.get_default();

  return (
    <box className="media">
      {bind(mpris, "players").as((ps) => {
        const player = ps[0];
        const label = bind(player, "metadata").as(
          () => `${player.title} - ${player.artist}`,
        );

        return player ? (
          <box spacing={10}>
            <box
              className="cover"
              valign={Gtk.Align.CENTER}
              css={bind(player, "coverArt").as(
                (cover) => `background-image: url('${cover}');`,
              )}
            />
            <label
              className="title"
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
              <icon
                icon={bind(player, "playbackStatus").as((f) => {
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

        <box spacing={10} hexpand halign={Gtk.Align.END}>
          <BatteryLevel />
          <Wifi />
          <Time />
        </box>
      </centerbox>
    </window>
  );
}
