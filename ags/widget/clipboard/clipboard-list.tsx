import { Variable } from "astal";
import { ClipboardItem } from "./clipboard-item";
import { search } from "./store";
import { Astal, Gtk } from "astal/gtk3";

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
    <scrollable heightRequest={500} vexpand>
      <box vertical spacing={5} className="clipboard-list">
        {filteredValues().as((values) =>
          values.map((v) => <ClipboardItem id={v.id} text={v.text} />),
        )}
      </box>
    </scrollable>
  );
}
