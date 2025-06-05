import { GLib } from "astal";
import { Gtk, Astal } from "astal/gtk4";
import Notifd from "gi://AstalNotifd";
import { cn, isIcon } from "../../lib/utils";

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
  onHoverLeave(): void;
};

export default function Notification(props: Props) {
  const { notification, setup, onHoverLeave } = props;
  const { START, CENTER, END } = Gtk.Align;

  return (
    <box cssClasses={cn("group")} setup={setup} onHoverLeave={onHoverLeave}>
      <box
        vertical
        cssClasses={cn(
          "min-w-[400px] max-w-[550px] rounded-md bg-bg border my-[0.5rem] mx-[1rem]",
        )}
      >
        <box cssClasses={cn("p-[0.5rem]")}>
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
            halign={START}
            wrap
            label={notification.appName || "Unknown"}
          />
          <label
            hexpand
            halign={END}
            label={time(notification.time)}
          />
          <button
            onClicked={() => {
              return notification.dismiss();
            }}
          >
            <image iconName="window-close-symbolic" />
          </button>
        </box>
        <Gtk.Separator visible />
        <box cssClasses={cn("p-3")} spacing={5}>
          {notification.image && fileExists(notification.image) && (
            <image
              overflow={Gtk.Overflow.HIDDEN}
              pixelSize={50}
              valign={CENTER}
              cssClasses={cn("rounded-md")}
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
              cssClasses={cn("text-lg font-bold")}
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
          <box cssClasses={cn("p-3 pt-0")}>
            {notification.get_actions().map(({ label, id }) => (
              <button
                hexpand
                onClicked={() => notification.invoke(id)}
                cssClasses={cn("border border-border p-2")}
              >
                <label label={label} halign={CENTER} hexpand />
              </button>
            ))}
          </box>
        )}
      </box>
    </box>
  );
}
