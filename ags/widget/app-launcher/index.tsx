import Apps from "gi://AstalApps";
import { App, Astal, Gdk, Gtk } from "astal/gtk3";
import { Variable } from "astal";
import { APP_LAUNCHER_WINDOW_NAME } from "./consts";
import { BG_BLUR_WINDOW_NAME } from "../bg-blur/consts";
import PopupWindow from "../common/popup-window";

const MAX_ITEMS = 8;

function hide() {
  App.get_window(BG_BLUR_WINDOW_NAME)!.hide();
  App.get_window(APP_LAUNCHER_WINDOW_NAME)!.hide();
}

function AppButton({ app }: { app: Apps.Application }) {
  return (
    <button
      className="app-button"
      onClicked={() => {
        hide();
        app.launch();
      }}
    >
      <box spacing={10}>
        <icon icon={app.iconName} />
        <box valign={Gtk.Align.CENTER} vertical>
          <label className="name" xalign={0} label={app.name} />
          {app.description && (
            <label
              maxWidthChars={50}
              className="description"
              wrap
              xalign={0}
              label={app.description}
            />
          )}
        </box>
      </box>
    </button>
  );
}

function Search({
  text,
  onActivate,
}: {
  text: Variable<string>;
  onActivate: () => void;
}) {
  return (
    <box className="search-bar" spacing={10}>
      <icon icon="system-search-symbolic" valign={Gtk.Align.BASELINE} />
      <entry
        valign={Gtk.Align.BASELINE}
        placeholderText="Search"
        text={text()}
        onChanged={(self) => text.set(self.text)}
        onActivate={onActivate}
        canFocus
        setup={(self) => {
          self.hook(App, "window-toggled", (self) => {
            self.grab_focus();
          });
        }}
      />
    </box>
  );
}

export default function Applauncher(gdkmonitor: Gdk.Monitor) {
  const { CENTER } = Gtk.Align;
  const apps = new Apps.Apps();
  const text = Variable("");

  const list = text((text) => apps.fuzzy_query(text).slice(0, MAX_ITEMS));
  const onEnter = () => {
    apps.fuzzy_query(text.get())?.[0].launch();
    hide();
  };

  return (
    <PopupWindow
      gdkmonitor={gdkmonitor}
      name={APP_LAUNCHER_WINDOW_NAME}
      onClose={hide}
      visible={false}
      layer={Astal.Layer.OVERLAY}
      animation="popin 80%"
      setup={(self) =>
        self.hook(App, "window-toggled", (self, win) => {
          if (win.name !== APP_LAUNCHER_WINDOW_NAME) return;
          text.set("");
        })
      }
    >
      <box widthRequest={500} className="app-launcher" vertical>
        <Search text={text} onActivate={onEnter} />

        <box
          vertical
          spacing={8}
          visible={list.as((l) => l.length > 0)}
          className="app-list"
        >
          {list.as((list) => list.map((app) => <AppButton app={app} />))}
        </box>

        <box
          halign={CENTER}
          className="not-found"
          vertical
          visible={list.as((l) => l.length === 0)}
        >
          <icon icon="system-search-symbolic" />
          <label label="No match found" />
        </box>
      </box>
    </PopupWindow>
  );
}
