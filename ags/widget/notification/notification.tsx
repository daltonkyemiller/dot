import { bind, GLib, Variable } from "astal";
import { Gtk, Astal } from "astal/gtk3";
import Notifd from "gi://AstalNotifd";
import { NotificationData } from "./types";

const isIcon = (icon: string) => !!Astal.Icon.lookup_icon(icon);

const fileExists = (path: string) => GLib.file_test(path, GLib.FileTest.EXISTS);

const time = (time: number, format = "%H:%M") =>
  GLib.DateTime.new_from_unix_local(time).format(format)!;

const urgency = (n: Notifd.Notification) => {
  const { LOW, NORMAL, CRITICAL } = Notifd.Urgency;
  // match operator when?
  switch (n.urgency) {
    case LOW:
      return "low";
    case CRITICAL:
      return "critical";
    case NORMAL:
    default:
      return "normal";
  }
};

type Props = {
  notification: Notifd.Notification;
  setup(): void;
  onHoverLost(): void;
};

export default function Notification(props: Props) {
  const { notification, setup, onHoverLost } = props;
  const { START, CENTER, END } = Gtk.Align;
  console.log("RENDERING NOTIFICATION", notification.id);

  return (
    <eventbox
      className={`notification ${urgency(notification)}`}
      setup={setup}
      onHoverLost={onHoverLost}
    >
      <box vertical>
        <box className="header">
          {(notification.appIcon || notification.desktopEntry) && (
            <icon
              className="app-icon"
              visible={Boolean(
                notification.appIcon || notification.desktopEntry,
              )}
              icon={notification.appIcon || notification.desktopEntry}
            />
          )}
          <label
            className="app-name"
            halign={START}
            truncate
            label={notification.appName || "Unknown"}
          />
          <label
            className="time"
            hexpand
            halign={END}
            label={time(notification.time)}
          />
          <button
            onClick={() => {
              return notification.dismiss();
            }}
          >
            <icon icon="window-close-symbolic" />
          </button>
        </box>
        <Gtk.Separator visible />
        <box className="content">
          {notification.image && fileExists(notification.image) && (
            <box
              valign={START}
              className="image"
              css={`
                background-image: url("${notification.image}");
              `}
            />
          )}
          {notification.image && isIcon(notification.image) && (
            <box expand={false} valign={START} className="icon-image">
              <icon
                icon={notification.image}
                expand
                halign={CENTER}
                valign={CENTER}
              />
            </box>
          )}
          <box vertical>
            <label
              className="summary"
              halign={START}
              xalign={0}
              label={notification.summary}
              truncate
            />
            {notification.body && (
              <label
                className="body"
                wrap
                useMarkup
                halign={START}
                xalign={0}
                justifyFill
                label={notification.body}
              />
            )}
          </box>
        </box>
        {notification.get_actions().length > 0 && (
          <box className="actions">
            {notification.get_actions().map(({ label, id }) => (
              <button hexpand onClick={() => notification.invoke(id)}>
                <label label={label} halign={CENTER} hexpand />
              </button>
            ))}
          </box>
        )}
      </box>
    </eventbox>
  );
}
