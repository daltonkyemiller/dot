import { Astal, Gtk, Gdk } from "astal/gtk3";
import Notifd from "gi://AstalNotifd";
import Notification from "./notification";
import { type Subscribable } from "astal/binding";
import { Variable, bind, timeout } from "astal";

// see comment below in constructor
const TIMEOUT_DELAY = 5000;

// The purpose if this class is to replace Variable<Array<Widget>>
// with a Map<number, Widget> type in order to track notification widgets
// by their id, while making it conviniently bindable as an array
class NotifiationMap implements Subscribable {
  // the underlying map to keep track of id widget pairs
  private map: Map<number, Gtk.Widget> = new Map();

  // it makes sense to use a Variable under the hood and use its
  // reactivity implementation instead of keeping track of subscribers ourselves
  private var: Variable<Array<Gtk.Widget>> = Variable([]);

  // notify subscribers to rerender when state changes
  private notify() {
    this.var.set([...this.map.values()].reverse());
  }

  private notifd = Notifd.get_default();

  constructor() {
    // this.notifd.ignoreTimeout = true;

    this.notifd.connect("notified", (_, id) => {
      this.set(
        id,
        Notification({
          notification: this.notifd.get_notification(id)!,

          onHoverLost: () =>
            this.delete(id, Notifd.ClosedReason.DISMISSED_BY_USER),

          setup: () =>
            timeout(TIMEOUT_DELAY, () => {
              this.delete(id, Notifd.ClosedReason.EXPIRED);
            }),
        }),
      );
    });

    this.notifd.connect("resolved", (_, id) => {
      this.delete(id);
    });
  }

  private set(key: number, value: Gtk.Widget) {
    // in case of replacecment destroy previous widget
    this.map.get(key)?.destroy();
    this.map.set(key, value);
    this.notify();
  }

  private delete(key: number, reason?: Notifd.ClosedReason) {
    if (reason) {
      this.notifd.emit("resolved", key, Notifd.ClosedReason.DISMISSED_BY_USER);
    }
    this.map.get(key)?.destroy();
    this.map.delete(key);
    this.notify();
  }

  // needed by the Subscribable interface
  get() {
    return this.var.get();
  }

  // needed by the Subscribable interface
  subscribe(callback: (list: Array<Gtk.Widget>) => void) {
    return this.var.subscribe(callback);
  }
}

export default function NotificationPopups(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor;
  const notifs = new NotifiationMap();

  return (
    <window
      className="notification-popups"
      namespace="dkm_blur_ignorealpha_notifications"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | RIGHT}
    >
      <box vertical>{bind(notifs)}</box>
    </window>
  );
}
