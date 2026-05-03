---
name: dialkit
description: Use DialKit to add or tune live UI controls for animation, layout, visual parameters, color, easing, spring physics, and runtime design exploration, but only after confirming the active project already has `dialkit` as a dependency or existing DialKit imports. Trigger when a user asks to tune UI values in real time, add control panels, expose animation/layout/style knobs, wire `useDialKit`/`createDialKit`, or adjust an existing DialKit setup. Do not use this skill for projects that do not already depend on DialKit.
---

# DialKit

DialKit is a floating control panel for tuning UI values directly in an app: sliders, toggles, color pickers, spring editors, easing curves, selects, actions, folders, presets, and JSON export.

## Dependency Gate

Before using this skill, confirm DialKit is already present in the active project:

```bash
rg -n 'dialkit' package.json . --glob '!node_modules'
```

Use this skill only if at least one of these is true:

- `package.json` lists `dialkit` in `dependencies`, `devDependencies`, or `peerDependencies`.
- Existing source imports from `dialkit`, `dialkit/solid`, `dialkit/svelte`, or `dialkit/vue`.
- The user points to a project file where DialKit is already wired.

If DialKit is absent, do not install it or rewrite the task around it unless the user explicitly asks to add DialKit. Say that this skill does not apply because the project does not currently depend on DialKit, then continue with the best local UI approach.

## Setup Check

When the dependency gate passes, verify the app root mounts `DialRoot` once and imports the stylesheet once:

```tsx
import { DialRoot } from 'dialkit'
import 'dialkit/styles.css'

export function Layout({ children }: { children: React.ReactNode }) {
  return (
    <>
      {children}
      <DialRoot />
    </>
  )
}
```

Mount `DialRoot` as a sibling alongside app content, not as a wrapper around it. Keep existing root/layout conventions and avoid duplicating `DialRoot` if the project already mounts it.

## React Pattern

Use `useDialKit(name, config, options?)` inside the component being tuned. Keep config close to the values it controls so agents can remove or promote the tuned values later.

```tsx
import { useDialKit } from 'dialkit'
import { motion } from 'motion/react'

export function Card() {
  const params = useDialKit('Card', {
    gap: [16, 0, 64, 1],
    scale: [1.04, 1, 1.3, 0.01],
    background: '#ff5500',
    isVisible: true,
    spring: {
      type: 'spring',
      visualDuration: 0.3,
      bounce: 0.2,
    },
    shadow: {
      _collapsed: true,
      offsetY: [8, 0, 32, 1],
      blur: [24, 0, 80, 1],
    },
  })

  return (
    <motion.div
      animate={{ scale: params.scale, opacity: params.isVisible ? 1 : 0 }}
      transition={params.spring}
      style={{
        background: params.background,
        boxShadow: `0 ${params.shadow.offsetY}px ${params.shadow.blur}px rgb(0 0 0 / 0.2)`,
        gap: params.gap,
      }}
    />
  )
}
```

Prefer explicit slider tuples `[default, min, max, step?]` for values where range matters. Use plain numbers only when DialKit's inferred range is acceptable.

## Control Types

- Number tuple: `[default, min, max, step?]` for sliders.
- Boolean: toggle control.
- Hex string: color picker.
- Non-hex string: text input.
- `{ type: 'select', options, default }`: dropdown.
- `{ type: 'spring', visualDuration, bounce }`: time-based spring editor.
- `{ type: 'spring', stiffness, damping, mass }`: physics spring editor.
- `{ type: 'easing', duration, ease }`: cubic bezier editor.
- `{ type: 'action' }`: button handled through `options.onAction`.
- Nested object: collapsible folder. Add `_collapsed: true` for noisy groups.

## Framework Entrypoints

Use the project's framework-specific import path:

- React: `import { DialRoot, useDialKit } from 'dialkit'`
- Solid: `import { DialRoot, createDialKit } from 'dialkit/solid'`; read values through the returned accessor, such as `params().blur`.
- Svelte 5: `import { createDialKit } from 'dialkit/svelte'`; read values directly from the returned reactive object.
- Vue 3: `import { useDialKit } from 'dialkit/vue'`; read values from the returned reactive object.

Do not migrate frameworks or animation libraries just to use DialKit. Adapt the smallest possible component surface.

## Usage Guidance

- Use DialKit for exploratory tuning, not permanent product controls.
- Keep runtime panels disabled in production unless the existing project deliberately enables them.
- Name folders by the component or behavior being tuned, such as `Hero Motion`, `Card Grid`, or `Toast`.
- Group related controls in nested folders so the panel stays scannable.
- Use actions for replay, reset, randomize, next item, or trigger toast/modal workflows.
- Preserve accessibility and reduced-motion behavior while tuning animations.
- Once the user accepts values, either leave DialKit controls if they asked for live tuning or promote final values into normal constants/tokens and remove temporary knobs.
