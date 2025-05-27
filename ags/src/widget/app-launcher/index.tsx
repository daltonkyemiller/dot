import Apps from "gi://AstalApps";
import { App, Astal, Gdk, Gtk, hook } from "astal/gtk4";
import { Variable } from "astal";
import { APP_LAUNCHER_WINDOW_NAME } from "./consts";
import { BG_BLUR_WINDOW_NAME } from "../bg-blur/consts";
import PopupWindow from "../common/popup-window";
import { cn, isIcon } from "../../lib/utils";
import { Scrollable } from "../common/scrollable";

const MAX_ITEMS = 8;

function hide() {
  App.get_window(BG_BLUR_WINDOW_NAME)!.hide();
  App.get_window(APP_LAUNCHER_WINDOW_NAME)!.hide();
}

function AppButton({ app, idx }: { idx: number; app: Apps.Application }) {
  const imageProps = isIcon(app.iconName)
    ? { iconName: app.iconName }
    : { file: app.iconName };

  return (
    <button
      cssClasses={cn(
        "mx-[10px] bg-bg px-[15px] py-[10px] text-fg transition-all first:mt-[8px] last:mb-[8px] focus:bg-black/30",
      )}
      onClicked={() => {
        hide();
        app.launch();
      }}
    >
      <box spacing={15}>
        <image {...imageProps} iconSize={Gtk.IconSize.LARGE} />
        <box valign={Gtk.Align.CENTER} vertical>
          <label cssClasses={["name"]} xalign={0} label={app.name} />
          {app.description && (
            <label
              maxWidthChars={50}
              cssClasses={cn("text-fg/50")}
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

const entryWidget = Variable<Gtk.Entry | null>(null);

function Search({
  text,
  onActivate,
}: {
  text: Variable<string>;
  onActivate: () => void;
}) {
  return (
    <box
      cssClasses={cn("border-b border-solid border-border p-[20px]")}
      spacing={10}
    >
      <image iconName="system-search-symbolic" valign={Gtk.Align.BASELINE} />
      <entry
        cssClasses={cn("[all:unset]")}
        valign={Gtk.Align.BASELINE}
        onNotifyText={(self) => text.set(self.text)}
        onActivate={onActivate}
        setup={(self) => {
          entryWidget.set(self);

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

export default function AppLauncher(gdkmonitor: Gdk.Monitor) {
  const { CENTER } = Gtk.Align;
  const apps = new Apps.Apps();
  const text = Variable("");

  const list = text((text) => {
    const filtered = apps.fuzzy_query(text).slice(0, MAX_ITEMS);

    return filtered;
  });
  const onEnter = () => {
    list.get()[0].launch();
    hide();
  };

  return (
    <PopupWindow
      cssClasses={cn("bg-transparent text-fg [all:unset]")}
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
      <box
        widthRequest={500}
        overflow={Gtk.Overflow.HIDDEN}
        cssClasses={cn(
          "rounded-md bg-bg bg-gradient-to-br from-bg to-fg/10 border border-solid border-border shadow-[0_0_10px_0_var(--tw-)]",
        )}
        vertical
      >
        <Search text={text} onActivate={onEnter} />

        <Scrollable visible={list.as((l) => l.length > 0)} heightRequest={500}>
          <box vertical spacing={8}>
            {list.as((list) =>
              list.map((app, idx) => <AppButton app={app} idx={idx} />),
            )}
          </box>
        </Scrollable>

        <box
          halign={CENTER}
          cssClasses={cn("p-4")}
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
