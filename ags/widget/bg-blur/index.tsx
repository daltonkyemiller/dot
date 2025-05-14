import { Astal, App, Gdk } from "astal/gtk3";
import { BG_BLUR_WINDOW_NAME } from "./consts";

export default function BgBlur(gdkmonitor: Gdk.Monitor) {
  return (
    <window
      visible={false}
      decorated
      name={BG_BLUR_WINDOW_NAME}
      namespace="dkm_blur"
      anchor={
        Astal.WindowAnchor.TOP |
        Astal.WindowAnchor.BOTTOM |
        Astal.WindowAnchor.LEFT |
        Astal.WindowAnchor.RIGHT
      }
      widthRequest={gdkmonitor.workarea.width}
      keymode={Astal.Keymode.NONE}
      exclusivity={Astal.Exclusivity.IGNORE}
      application={App}
    />
  );
}
