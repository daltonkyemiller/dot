import { Gtk } from "astal/gtk3";
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
      className="clipboard-item"
      onClick={onClick}
      onClicked={onClick}
      cursor="pointer"
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
