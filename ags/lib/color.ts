type RGBA = [r: number, g: number, b: number, a: number];

function hexToRGBA(hex: string): RGBA {
  const [r, g, b] =
    hex
      .replace("#", "")
      .match(/.{2}/g)
      ?.map((x) => parseInt(x, 16)) ?? [];

  return [r, g, b, 255];
}

function RGBAToHex(rgba: RGBA) {
  return `#${rgba[0].toString(16).padStart(2, "0")}${rgba[1]
    .toString(16)
    .padStart(2, "0")}${rgba[2].toString(16).padStart(2, "0")}`;
}

export function changeAlpha(
  hexOrRGBA: string | RGBA,
  alpha: number,
): RGBA{
  // Convert alpha from 0-1 to 0-255
  const alphaValue = Math.round(alpha * 255);
  
  if (typeof hexOrRGBA === "string") {
    const [r, g, b] = hexToRGBA(hexOrRGBA);
    return [r, g, b, alphaValue];
  } else {
    return [hexOrRGBA[0], hexOrRGBA[1], hexOrRGBA[2], alphaValue];
  }
}

export function saturate(hexOrRGBA: string | RGBA, amount: number) {
  if (typeof hexOrRGBA === "string") {
    const [r, g, b] = hexToRGBA(hexOrRGBA);
    return RGBAToHex([
      Math.max(0, Math.min(255, r + amount)),
      Math.max(0, Math.min(255, g + amount)),
      Math.max(0, Math.min(255, b + amount)),
      255,
    ]);
  } else {
    return [
      Math.max(0, Math.min(255, hexOrRGBA[0] + amount)),
      Math.max(0, Math.min(255, hexOrRGBA[1] + amount)),
      Math.max(0, Math.min(255, hexOrRGBA[2] + amount)),
      255,
    ];
  }
}

export function changeBrightness(hexOrRGBA: string, amount: number): string;
export function changeBrightness(hexOrRGBA: RGBA, amount: number): RGBA;
export function changeBrightness(
  hexOrRGBA: string | RGBA,
  amount: number,
): RGBA | string {
  if (typeof hexOrRGBA === "string") {
    const [r, g, b] = hexToRGBA(hexOrRGBA);
    const adjustR =
      amount > 0
        ? Math.round(r + (255 - r) * amount)
        : Math.round(r * (1 + amount));
    const adjustG =
      amount > 0
        ? Math.round(g + (255 - g) * amount)
        : Math.round(g * (1 + amount));
    const adjustB =
      amount > 0
        ? Math.round(b + (255 - b) * amount)
        : Math.round(b * (1 + amount));

    return RGBAToHex([
      Math.max(0, Math.min(255, adjustR)),
      Math.max(0, Math.min(255, adjustG)),
      Math.max(0, Math.min(255, adjustB)),
      255,
    ]);
  } else {
    const adjustR =
      amount > 0
        ? Math.round(hexOrRGBA[0] + (255 - hexOrRGBA[0]) * amount)
        : Math.round(hexOrRGBA[0] * (1 + amount));
    const adjustG =
      amount > 0
        ? Math.round(hexOrRGBA[1] + (255 - hexOrRGBA[1]) * amount)
        : Math.round(hexOrRGBA[1] * (1 + amount));
    const adjustB =
      amount > 0
        ? Math.round(hexOrRGBA[2] + (255 - hexOrRGBA[2]) * amount)
        : Math.round(hexOrRGBA[2] * (1 + amount));

    return [
      Math.max(0, Math.min(255, adjustR)),
      Math.max(0, Math.min(255, adjustG)),
      Math.max(0, Math.min(255, adjustB)),
      255,
    ];
  }
}

export function isColorDark(hexOrRGBA: string | RGBA) {
  if (typeof hexOrRGBA === "string") {
    const [r, g, b] = hexToRGBA(hexOrRGBA);
    return r * 0.299 + g * 0.587 + b * 0.114 > 186;
  } else {
    return (
      hexOrRGBA[0] * 0.299 + hexOrRGBA[1] * 0.587 + hexOrRGBA[2] * 0.114 > 186
    );
  }
}

export function cssRGBA(rgba: RGBA) {
  return `rgba(${rgba[0]}, ${rgba[1]}, ${rgba[2]}, ${rgba[3] / 255})`;
}
