import { App } from "astal/gtk3";
import style from "./style/main.scss";
import Bar from "./widget/bar";
import AppLauncher from "./widget/app-launcher";
import NotificationPopups from "./widget/notification/notification-popup";

App.start({
  css: style,
  requestHandler(request, res) {
    console.log("foo");
  },
  main() {
    App.get_monitors().map(Bar);
    App.get_monitors().map(AppLauncher);
    App.get_monitors().map(NotificationPopups);
  },
});
