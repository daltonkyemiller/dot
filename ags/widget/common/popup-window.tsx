import { App, Astal, Gdk, Gtk } from "astal/gtk3";
import { WindowProps } from "astal/gtk3/widget";

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
function Padding({ onClick }: { onClick: () => void }) {
  return <button canFocus={false} onClick={onClick} hexpand vexpand />;
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
          <Padding onClick={onClose} />
        </box>
      );
    case "top_center":
      return (
        <box>
          <Padding onClick={onClose} />
          <box vertical hexpand={false}>
            {child}
            <Padding onClick={onClose} />
          </box>
          <Padding onClick={onClose} />
        </box>
      );
    case "top_left":
      return (
        <box>
          <box vertical hexpand={false}>
            {child}
            <Padding onClick={onClose} />
          </box>
          <Padding onClick={onClose} />
        </box>
      );
    case "top_right":
      return (
        <box>
          <Padding onClick={onClose} />
          <box vertical hexpand={false}>
            {child}
            <Padding onClick={onClose} />
          </box>
        </box>
      );
    case "bottom":
      return (
        <box vertical>
          <Padding onClick={onClose} />
          {child}
        </box>
      );
    case "bottom_center":
      return (
        <box>
          <Padding onClick={onClose} />
          <box vertical hexpand={false}>
            <Padding onClick={onClose} />
            {child}
          </box>
          <Padding onClick={onClose} />
        </box>
      );
    case "bottom_left":
      return (
        <box>
          <box vertical hexpand={false}>
            <Padding onClick={onClose} />
            {child}
          </box>
          <Padding onClick={onClose} />
        </box>
      );
    case "bottom_right":
      return (
        <box>
          <Padding onClick={onClose} />
          <box vertical hexpand={false}>
            <Padding onClick={onClose} />
            {child}
          </box>
        </box>
      );
    //default to center
    default:
      return (
        <centerbox>
          <Padding onClick={onClose} />
          <centerbox orientation={Gtk.Orientation.VERTICAL}>
            <Padding onClick={onClose} />
            {child}
            <Padding onClick={onClose} />
          </centerbox>
          <Padding onClick={onClose} />
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
  ...props
}: PopupWindowProps) {
  const { TOP, RIGHT, BOTTOM, LEFT } = Astal.WindowAnchor;
  onClose = onClose || (() => App.toggle_window(name));

  return (
    <window
      css="background-color: transparent;"
      visible={visible}
      name={name}
      namespace={name}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.EXCLUSIVE}
      application={App}
      anchor={TOP | BOTTOM | RIGHT | LEFT}
      onKeyPressEvent={(_, event) => {
        const [, keyval] = event.get_keyval();
        if (keyval === Gdk.KEY_Escape) {
          onClose();
        }
      }}
      {...props}
    >
      <Layout name={name} position={layout} onClose={onClose}>
        {child}
      </Layout>
    </window>
  );
}
