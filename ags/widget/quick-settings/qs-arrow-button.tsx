import { Binding } from "astal";
import { Gtk } from "astal/gtk3";

export function QSArrowButton({
  iconName,
  title,
  subtitle,
  onClick,
  onArrowClick,
}: {
  iconName: string | Binding<string>;
  title: string;
  subtitle: string | Binding<string>;
  onClick: () => void;
  onArrowClick: () => void;
}) {
  return (
    <box className="qs-button">
      <button onClick={onClick}>
        <box halign={Gtk.Align.START} spacing={6}>
          <icon icon={iconName} className="icon" />
          <box vertical hexpand>
            <label xalign={0} label={title} className="title" />
            <label xalign={0} label={subtitle} className="subtitle" />
          </box>
        </box>
      </button>
      <button onClick={onArrowClick}>
        <box>
          <icon icon="go-next-symbolic" css="font-size: 20px;" />
        </box>
      </button>
    </box>
  );
}
