---
name: mdx-sites
description: Create, revise, preview, build, and publish local MDX sites, visual plans, implementation proposals, diagrams, and shareable HTML artifacts with mdx-preview. Use when an agent should write a durable MDX artifact instead of an inline plan, needs component-backed visual documentation, needs to preview or export an MDX site, or needs to publish a static artifact through Here Now.
---

# MDX Sites

Create durable source artifacts, not chat-only plans. Keep plan content in local MDX and use the project component registry before inventing layout markup.

## Workflow

1. Inspect the target project before writing a plan. Name actual files, symbols, and decisions.
2. Choose a checked-in `plans/<slug>/` folder unless the user asks for temporary output. Create it with:

   ```sh
   mdx-preview new <slug> --out plans --title "Plan title"
   ```

3. Run `mdx-preview components list plans/<slug>` to load the built-in and project-specific components available to that artifact. Use the smallest set that clarifies the artifact; do not pad a plan with decorative metrics or diagrams.
4. Write `index.mdx`. Use MDX imports and exports at the top level. Export local React components rather than declaring bare functions. For a substantial plan, write a short summary, then a `TableOfContents` before the first main section. Give every TOC item and matching heading the same stable `id`.
5. Preview with `mdx-preview serve plans/<slug> --open`.
6. Build a shareable static directory with `mdx-preview build plans/<slug> --out dist/<slug>`.
7. Publish only when asked, using `mdx-preview publish plans/<slug> --out dist/<slug>`. This reads `HERENOW_API_KEY` when present; otherwise it creates a 24-hour anonymous site and prints its claim URL.

## Component registry

Run `mdx-preview components list <file-or-directory>` for the component context available to that artifact. The command includes the built-ins and custom components from the nearest `mdx-preview.config.mjs`; it is the source of truth for names, props, examples, and usage guidance.

For project-specific components, create `mdx-preview.config.mjs` beside the MDX site or in an ancestor directory:

```js
export default {
  components: [
    {
      name: "ArchitectureMap",
      module: "./components/architecture-map.tsx",
      export: "ArchitectureMap",
      description: "Show service ownership and dependencies.",
      when: "Use for system boundaries with multiple services.",
    },
  ],
};
```

Add a `description`, `when`, props, and an example to the project's own agent instructions or component reference. Agents need usage intent, not only a component name.

## Site discipline

- Keep standard Markdown as the default. Use React components only when they clarify a relationship, comparison, state, or interaction.
- Default to human digestion over information density. Give the reader a clear title and one-paragraph summary; use a TOC for five or more main sections; make headings answer-oriented; open each section with its conclusion before supporting detail; keep paragraphs short; and use lists, tables, or one focused component when they scan better than prose.
- Preserve visual rhythm: prefer four to eight main sections, one idea per section, generous separation between major sections, and a readable narrative width. Do not build a wall of text, a dashboard of decorative cards, or a component at every heading unless the user explicitly asks for a denser or more expressive treatment.
- Use `Flow` for sequence, `Architecture` for ownership, `Diagram` for a directed handoff or dependency graph, `Comparison` for two alternatives, and `FileMap` for multi-file change surfaces.
- For `Diagram`, provide short `nodes` and `edges`, never manual positions. Keep it to eight nodes and twelve edges, avoid cycles, and split unrelated relationships into separate diagrams. Use `renderer="flow"` only when pan, zoom, and fit-view improve review; keep the static renderer for a compact finished document. Do not use a diagram when a `Flow` or short table is easier to scan.
- Build a static directory as the canonical export. Use `--single-file` only when a recipient explicitly needs one HTML file.
- Keep theme overrides token-based. For a site-wide default, add `theme: "./theme.css"` to the nearest `mdx-preview.config.mjs`; every Document below that config inherits it. For one Document only, import a neighboring stylesheet from its MDX, such as `import "./article.css"`. The local import loads after the site theme and overrides it.
- Define light values in `:root`, explicit dark values in `:root[data-theme="dark"]`, and system-dark values in `prefers-color-scheme` so the viewer controls remain meaningful. Override the full surface set used by the artifact—at least `--background`, `--foreground`, `--card`, `--border`, `--muted`, and `--primary`—rather than changing one accent token in isolation.
- Do not publish private material without explicit approval. Keep `.herenow/` out of source control.
