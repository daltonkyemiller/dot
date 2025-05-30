import { exec, Variable } from "astal";
import { App, Astal, Gdk, Gtk, hook } from "astal/gtk4";
import { CLIPBOARD_WINDOW_NAME } from "./consts";
import { BG_BLUR_WINDOW_NAME } from "../bg-blur/consts";
import PopupWindow from "../common/popup-window";
import { ClipboardList } from "./clipboard-list";
import { search } from "./store";
import { cn } from "../../lib/utils";

function hide() {
  search.set("");
  App.get_window(BG_BLUR_WINDOW_NAME)!.hide();
  App.get_window(CLIPBOARD_WINDOW_NAME)!.hide();
}

function Search() {
  return (
    <box spacing={10} cssClasses={cn("p-4")}>
      <image iconName="system-search-symbolic" valign={Gtk.Align.BASELINE} />
      <entry
        cssClasses={cn("[all:unset]")}
        onChanged={(self) => search.set(self.text)}
        valign={Gtk.Align.BASELINE}
        setup={(self) => {
          hook(self, App, "window-toggled", (self, win) => {
            if (win.name !== CLIPBOARD_WINDOW_NAME) return;
            self.grab_focus();
            self.set_text("");
          });
        }}
      />
    </box>
  );
}

export default function Clipboard(gdkmonitor: Gdk.Monitor) {
  const values = Variable<
    {
      id: number;
      text: string;
    }[]
  >([]);
  return (
    <PopupWindow
      gdkmonitor={gdkmonitor}
      name={CLIPBOARD_WINDOW_NAME}
      onClose={hide}
      visible={false}
      layer={Astal.Layer.OVERLAY}
      animation="popin 80%"
      setup={(self) =>
        hook(self, App, "window-toggled", (self, win) => {
          if (win.name !== CLIPBOARD_WINDOW_NAME) return;
          const out = exec("cliphist list -t");
          const split = out.split("\n");
          const items = split.map((v) => {
            const [id, text] = v.split("\t");
            return { id: Number(id), text };
          });
          values.set(items);
        })
      }
    >
      <box
        widthRequest={500}
        cssClasses={cn("rounded-md border border-border bg-bg bg-gradient-to-br from-bg from-30% to-fg/10 shadow-[0_0_100px_0_rgb(var(--color-fg)/0.2)]")}
        overflow={Gtk.Overflow.HIDDEN}
        vertical
      >
        <Search />
        <Gtk.Separator />
        <ClipboardList values={values} />
      </box>
    </PopupWindow>
  );
}
