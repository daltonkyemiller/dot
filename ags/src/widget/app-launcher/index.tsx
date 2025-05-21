import Apps from "gi://AstalApps";
import { App, Astal, Gdk, Gtk, hook } from "astal/gtk4";
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
      cssClasses={["app-button"]}
      onClicked={() => {
        hide();
        app.launch();
      }}
    >
      <box spacing={10}>
        <image iconName={app.iconName} />
        <box valign={Gtk.Align.CENTER} vertical>
          <label cssClasses={["name"]} xalign={0} label={app.name} />
          {app.description && (
            <label
              maxWidthChars={50}
              cssClasses={["description"]}
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
    <box cssClasses={["search-bar"]} spacing={10}>
      <image iconName="system-search-symbolic" valign={Gtk.Align.BASELINE} />
      <entry
        valign={Gtk.Align.BASELINE}
        onNotifyText={(self) => text.set(self.text)}
        onActivate={onActivate}
        setup={(self) => {
          hook(self, App, "window-toggled", (self, win) => {
            if (win.name !== APP_LAUNCHER_WINDOW_NAME) return;
            self.grab_focus();
            self.set_text("");
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
      keymode={Astal.Keymode.ON_DEMAND}
      setup={(self) => {
        hook(self, App, "window-toggled", (self, win) => {
          if (win.name !== APP_LAUNCHER_WINDOW_NAME) return;
          text.set("");
        });
      }}
    >
      <box widthRequest={500} cssClasses={["app-launcher"]} vertical>
        <Search text={text} onActivate={onEnter} />

        <box
          vertical
          spacing={8}
          visible={list.as((l) => l.length > 0)}
          cssClasses={["app-list"]}
        >
          {list.as((list) => list.map((app) => <AppButton app={app} />))}
        </box>

        <box
          halign={CENTER}
          cssClasses={["not-found"]}
          vertical
          visible={list.as((l) => l.length === 0)}
        >
          <image iconName="system-search-symbolic" />
          <label label="No match found" />
        </box>
      </box>
    </PopupWindow>
  );
}
