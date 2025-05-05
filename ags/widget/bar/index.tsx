import { App, Astal, Gdk, Gtk } from "astal/gtk3";
import { GLib, Variable, bind, timeout } from "astal";
import Network from "gi://AstalNetwork";
import Battery from "gi://AstalBattery";
import Mpris from "gi://AstalMpris";

function Time({ format = "%H:%M - %A" }) {
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
    <box className="Media">
      {bind(mpris, "players").as((ps) =>
        ps[0] ? (
          <box>
            <box
              className="Cover"
              valign={Gtk.Align.CENTER}
              css={bind(ps[0], "coverArt").as(
                (cover) => `background-image: url('${cover}');`,
              )}
            />
            <label
              label={bind(ps[0], "metadata").as(
                () => `${ps[0].title} - ${ps[0].artist}`,
              )}
            />
          </box>
        ) : (
          <label label="Nothing Playing" />
        ),
      )}
    </box>
  );
}
export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor;

  return (
    <window
      name="statusbar"
      className="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={App}
    >
      <centerbox>
        <box hexpand halign={Gtk.Align.START}>
          <Media />
        </box>
        <box />

        <box spacing={10} hexpand halign={Gtk.Align.END}>
          <BatteryLevel />
          <Wifi />
          <Time />
        </box>
      </centerbox>
    </window>
  );
}
