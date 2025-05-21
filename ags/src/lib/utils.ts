import type * as CSS from "csstype";
import { exec, execAsync, timeout } from "astal";
import type { AstalIO } from "astal";
import { Gtk } from "astal/gtk4";

const camelToKebab = (str: string) =>
  str.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();

export function styleToCss(styles: CSS.Properties) {
  return Object.entries(styles)
    .map(([key, value]) => `${camelToKebab(key)}: ${value};`)
    .join("");
}

export function bash(cmd: string | string[]) {
  const cmdArray = Array.isArray(cmd) ? cmd : [cmd];
  return exec(["bash", "-c", ...cmdArray]);
}

export function bashAsync(cmd: string | string[]) {
  const cmdArray = Array.isArray(cmd) ? cmd : [cmd];
  return execAsync(["bash", "-c", ...cmdArray]);
}

export function debounce<T extends (...args: any[]) => any>(
  delay: number,
  fn: T,
  immediateOnFirstCall = false,
): (...args: Parameters<T>) => void {
  let timer: AstalIO.Time | null = null;
  let isFirstCall = true;

  return (...args: Parameters<T>) => {
    if (timer) {
      timer.cancel();
    }

    if (immediateOnFirstCall && isFirstCall) {
      fn(...args);
      isFirstCall = false;
    } else {
      timer = timeout(delay, () => {
        fn(...args);
        timer = null;
      });
    }
  };
}

export function truncate(str: string, maxLength: number, ellipses = false) {
  if (str.length <= maxLength) {
    return str;
  }

  const ellipsesLength = ellipses ? 3 : 0;

  return `${str.slice(0, maxLength - ellipsesLength)}${ellipses ? "..." : ""}`;
}

export const isIcon = (icon: string) => {
  const iconTheme = new Gtk.IconTheme();
  return iconTheme.has_icon(icon);
};
