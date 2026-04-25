---
name: pastel
description: Convert, manipulate, and analyze colors using the pastel CLI. Use when the user asks to convert color formats, generate palettes, mix colors, find complements, adjust lightness/saturation, or get color info.
user_invocable: true
---

# Pastel Color Tool

Use the `pastel` CLI to convert, inspect, and manipulate colors. Always run pastel commands via Bash and return the results to the user.

## Color Input Formats

Pastel accepts colors in many formats. Pass them as-is:

- Hex: `#RRGGBB`, `RRGGBB`, `#RGB`
- RGB: `'rgb(119, 136, 153)'` or `'119,136,153'`
- HSL: `'hsl(210, 14.3%, 53.3%)'`
- Named: `lightslategray`, `red`, `dodgerblue`
- Gray: `'gray(0.5)'`
- With alpha: `#77889980`, `'rgba(119, 136, 153, 0.5)'`, `'hsla(210, 14.3%, 53.3%, 50%)'`

## Common Operations

### Convert between formats

```bash
pastel format <type> <color>
```

Output types: `hex`, `rgb`, `rgb-float`, `hsl`, `hsv`, `lch`, `oklch`, `lab`, `oklab`, `cmyk`, `name`, `luminance`, `brightness`, and individual channels like `hsl-hue`, `rgb-r`, etc.

Examples:
```bash
pastel format rgb '#ff6b6b'        # → rgb(255,107,107)
pastel format hsl dodgerblue       # → hsl(210,100%,56%)
pastel format hex 'rgb(30,60,90)'  # → hex value
pastel format oklch '#4ecdc4'      # → OKLCh values
```

### Inspect a color

```bash
pastel color <color>
```

Shows a full breakdown: hex, RGB, HSL, LCh, luminance, ANSI preview, and closest named color. Use this when the user wants to "see" or "inspect" a color.

### Mix two colors

```bash
pastel mix [--fraction 0.5] [--colorspace Lab] <base> <color>
```

Interpolates between colors. Fraction controls how much of the base to keep (0.0 = all base, 1.0 = all other). Colorspaces: `Lab` (default, perceptually uniform), `LCh`, `RGB`, `HSL`, `OkLab`.

### Lighten / Darken

```bash
pastel lighten <amount> <color>    # amount: 0.0 to 1.0
pastel darken <amount> <color>
```

Adjusts the HSL lightness channel. Pipe to `pastel format hex` to get the result as hex.

### Saturate / Desaturate

```bash
pastel saturate <amount> <color>
pastel desaturate <amount> <color>
```

### Complement

```bash
pastel complement <color>
```

Rotates hue by 180 degrees.

### Rotate hue

```bash
pastel rotate <degrees> <color>
```

Rotate by any angle. Useful for triadic (120), analogous (30), split-complementary (150/210) schemes.

### Generate a gradient

```bash
pastel gradient [--number 10] [--colorspace Lab] <color1> <color2> [<color3>...]
```

Generates an interpolated sequence between color stops. Pipe to `pastel format hex` for hex output.

### Generate distinct colors

```bash
pastel distinct [count]
```

Uses simulated annealing to maximize perceptual distance between colors. Good for chart palettes, category colors, data visualization.

### Readable text color

```bash
pastel textcolor <background-color>
```

Returns black or white, whichever is more readable against the given background.

### Sort colors

```bash
pastel sort-by <property> <colors...>
```

Sort by: `hue`, `brightness`, `luminance`, `chroma`, `random`.

### Gray tones

```bash
pastel gray <lightness>   # 0.0 = black, 1.0 = white
```

## Piping

Pastel commands can be piped together. This is the key power feature:

```bash
# Generate 5 distinct colors, sort by hue, output as hex
pastel distinct 5 | pastel sort-by hue | pastel format hex

# Create a 7-step gradient and get RGB values
pastel gradient '#1a1a2e' '#e94560' -n 7 | pastel format rgb

# Lighten a color and convert to HSL
pastel lighten 0.2 '#334455' | pastel format hsl

# Get complement and check readable text color for it
pastel complement '#4ecdc4' | pastel textcolor
```

## Guidelines

- Always pipe to `pastel format hex` (or the requested format) so the output is clean and usable.
- When generating palettes, also pipe through `pastel sort-by hue` for visual coherence.
- Use `pastel color` when the user wants a full breakdown or is exploring.
- Prefer `Lab` or `OkLab` colorspace for mixing/gradients (perceptually uniform). Use `HSL` only when the user specifically wants it or when hue interpolation matters.
- When the user gives a color without specifying format, detect it and pass it through directly.
- Present results clearly: show the hex values, and if relevant, show them with `pastel color` for visual preview in terminal.
