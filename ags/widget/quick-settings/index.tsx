import { bind, Variable } from "astal";
import PopupWindow, { PopupLayout } from "../common/popup-window";
import { Gtk } from "astal/gtk3";
import Network from "gi://AstalNetwork";
import Bluetooth from "gi://AstalBluetooth";
import { Separator } from "../common/separator";
import { QSArrowButton } from "./qs-arrow-button";

const network = Network.get_default();

enum QuickSettingsPage {
  MAIN = "Quick Settings",
  WIFI = "Wi-Fi",
  BLUETOOTH = "Bluetooth",
  TEST = "Test",
}

const visible = Variable<QuickSettingsPage>(QuickSettingsPage.MAIN);

function Header() {
  const options = Object.values(QuickSettingsPage);
  return (
    <box className="header">
      <stack
        visibleChildName={bind(visible)}
        transitionType={Gtk.StackTransitionType.CROSSFADE}
      >
        {options.map((p) => {
          return (
            <label name={p} halign={Gtk.Align.START}>
              {p}
            </label>
          );
        })}
      </stack>
    </box>
  );
}

function WifiButton() {
  const wifi = network.wifi;
  const wifiIconName = bind(wifi, "iconName");
  const wifiSsid = bind(wifi, "ssid");

  return (
    <QSArrowButton
      iconName={bind(wifiIconName)}
      title="Wi-Fi"
      subtitle={wifiSsid}
      onClick={() => {
        wifi.scan();
      }}
      onArrowClick={() => {
        visible.set(QuickSettingsPage.WIFI);
      }}
    />
  );
}

function BluetoothButton() {
  const bluetooth = Bluetooth.get_default();

  return (
    <QSArrowButton
      iconName={"bluetooth-symbolic"}
      title="Bluetooth"
      subtitle="Scan"
      onClick={() => {}}
      onArrowClick={() => {
        visible.set(QuickSettingsPage.BLUETOOTH);
      }}
    />
  );
}

function MainPage() {
  return (
    <box name={QuickSettingsPage.MAIN} spacing={6}>
      <WifiButton />
      <BluetoothButton />
    </box>
  );
}

function WifiPage() {
  const wifi = bind(network, "wifi");

  return (
    <box vertical spacing={6} name={QuickSettingsPage.WIFI}>
      {wifi.as((wifi) => {
        const accessPoints = bind(wifi, "accessPoints");

        return (
          <>
            <box hexpand={false} spacing={6}>
              <button
                onClick={() => {
                  visible.set(QuickSettingsPage.MAIN);
                }}
              >
                <box>
                  <icon icon="go-previous-symbolic" />
                </box>
              </button>
            </box>
            <scrollable vexpand={false}>
              <box vertical spacing={6}>
                {accessPoints.as((aps) => {
                  const seenSsids = new Set<string>();

                  return aps
                    .filter((ap) => {
                      if (seenSsids.has(ap.ssid)) {
                        return false;
                      }
                      seenSsids.add(ap.ssid);
                      return !!ap.ssid;
                    })
                    .sort((a, b) => -a.strength - -b.strength)
                    .map((ap) => {
                      return <label halign={Gtk.Align.START}>{ap.ssid}</label>;
                    });
                })}
              </box>
            </scrollable>
          </>
        );
      })}
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
      <box vertical className="quick-settings-container">
        <Header />

        <Separator />
        <box className="quick-settings-content">
          <stack
            visibleChildName={bind(visible)}
            transitionType={Gtk.StackTransitionType.SLIDE_LEFT_RIGHT}
            widthRequest={300}
          >
            <MainPage />
            <WifiPage />
          </stack>
        </box>
      </box>
    </PopupWindow>
  );
}
