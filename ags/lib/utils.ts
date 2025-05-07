import type * as CSS from "csstype";
import { timeout } from "astal";
import type { AstalIO } from "astal";

const camelToKebab = (str: string) =>
  str.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();

export function styleToCss(styles: CSS.Properties) {
  return Object.entries(styles)
    .map(([key, value]) => `${camelToKebab(key)}: ${value};`)
    .join("");
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
