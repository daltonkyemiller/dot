import { App, Astal, Gdk, Gtk } from "astal/gtk4";
import { GLib, Variable, bind } from "astal";
import Network from "gi://AstalNetwork";
import Battery from "gi://AstalBattery";
import Mpris from "gi://AstalMpris";
import Hyprland from "gi://AstalHyprland";
import { cn, styleToCss, truncate } from "../../lib/utils";
import { ACCENT_COLORS } from "../../lib/theme";
import { changeBrightness } from "../../lib/color";
import QuickSettings from "../quick-settings";

const barSectionClasses = [
  "bg-bg",
  "px-3",
  "py-1",
  "rounded-md",
  "border",
  "border-solid",
  "border-border",
];

function Time({ format = "%I:%M - %A" }) {
  const time = Variable<string>("").poll(
    1000,
    () => GLib.DateTime.new_now_local().format(format)!,
  );

  return <label onDestroy={() => time.drop()} label={time()} />;
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
    <box cssClasses={[...barSectionClasses]} hexpand halign={Gtk.Align.START}>
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
            <button>
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
    <box cssClasses={[...barSectionClasses]}>
      {bind(mpris, "players").as((ps) => {
        const player = ps[0];
        const label = bind(player, "metadata").as(
          () => `${player.title} - ${player.artist}`,
        );

        return player ? (
          <box spacing={10}>
            <image
              file={bind(player, "coverArt")}
              valign={Gtk.Align.CENTER}
              pixelSize={30}
              overflow={Gtk.Overflow.HIDDEN}
              cssClasses={cn("rounded-md")}
            />

            <label
              widthRequest={100}
              tooltipText={label}
              label={label.as((l) => truncate(l, 60, true))}
            />
            <button
              tooltipText="Play/Pause"
              onClicked={() => {
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
      onClicked={() => {
        popoverOpen.set(!popoverOpen.get());
      }}
      cssClasses={[...barSectionClasses]}
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
      visible
      name="status-bar"
      namespace="dkm_blur_ignorealpha_statusbar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={App}
      cssClasses={["bg-transparent", "text-fg"]}
    >
      <centerbox cssClasses={cn("mx-[20px] mb-[3px] mt-[10px]")}>
        <Workspaces />

        <Media />

        <Right />
      </centerbox>
    </window>
  );
}
