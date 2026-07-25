#!/bin/bash
# Directional resize matching Hyprland's resizeactive: the pixel delta moves
# the window's controlling edge in the pressed direction. The controlling edge
# is the trailing one (right/bottom) unless the window touches the display's
# trailing border, in which case it's the leading edge — so h/k shrink except
# on the last window of the axis, where they grow (and l/j mirror that).
#
# Routes to whichever WM is running (OmniWM via IPC, else AeroSpace).
# The AeroSpace decision is made by a compiled helper (wm-resize-calc.c) for
# speed; it is auto-compiled to ~/.local/bin on first run.
#
# NOTE: no pgrep liveness checks anywhere — macOS pgrep silently excludes the
# caller's ancestors, so a script spawned by the WM can never "see" the WM.
set -euo pipefail
dir="${1:?usage: wm-resize-dir.sh left|right|up|down}"

OMNIWMCTL=/Applications/OmniWM.app/Contents/MacOS/omniwmctl
AEROSPACE=/opt/homebrew/bin/aerospace
CALC="$HOME/.local/bin/wm-resize-calc"

if [ -x "$OMNIWMCTL" ] && "$OMNIWMCTL" ping 2>/dev/null | grep -q pong; then
  args=$("$OMNIWMCTL" query windows --visible --fields frame,mode,is-focused --format json | /usr/bin/python3 - "$dir" <<'PY'
import json, sys

dir = sys.argv[1]
wins = json.load(sys.stdin)['result']['payload']['windows']
tiled = [w for w in wins if w.get('mode') == 'tiling']
foc = next((w for w in tiled if w.get('isFocused')), None)
if foc is None:
    sys.exit(0)
f = foc['frame']
others = [w['frame'] for w in tiled if w is not foc]

EPS = 40
def overlap_v(w): return w['y'] < f['y'] + f['height'] and w['y'] + w['height'] > f['y']
def overlap_h(w): return w['x'] < f['x'] + f['width'] and w['x'] + w['width'] > f['x']
has_right = any(overlap_v(w) and abs(w['x'] - (f['x'] + f['width'])) < EPS for w in others)
has_left = any(overlap_v(w) and abs((w['x'] + w['width']) - f['x']) < EPS for w in others)
has_down = any(overlap_h(w) and abs(w['y'] - (f['y'] + f['height'])) < EPS for w in others)
has_up = any(overlap_h(w) and abs((w['y'] + w['height']) - f['y']) < EPS for w in others)

# ids that empirically grow/shrink the focused window per axis in OmniWM
GROW = {'h': ['left', 'grow'], 'v': ['down', 'grow']}
SHRINK = {'h': ['left', 'shrink'], 'v': ['down', 'shrink']}
axis = 'h' if dir in ('left', 'right') else 'v'
trailing = has_right if axis == 'h' else has_down
leading = has_left if axis == 'h' else has_up
if not trailing and not leading:
    sys.exit(0)
toward_end = dir in ('right', 'down')
if trailing:
    args = GROW[axis] if toward_end else SHRINK[axis]
else:
    args = SHRINK[axis] if toward_end else GROW[axis]
print(' '.join(args))
PY
) || exit 0
  [ -n "$args" ] && exec "$OMNIWMCTL" command resize $args
  exit 0
fi

if [ ! -x "$CALC" ]; then
  mkdir -p "$HOME/.local/bin"
  /usr/bin/cc -O2 -o "$CALC" "$HOME/dev/dot/scripts/wm-resize-calc.c" \
    -framework CoreGraphics -framework CoreFoundation 2>/dev/null || exit 0
fi

wid=$("$AEROSPACE" list-windows --focused --format '%{window-id}' 2>/dev/null) || exit 0
args=$("$CALC" "$dir" "$wid") || exit 0
[ -n "$args" ] && exec "$AEROSPACE" resize $args
exit 0
