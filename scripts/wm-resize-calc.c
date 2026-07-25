// Directional-resize decision helper for wm-resize-dir.sh (AeroSpace branch).
// Usage: wm-resize-calc <left|right|up|down> <cg-window-id>
// Prints aerospace resize args, e.g. "width -40". Hyprland resizeactive
// semantics: the delta moves the window's controlling edge in the pressed
// direction; controlling edge is trailing (right/bottom) unless the window
// touches the display's trailing border, then it's the leading edge.
//
// Build: cc -O2 -o ~/.local/bin/wm-resize-calc wm-resize-calc.c \
//          -framework CoreGraphics -framework CoreFoundation
#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  if (argc < 3) return 1;
  const char *dir = argv[1];
  long wid = atol(argv[2]);

  CFArrayRef list = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
  if (!list) return 1;
  CGRect f = CGRectNull;
  for (CFIndex i = 0; i < CFArrayGetCount(list); i++) {
    CFDictionaryRef d = CFArrayGetValueAtIndex(list, i);
    CFNumberRef numRef = CFDictionaryGetValue(d, kCGWindowNumber);
    long num = 0;
    if (numRef) CFNumberGetValue(numRef, kCFNumberLongType, &num);
    if (num == wid) {
      CFDictionaryRef b = CFDictionaryGetValue(d, kCGWindowBounds);
      if (b) CGRectMakeWithDictionaryRepresentation(b, &f);
      break;
    }
  }
  CFRelease(list);
  if (CGRectIsNull(f)) return 1;

  // display containing the window center (CGDisplayBounds shares the same
  // top-left global coordinate space as kCGWindowBounds — no flipping)
  CGDirectDisplayID ids[16];
  uint32_t n = 0;
  CGGetActiveDisplayList(16, ids, &n);
  CGPoint c = CGPointMake(CGRectGetMidX(f), CGRectGetMidY(f));
  CGRect s = CGDisplayBounds(CGMainDisplayID());
  for (uint32_t i = 0; i < n; i++) {
    CGRect r = CGDisplayBounds(ids[i]);
    if (CGRectContainsPoint(r, c)) { s = r; break; }
  }

  const double EPS = 45; // outer gap (20) + border/rounding tolerance
  int rightmost = (CGRectGetMaxX(s) - CGRectGetMaxX(f)) < EPS;
  int bottommost = (CGRectGetMaxY(s) - CGRectGetMaxY(f)) < EPS;
  int horiz = !strcmp(dir, "left") || !strcmp(dir, "right");
  int toward_end = !strcmp(dir, "right") || !strcmp(dir, "down");
  int grow = horiz ? (toward_end != rightmost) : (toward_end != bottommost);
  printf("%s %s40\n", horiz ? "width" : "height", grow ? "+" : "-");
  return 0;
}
