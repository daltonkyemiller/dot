---
name: pwa
description: Build and debug Progressive Web Apps, with a focus on iOS/iPhone standalone (installed to the home screen) reliability. Use when implementing PWA layout (app shell, fixed header/bottom tab bar), safe-area insets, viewport/height handling, the web app manifest, or a service worker — and especially when a PWA looks or behaves wrong once installed on iOS (dead gaps under a bottom bar, a nav that jumps or drifts between pages, content under the status bar / home indicator, safe-area insets that reset).
---

# Building PWAs (iOS-hardened)

Most PWA layout advice is written for desktop/Android and quietly breaks in an
**iOS standalone** app (added to the Home Screen). iOS has a cluster of real
WebKit bugs around `position: fixed`, `env(safe-area-inset-*)`, viewport
height, and client-side navigation. Follow the rules below and a PWA behaves
identically in Safari and installed — miss them and it's maddeningly
inconsistent, worse on iOS beta releases.

## The iOS failure modes (why "the textbook thing" breaks)

1. **`position: fixed` drifts.** In iOS standalone PWAs, fixed elements
   (bottom nav, sticky header) shift up / detach after navigation or after the
   app is backgrounded a while — as if a phantom Safari toolbar is pushing the
   viewport. No OS fix. → **Don't use `position: fixed` for app chrome.**
2. **`env(safe-area-inset-*)` resets to `0px` on client-side (SPA) navigation.**
   Correct on first load, then flips to 0 after a router `<Link>` navigation, so
   any padding driven by it jumps between pages. → **Cache the insets in JS.**
3. **`height: 100%` ≠ the screen.** iOS standalone resolves `100%` to the
   *safe-area* height, so a full-height shell stops short of the physical
   bottom and a strip of body background shows under the tab bar. → **Use
   `100vh`.** (In standalone there's no dynamic browser chrome, so `100vh` is
   stable; `100dvh` can report wrong values on cold start.)
4. **Body scrolling causes viewport-recalc jitter.** iOS recomputes the
   viewport during body scroll. → **The body must not scroll; scroll inside an
   inner `<main>`.**

## The rule: an app-shell layout, no `position: fixed`

A fixed-height flex column. Content scrolls **inside `<main>`**; the header and
tab bar are ordinary **flex children** pinned by layout, not by fixed
positioning. This is the single most important decision.

```html
<body>                              <!-- overflow: hidden; does NOT scroll -->
  <div class="flex h-screen flex-col">   <!-- 100vh, full screen -->
    <header class="shrink-0">…</header>       <!-- optional, flex child -->
    <main class="min-h-0 flex-1 overflow-y-auto">…</main>   <!-- the scroller -->
    <nav class="shrink-0">…tabs…</nav>        <!-- flex child, never fixed -->
  </div>
</body>
```

```css
html, body { height: 100vh; }   /* NOT 100% */
body { overflow: hidden; box-sizing: border-box; }
```

- `min-h-0` on `<main>` is required — flex items default to `min-height: auto`
  and won't shrink, so `overflow-y-auto` silently won't scroll without it.
- The nav is the last flex child → always at the bottom of the shell, which is
  the physical bottom (because the shell is `100vh`), so its own background
  fills the home-indicator area. No dead gap, no drift.
- If a router controls scroll restoration or a component reads scroll position
  (pull-to-refresh), point it at the `<main>` scroller, **not** `window`
  (`el.closest('main')?.scrollTop`, not `window.scrollY`).

## Safe-area insets: cache them, never trust live `env()`

Because `env(safe-area-inset-*)` zeroes out across navigation, measure once and
store the values as CSS variables that never regress to 0. Run this before
paint (inline `<script>` in `<head>`):

```js
(function () {
  var root = document.documentElement;
  function inset(side) {
    var p = document.createElement('div');
    p.style.cssText = 'position:fixed;visibility:hidden;pointer-events:none;left:0;width:0;'
      + side + ':0;height:env(safe-area-inset-' + side + ',0px);';
    (document.body || root).appendChild(p);
    var h = p.getBoundingClientRect().height; p.remove(); return h;
  }
  function apply(reset) {
    ['top', 'bottom'].forEach(function (side) {
      var name = side === 'top' ? '--sat' : '--sab';
      var v = inset(side);
      var cur = parseFloat(getComputedStyle(root).getPropertyValue(name)) || 0;
      if (v > 0 || reset || cur === 0) root.style.setProperty(name, v + 'px');
    });
  }
  document.body ? apply(false) : addEventListener('DOMContentLoaded', function(){apply(false);});
  addEventListener('resize', function(){apply(false);});
  addEventListener('pageshow', function(){apply(false);});
  addEventListener('orientationchange', function(){setTimeout(function(){apply(true);},300);});
  setTimeout(function(){apply(false);}, 400);   // catch late standalone settle
})();
```

Then use the cached vars (never bare `env()`), with a fixed fallback:

```css
/* status bar / notch / Dynamic Island: pages pad their own top */
.page   { padding-top: calc(1.5rem + var(--sat, 0px)); }
/* home indicator: small, consistent clearance — capped so dark mode isn't a
   big dead band; the nav bg still fills to the physical bottom */
nav      { padding-bottom: clamp(0.5rem, var(--sab, 0px), 1rem); }
```

- A full-bleed view (e.g. a video/reels player) should fill `<main>` and offset
  only its *overlay controls* by `var(--sat)`, so the media runs under the
  status bar while the buttons stay clear.

## Required viewport + meta + manifest

```html
<meta name="viewport"
      content="width=device-width, initial-scale=1, viewport-fit=cover, maximum-scale=1">
<meta name="apple-mobile-web-app-capable" content="yes">        <!-- iOS standalone -->
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="App">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">      <!-- 180×180, opaque -->
<link rel="manifest" href="/manifest.webmanifest">
<!-- paired theme-color for light/dark -->
<meta name="theme-color" content="#fff" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#000" media="(prefers-color-scheme: dark)">
```

- **`viewport-fit=cover` is mandatory** or `env(safe-area-inset-*)` is always 0.
- `black-translucent` makes web content run **under** the status bar — so you
  must pad the top yourself (`var(--sat)`), which is what the app-shell does.
- Manifest: `display: "standalone"`, `start_url`, `scope`, `background_color`,
  `theme_color`, and icons including a 512×512 `maskable`.
- iOS ignores the manifest's `theme_color`; it uses the `theme-color` meta.
- iOS needs a real `apple-touch-icon` (transparent PNGs get a black background).

## Flicker-free theming (bonus, same class of problem)

For dark mode without an SSR flash: store the choice in a cookie, render the
`class="dark"` server-side from it, and run an inline head script that resolves
`auto` from `matchMedia('(prefers-color-scheme: dark)')` before first paint.
Add `suppressHydrationWarning` on `<html>`.

## Debugging checklist (when an installed PWA looks wrong)

- Dead strip under the bottom bar → shell is `height: 100%`; use `100vh`.
- Nav jumps/drifts between pages or after backgrounding → it's `position: fixed`;
  move to the app-shell (flex child).
- Padding flips between pages → bare `env(safe-area-inset-*)`; cache to `--sat`/`--sab`.
- Content under the status bar → missing top `var(--sat)` padding (expected with
  `black-translucent`).
- Whole layout janks while scrolling → the body is scrolling; move scroll into `<main>`.
- Insets always 0 → missing `viewport-fit=cover`.
- **Test installed, not just in Safari** — Safari's toolbar hides the exact
  region that's broken in standalone. And **fully quit + reopen** after deploy;
  the service worker serves the old shell otherwise.

## Sources

- Apple Forums — `position: fixed` drifts in iOS PWAs:
  https://developer.apple.com/forums/thread/744327
- Next.js #81264 — `env(safe-area-inset-bottom)` resets to 0 on SPA nav:
  https://github.com/vercel/next.js/discussions/81264
- Mobile-friendly footers (flex/grid app-shell, dvh):
  https://www.ianjmacintosh.com/articles/mobile-friendly-footers/
- MDN — safe-area env() + `viewport-fit=cover`; web.dev — app-shell model.
