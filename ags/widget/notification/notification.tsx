import { GLib } from "astal";
import { Gtk, Astal } from "astal/gtk4";
import Notifd from "gi://AstalNotifd";

const isIcon = (icon: string) => {
  const iconTheme = new Gtk.IconTheme();
  return iconTheme.has_icon(icon);
};

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
    <box
      cssClasses={["notification", urgency(notification)]}
      setup={setup}
      onHoverLost={onHoverLost}
    >
      <box vertical>
        <box cssClasses={["header"]}>
          {notification.appIcon || notification.desktopEntry ? (
            <image
              cssClasses={["app-icon"]}
              visible={Boolean(
                notification.appIcon || notification.desktopEntry,
              )}
              iconName={notification.appIcon || notification.desktopEntry}
            />
          ) : null}
          <label
            cssClasses={["app-name"]}
            halign={START}
            wrap
            label={notification.appName || "Unknown"}
          />
          <label
            cssClasses={["time"]}
            hexpand
            halign={END}
            label={time(notification.time)}
          />
          <button
            onClick={() => {
              return notification.dismiss();
            }}
          >
            <image iconName="window-close-symbolic" />
          </button>
        </box>
        <Gtk.Separator visible />
        <box cssClasses={["content"]}>
          {notification.image && fileExists(notification.image) && (
            <image
              valign={START}
              cssClasses={["image"]}
              file={notification.image}
            />
          )}

          {notification.image && isIcon(notification.image) && (
            <box
              hexpand={false}
              vexpand={false}
              valign={START}
              cssClasses={["icon-image"]}
            >
              <image
                iconName={notification.image}
                hexpand
                vexpand
                halign={CENTER}
                valign={CENTER}
              />
            </box>
          )}
          <box vertical>
            <label
              cssClasses={["summary"]}
              halign={START}
              xalign={0}
              label={notification.summary}
              wrap
            />
            {notification.body && (
              <label
                cssClasses={["body"]}
                wrap
                useMarkup
                halign={START}
                xalign={0}
                label={notification.body}
              />
            )}
          </box>
        </box>
        {notification.get_actions().length > 0 && (
          <box cssClasses={["actions"]}>
            {notification.get_actions().map(({ label, id }) => (
              <button hexpand onClick={() => notification.invoke(id)}>
                <label label={label} halign={CENTER} hexpand />
              </button>
            ))}
          </box>
        )}
      </box>
    </box>
  );
}
