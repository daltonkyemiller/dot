import { App } from "astal/gtk3";
import { search } from "./store";
import { CLIPBOARD_WINDOW_NAME } from "./consts";
import { BG_BLUR_WINDOW_NAME } from "../bg-blur/consts";

export function hide() {
  search.set("");
  App.get_window(BG_BLUR_WINDOW_NAME)!.hide();
  App.get_window(CLIPBOARD_WINDOW_NAME)!.hide();
}
