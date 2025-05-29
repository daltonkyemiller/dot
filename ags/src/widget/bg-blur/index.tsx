import { Astal, App, Gdk } from "astal/gtk4";
import { BG_BLUR_WINDOW_NAME } from "./consts";
import { cn } from "../../lib/utils";

export default function BgBlur(gdkmonitor: Gdk.Monitor) {
  return (
    <window
      cssClasses={cn("bg-bg/20")}
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
      // widthRequest={gdkmonitor.workarea.width}
      keymode={Astal.Keymode.NONE}
      exclusivity={Astal.Exclusivity.IGNORE}
      application={App}
    />
  );
}
