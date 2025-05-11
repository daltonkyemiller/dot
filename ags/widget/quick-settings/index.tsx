import { bind, Variable } from "astal";
import PopupWindow, { PopupLayout } from "../common/popup-window";
import { Gtk } from "astal/gtk3";
import Network from "gi://AstalNetwork";
import { styleToCss } from "../../lib/utils";

const network = Network.get_default();

enum QuickSettingsPage {
  MAIN = "main",
  WIFI = "wifi",
  TEST = "test",
}

const visible = Variable<QuickSettingsPage>(QuickSettingsPage.MAIN);

function WifiButton() {
  const wifi = bind(network, "wifi");
  return (
    <button
      className="qs-button"
      onClick={() => visible.set(QuickSettingsPage.WIFI)}
    >
      {wifi.as((wifi) => {
        return (
          <box spacing={10}>
            <icon
              icon={bind(wifi, "iconName")}
              css={styleToCss({
                fontSize: "40px",
              })}
            />

            <box vertical>
              <label>Wi-Fi</label>
              {bind(wifi, "ssid")}
            </box>
          </box>
        );
      })}
    </button>
  );
}

function MainPage() {
  return (
    <box name={QuickSettingsPage.MAIN}>
      <WifiButton />
    </box>
  );
}

function WifiPage() {
  return (
    <box name={QuickSettingsPage.WIFI}>
      <button onClick={() => visible.set(QuickSettingsPage.MAIN)}>back</button>
    </box>
  );
}

type QuickSettingsProps = {
  open: Variable<boolean>;
};

export default function QuickSettings(props: QuickSettingsProps) {
  const { open } = props;
  return (
    <PopupWindow
      name="quick-settings"
      namespace="dkm_blur_ignorealpha_quick-settings"
      visible={bind(open)}
      animation="slide top"
      layout={PopupLayout.TOP_RIGHT}
    >
      <stack
        className="quick-settings-content"
        visibleChildName={bind(visible)}
        transitionType={Gtk.StackTransitionType.SLIDE_LEFT_RIGHT}
        widthRequest={500}
      >
        <MainPage />
        <WifiPage />
      </stack>
    </PopupWindow>
  );
}
