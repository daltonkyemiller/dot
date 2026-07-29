---
name: tanstack-start
description: Use when building TanStack Start apps with current guidance.
version: 1.0.0
author: Hermes Agent
license: Private
metadata:
  hermes:
    tags: [tanstack-start, react, scaffolding, intent]
    related_skills: [dalton-product-build, code-style, public-site-deployment]
---

# TanStack Start

## Authority

Use current TanStack tooling instead of model memory:

- CLI docs: `https://tanstack.com/cli/latest/docs/cli-reference`
- Start docs: `https://tanstack.com/start/latest/docs/framework/react`
- Intent docs: `https://tanstack.com/intent/latest`

Search documentation from the project root:

```sh
pnpm dlx @tanstack/cli@latest search-docs "<query>" --library start --framework react --json
```

Fetch a known page with `pnpm dlx @tanstack/cli@latest doc start <path> --json`.

## Dalton scaffold

Prefer the maintained GitHub template:

```sh
gh repo create <name> --private --template daltonkyemiller/dalton-start-template --clone
cd <name>
corepack enable
pnpm install
pnpm init:project <name>
```

The initializer resets PRODUCT.md to a project-named fill-in brief. Complete every TODO before product UI work; preserve DESIGN.md as a baseline until the real design system replaces it.

For a clean official scaffold when the template is inappropriate:

```sh
pnpm dlx @tanstack/cli@latest create <name> \
  --framework React \
  --package-manager pnpm \
  --no-examples \
  --deployment nitro \
  --no-toolchain \
  --intent \
  --no-git \
  -y
```

Do not use `--blank` when Tailwind or Intent should be present; blank intentionally omits them. Current Start/Oxc packages and pnpm 11.18 require Node 22.13 or newer.

## Version-matched package skills

Trust only explicitly allowed package skills. Dalton projects use:

```json
{"intent":{"skills":["@tanstack/*"]}}
```

Before substantial TanStack edits:

```sh
pnpm dlx @tanstack/intent@latest list
pnpm dlx @tanstack/intent@latest load <package>#<skill>
```

Use the most specific matching installed skill. Package skills version with the installed package and take precedence over general recollection.

## Build discipline

- Read `AGENTS.md`, PRODUCT.md, DESIGN.md, `.cta.json`, Vite config, and package scripts first.
- Keep secrets and database access in server handlers or `.server.ts` modules.
- Do not expose Vite environment variables to the client unless intentionally public.
- Use Tailwind v4 CSS-first `@theme`; avoid a config file unless a plugin requires it.
- Preserve generated route files; exclude tests from route discovery with the configured ignore prefix.
- Run `pnpm check`, then exercise the production server or container over its loopback listener.

## Public deployment

The template emits Nitro's `.output/server/index.mjs` and includes a hardened Docker Compose service bound to `127.0.0.1`. Publish that loopback service through `publish-dalton-site proxy`; never expose the app's container port directly to the internet.
