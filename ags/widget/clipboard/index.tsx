import { exec, Variable } from "astal";
import { App, Astal, Gdk, Gtk } from "astal/gtk3";
import { CLIPBOARD_WINDOW_NAME } from "./consts";
import { BG_BLUR_WINDOW_NAME } from "../bg-blur/consts";
import PopupWindow from "../common/popup-window";
import { Separator } from "../common/separator";
import { ClipboardList } from "./clipboard-list";
import { search } from "./store";

function hide() {
  search.set("");
  App.get_window(BG_BLUR_WINDOW_NAME)!.hide();
  App.get_window(CLIPBOARD_WINDOW_NAME)!.hide();
}

function Search() {
  return (
    <box spacing={10} className="search">
      <icon icon="system-search-symbolic" valign={Gtk.Align.BASELINE} />
      <entry
        text={search()}
        onChanged={(self) => search.set(self.text)}
        valign={Gtk.Align.BASELINE}
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
        self.hook(App, "window-toggled", (self, win) => {
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
      <box widthRequest={500} className="clipboard-content" vertical>
        <Search />
        <Separator />
        <ClipboardList values={values} />
      </box>
    </PopupWindow>
  );
}
