import { Gtk } from "astal/gtk4";
import { hide } from "./utils";
import { bash } from "../../lib/utils";
import Pango from "gi://Pango?version=1.0";

interface ClipboardItemProps {
  id: number;
  text: string;
}

export function ClipboardItem({ id, text }: ClipboardItemProps) {
  const onClick = () => {
    bash(`cliphist decode ${id} | wl-copy 2>/dev/null`);
    hide();
  };
  return (
    <button
      cssClasses={["clipboard-item"]}
      onClick={onClick}
      onClicked={onClick}
    >
      <box>
        <label
          label={text}
          halign={Gtk.Align.START}
          wrapMode={Pango.WrapMode.WORD_CHAR}
          maxWidthChars={50}
          wrap
        />
      </box>
    </button>
  );
}
