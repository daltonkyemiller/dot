import { App } from "astal/gtk3";
import AstalHyprland from "gi://AstalHyprland?version=0.1";

const hyprland = AstalHyprland.get_default();

export function sendBatch(batch: string[]) {
  const cmd = batch
    .filter((x) => !!x)
    .map((x) => `keyword ${x}`)
    .join("; ");

  hyprland.message(`[[BATCH]]/${cmd}`);
}

export function windowAnimation() {
  sendBatch(
    App.get_windows()
      .filter(({ animation }: any) => !!animation)
      .map(
        ({ animation, namespace }: any) =>
          `layerrule animation ${animation}, ${namespace}`,
      ),
  );
}
export function setupHyprland() {
  windowAnimation();
}
