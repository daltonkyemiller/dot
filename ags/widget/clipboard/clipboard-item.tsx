import { execAsync } from "astal";
import { Gtk } from "astal/gtk3";
import { hide } from "./utils";

interface ClipboardItemProps {
  id: number;
  text: string;
}

export function ClipboardItem({ id, text }: ClipboardItemProps) {
  return (
    <button
      className="clipboard-item"
      onClicked={async () => {
        hide();
        await execAsync(["wl-copy", `"${text}"`]);
      }}
    >
      <label label={text} halign={Gtk.Align.START} />
    </button>
  );
}

