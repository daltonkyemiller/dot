import { App } from "astal/gtk3";
import style from "./style/main.scss";
import AppLauncher from "./widget/app-launcher";
import Bar from "./widget/bar";
import NotificationPopups from "./widget/notification/notification-popup";
import { setupHyprland } from "./lib/hyprland";
import BgBlur from "./widget/bg-blur";
import Clipboard from "./widget/clipboard";

App.start({
  css: style,
  requestHandler(request, res) {
    console.log("foo");
  },
  main() {
    App.get_monitors().map(Bar);
    App.get_monitors().map(AppLauncher);
    App.get_monitors().map(NotificationPopups);
    App.get_monitors().map(Clipboard);
    App.get_monitors().map(BgBlur);

    setupHyprland();
  },
});
