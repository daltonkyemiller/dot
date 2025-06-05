import Apps from "gi://AstalApps";
import { App, Astal, Gdk, Gtk, hook } from "astal/gtk4";
import { bind, Binding, exec, Variable } from "astal";
import { APP_LAUNCHER_WINDOW_NAME } from "./consts";
import { BG_BLUR_WINDOW_NAME } from "../bg-blur/consts";
import PopupWindow from "../common/popup-window";
import { bash, bashAsync, cn, debounce, isIcon } from "../../lib/utils";
import {
  QuickResultsManager,
  calculatorPlugin,
  colorConverterPlugin,
  QuickResult,
} from "./quick-results";
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
        "mx-4 rounded-md bg-bg px-4 py-3 text-fg transition-all first:mt-2 last:mb-2 focus:bg-white/10",
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

const entryWidget$ = Variable<Gtk.Entry | null>(null);

const quickResult$ = Variable<QuickResult | null>(null);

const quickResultsManager = new QuickResultsManager();
quickResultsManager.addPlugin(colorConverterPlugin);
quickResultsManager.addPlugin(calculatorPlugin);

function QuickResults(props: { text$: Variable<string> }) {
  const { text$ } = props;
  const unsub = text$.subscribe(async (t) => {
    if (!t.trim()) {
      quickResult$.set(null);
      return;
    }

    const result = await quickResultsManager.processInput(t);
    quickResult$.set(result);
  });

  return (
    <box
      onDestroy={() => unsub()}
      visible={bind(quickResult$).as((r) => !!r)}
      valign={Gtk.Align.CENTER}
      halign={Gtk.Align.END}
    >
      <box cssClasses={cn("[&>label]:text-fg/50")}>
        {bind(quickResult$).as((result) => {
          if (!result) return <label></label>;

          if (typeof result.display === "string") {
            return <label>{result.display}</label>;
          } else {
            return result.display;
          }
        })}
      </box>
    </box>
  );
}

function Search({
  text,
  onActivate,
  showBottomBorder,
}: {
  text: Variable<string>;
  onActivate: () => void;
  showBottomBorder: Binding<boolean>;
}) {
  return (
    <box
      cssClasses={showBottomBorder.as((show) => {
        return cn("border-b border-solid border-border p-[20px]", {
          "border-b-0": !show,
        });
      })}
      spacing={10}
    >
      <image iconName="system-search-symbolic" valign={Gtk.Align.BASELINE} />
      <entry
        cssClasses={cn("[all:unset]")}
        valign={Gtk.Align.BASELINE}
        onNotifyText={debounce(300, (self) => text.set(self.text))}
        onActivate={onActivate}
        hexpand
        setup={(self) => {
          entryWidget$.set(self);

          hook(self, App, "window-toggled", (self, win) => {
            if (win.name !== APP_LAUNCHER_WINDOW_NAME) return;
            self.grab_focus();
            self.set_text("");
          });
        }}
      />
      <QuickResults text$={text} />
    </box>
  );
}

export default function AppLauncher(gdkmonitor: Gdk.Monitor) {
  const { CENTER } = Gtk.Align;
  const apps = new Apps.Apps();
  const text$ = Variable("");

  const list$ = text$((text) => {
    if (!text) return [];
    const filtered = apps.fuzzy_query(text).slice(0, MAX_ITEMS);

    return filtered;
  });

  const onEnter = () => {
    list$.get()[0].launch();
    hide();
  };

  return (
    <PopupWindow
      cssClasses={cn("bg-transparent text-fg [all:unset]")}
      name={APP_LAUNCHER_WINDOW_NAME}
      onClose={hide}
      visible={false}
      layer={Astal.Layer.OVERLAY}
      animation="popin 80%"
      keymode={Astal.Keymode.ON_DEMAND}
      setup={(self) => {
        hook(self, App, "window-toggled", (self, win) => {
          if (win.name !== self.name) return;
          if (win.visible) {
            App.toggle_window(BG_BLUR_WINDOW_NAME);
          }
          text$.set("");
        });
      }}
    >
      <box
        widthRequest={500}
        overflow={Gtk.Overflow.HIDDEN}
        cssClasses={cn(
          "rounded-md border border-solid border-border bg-bg bg-gradient-to-br from-bg from-30% to-fg/10 shadow-[0_0_100px_0_rgb(var(--color-fg)/0.2)]",
        )}
        vertical
        onKeyReleased={async (self, keyval, keycode, state) => {
          if (keyval === Gdk.KEY_c && state === Gdk.ModifierType.CONTROL_MASK) {
            const quickResult = quickResult$.get();
            if (!quickResult) return;
            bash(`wl-copy "${quickResult.clipboardValue}" 2>/dev/null`);
            hide();
          }
        }}
      >
        <Search
          text={text$}
          onActivate={onEnter}
          showBottomBorder={list$.as((l) => !!l.length)}
        />

        <Scrollable
          // visible={list$.as((l) => l.length > 0)}
          cssClasses={list$.as((l) => {
            return cn("transition-all", {
              "opacity-0 min-h-0": !l.length,
              "opacity-100 min-h-[450px]": !!l.length,
            });
          })}
          setup={(self) => {
            self.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.EXTERNAL);
          }}
        >
          <box vertical spacing={8}>
            {list$.as((list) =>
              list.map((app, idx) => <AppButton app={app} idx={idx} />),
            )}
          </box>
        </Scrollable>
      </box>
    </PopupWindow>
  );
}
