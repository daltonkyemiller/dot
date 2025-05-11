import { App } from "astal/gtk3";
// import style from "./style/main.scss";
import style from "./output.css";
import AppLauncher from "./widget/app-launcher";
import Bar from "./widget/bar";
import NotificationPopups from "./widget/notification/notification-popup";
import { setupHyprland } from "./lib/hyprland";

App.start({
  css: style,
  requestHandler(request, res) {
    console.log("foo");
  },
  main() {
    App.get_monitors().map(Bar);
    App.get_monitors().map(AppLauncher);
    App.get_monitors().map(NotificationPopups);

    setupHyprland();
  },
});
