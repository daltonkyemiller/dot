import { Astal, Gdk, Gtk, hook } from "astal/gtk4";
import Notification from "./notification";
import { bind, timeout, Variable } from "astal";
import AstalNotifd from "gi://AstalNotifd";
import { cn } from "../../lib/utils";

export default function NotificationPopups(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor;
  const notifd = AstalNotifd.get_default();

  const child = Variable<Gtk.Widget | null>(null);

  return (
    <window
      cssClasses={cn("[all:unset]")}
      namespace="dkm_blur_ignorealpha_notifications"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | RIGHT}
      visible={false}
      setup={(self) => {
        const notificationQueue: number[] = [];
        let isProcessing = false;

        hook(self, notifd, "notified", (_, id: number) => {
          if (
            notifd.dont_disturb &&
            notifd.get_notification(id).urgency != AstalNotifd.Urgency.CRITICAL
          ) {
            return;
          }
          notificationQueue.push(id);
          processQueue();
        });

        hook(self, notifd, "resolved", (_, __) => {
          self.visible = false;
          isProcessing = false;
          timeout(300, () => {
            processQueue();
          });
        });

        function processQueue() {
          if (isProcessing || notificationQueue.length === 0) return;
          isProcessing = true;
          const id = notificationQueue.shift();

          child.set(
            <box vertical>
              {Notification({
                notification: notifd.get_notification(id!),
                onHoverLeave() {},
                setup() {},
              })}
              <box vexpand />
            </box>,
          );

          self.visible = true;

          timeout(6000, () => {
            self.visible = false;
            isProcessing = false;
            child.set(null);
            timeout(300, () => {
              processQueue();
            });
          });
        }
      }}
    >
      {bind(child)}
    </window>
  );
}
