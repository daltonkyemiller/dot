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
function Padding({ winName }: { winName: string }) {
  return (
    <button
      canFocus={false}
      onClick={() => App.toggle_window(winName)}
      hexpand
      vexpand
    />
  );
}

function Layout({
  child,
  name,
  position,
}: {
  child?: JSX.Element;
  name: string;
  position: PopupLayout;
}) {
  switch (position) {
    case "top":
      return (
        <box vertical>
          {child}
          <Padding winName={name} />
        </box>
      );
    case "top_center":
      return (
        <box>
          <Padding winName={name} />
          <box vertical hexpand={false}>
            {child}
            <Padding winName={name} />
          </box>
          <Padding winName={name} />
        </box>
      );
    case "top_left":
      return (
        <box>
          <box vertical hexpand={false}>
            {child}
            <Padding winName={name} />
          </box>
          <Padding winName={name} />
        </box>
      );
    case "top_right":
      return (
        <box>
          <Padding winName={name} />
          <box vertical hexpand={false}>
            {child}
            <Padding winName={name} />
          </box>
        </box>
      );
    case "bottom":
      return (
        <box vertical>
          <Padding winName={name} />
          {child}
        </box>
      );
    case "bottom_center":
      return (
        <box>
          <Padding winName={name} />
          <box vertical hexpand={false}>
            <Padding winName={name} />
            {child}
          </box>
          <Padding winName={name} />
        </box>
      );
    case "bottom_left":
      return (
        <box>
          <box vertical hexpand={false}>
            <Padding winName={name} />
            {child}
          </box>
          <Padding winName={name} />
        </box>
      );
    case "bottom_right":
      return (
        <box>
          <Padding winName={name} />
          <box vertical hexpand={false}>
            <Padding winName={name} />
            {child}
          </box>
        </box>
      );
    //default to center
    default:
      return (
        <centerbox>
          <Padding winName={name} />
          <centerbox orientation={Gtk.Orientation.VERTICAL}>
            <Padding winName={name} />
            {child}
            <Padding winName={name} />
          </centerbox>
          <Padding winName={name} />
        </centerbox>
      );
  }
}

type PopupWindowProps = WindowProps & {
  child?: unknown;
  name: string;
  animation?: string;
  layout?: PopupLayout;
};

export default function PopupWindow({
  child,
  name,
  visible,
  layout = PopupLayout.CENTER,
  ...props
}: PopupWindowProps) {
  const { TOP, RIGHT, BOTTOM, LEFT } = Astal.WindowAnchor;

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
          App.toggle_window(name);
        }
      }}
      {...props}
    >
      <Layout name={name} position={layout}>
        {child}
      </Layout>
    </window>
  );
}
