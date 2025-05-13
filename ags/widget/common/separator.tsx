import { GObject } from "astal";
import { astalify, Gtk, ConstructProps } from "astal/gtk3";

export class Separator extends astalify(Gtk.Separator) {
  static {
    GObject.registerClass(this);
  }

  constructor(
    props: ConstructProps<Separator, Gtk.Separator.ConstructorProps>,
  ) {
    super(props as any);
  }
}
