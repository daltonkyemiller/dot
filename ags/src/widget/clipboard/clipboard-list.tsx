import { Variable } from "astal";
import { ClipboardItem } from "./clipboard-item";
import { search } from "./store";
import { Gtk } from "astal/gtk4";
import { cn } from "../../lib/utils";

const maxItems = 100;

interface ClipboardListProps {
  values: Variable<{ id: number; text: string }[]>;
}

export function ClipboardList({ values }: ClipboardListProps) {
  const filteredValues = Variable.derive([values, search], (values, search) => {
    return values
      .filter(
        (v) => v.id.toString().includes(search) || v.text.includes(search),
      )
      .slice(0, maxItems);
  });

  return (
    <Gtk.ScrolledWindow heightRequest={500}>
      <box vertical spacing={5} cssClasses={cn("bg-bg")}>
        {filteredValues().as((values) =>
          values.map((v) => <ClipboardItem id={v.id} text={v.text} />),
        )}
      </box>
    </Gtk.ScrolledWindow>
  );
}
