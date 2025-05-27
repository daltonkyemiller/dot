import { App, Astal, Gdk, Gtk } from "astal/gtk4";
import { WindowProps } from "astal/gtk4/widget";

export enum PopupLayout {
  CENTER = "center",
  TOP = "top",
  TOP_CENTER = "top_center",
  TOP_LEFT = "top_left",
  TOP_RIGHT = "top_right",
  BOTTOM = "bottom",
  BOTTOM_CENTER = "bottom_center",
  BOTTOM_LEFT = "bottom_left",
  BOTTOM_RIGHT = "bottom_right",
}
function Padding({ onClicked }: { onClicked: () => void }) {
  return <button canFocus={false} onClicked={onClicked} hexpand vexpand />;
}

function Layout({
  child,
  position,
  onClose,
}: {
  position: PopupLayout;
  onClose: () => void;
  child?: JSX.Element;
}) {
  switch (position) {
    case "top":
      return (
        <box vertical>
          {child}
          <Padding onClicked={onClose} />
        </box>
      );
    case "top_center":
      return (
        <box>
          <Padding onClicked={onClose} />
          <box vertical hexpand={false}>
            {child}
            <Padding onClicked={onClose} />
          </box>
          <Padding onClicked={onClose} />
        </box>
      );
    case "top_left":
      return (
        <box>
          <box vertical hexpand={false}>
            {child}
            <Padding onClicked={onClose} />
          </box>
          <Padding onClicked={onClose} />
        </box>
      );
    case "top_right":
      return (
        <box>
          <Padding onClicked={onClose} />
          <box vertical hexpand={false}>
            {child}
            <Padding onClicked={onClose} />
          </box>
        </box>
      );
    case "bottom":
      return (
        <box vertical>
          <Padding onClicked={onClose} />
          {child}
        </box>
      );
    case "bottom_center":
      return (
        <box>
          <Padding onClicked={onClose} />
          <box vertical hexpand={false}>
            <Padding onClicked={onClose} />
            {child}
          </box>
          <Padding onClicked={onClose} />
        </box>
      );
    case "bottom_left":
      return (
        <box>
          <box vertical hexpand={false}>
            <Padding onClicked={onClose} />
            {child}
          </box>
          <Padding onClicked={onClose} />
        </box>
      );
    case "bottom_right":
      return (
        <box>
          <Padding onClicked={onClose} />
          <box vertical hexpand={false}>
            <Padding onClicked={onClose} />
            {child}
          </box>
        </box>
      );
    //default to center
    default:
      return (
        <centerbox>
          <Padding onClicked={onClose} />
          <centerbox orientation={Gtk.Orientation.VERTICAL}>
            <Padding onClicked={onClose} />
            {child}
            <Padding onClicked={onClose} />
          </centerbox>
          <Padding onClicked={onClose} />
        </centerbox>
      );
  }
}

type PopupWindowProps = WindowProps & {
  child?: unknown;
  name: string;
  animation?: string;
  layout?: PopupLayout;
  onClose?: () => void;
};

export default function PopupWindow({
  child,
  name,
  visible,
  layout = PopupLayout.CENTER,
  onClose,
  onKeyPressed,
  ...props
}: PopupWindowProps) {
  const { TOP, RIGHT, BOTTOM, LEFT } = Astal.WindowAnchor;
  onClose = onClose || (() => App.toggle_window(name));

  return (
    <window
      cssClasses={["bg-transparent"]}
      visible={visible}
      name={name}
      namespace={name}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={App}
      anchor={TOP | BOTTOM | RIGHT | LEFT}
      onKeyPressed={(...args) => {
        const [, keyval] = args;
        if (keyval === Gdk.KEY_Escape) {
          onClose();
        }
        if (onKeyPressed) {
          onKeyPressed(...args);
        }
      }}
      {...props}
    >
      <Layout position={layout} onClose={onClose}>
        {child}
      </Layout>
    </window>
  );
}
