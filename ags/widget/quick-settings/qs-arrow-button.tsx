import { Binding } from "astal";
import { Gtk } from "astal/gtk4";

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
    <box cssClasses={["qs-button"]}>
      <button onClick={onClick}>
        <box halign={Gtk.Align.START} spacing={6}>
          <image iconName={iconName} cssClasses={["icon"]} />
          <box vertical hexpand>
            <label xalign={0} label={title} cssClasses={["title"]} />
            <label xalign={0} label={subtitle} cssClasses={["subtitle"]} />
          </box>
        </box>
      </button>
      <button onClick={onArrowClick}>
        <box>
          <image iconName="go-next-symbolic" />
        </box>
      </button>
    </box>
  );
}
