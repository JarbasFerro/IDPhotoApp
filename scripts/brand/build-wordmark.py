#!/usr/bin/env python3
"""Build the Calipic wordmark and lock-ups from one parametric construction.

Usage (from the repo root):  scripts/brand/build-wordmark.py

The wordmark is drawn, not typeset: every letter of "Calipic" is made of circular bowls and straight stems with
the same uniform stroke and round caps as the icon's C-frame, and the capital C is the frame itself (rounded
square, right corners stopped early). No font is involved, so there is nothing to license and nothing to drift.

Writes
  docs/brand/assets/calipic-wordmark.svg            wordmark, ink #111111
  docs/brand/assets/calipic-lockup-horizontal.svg   symbol + wordmark
  docs/brand/assets/calipic-lockup-stacked.svg      symbol above wordmark
  docs/brand/assets/calipic-lockup-integrated.svg   the symbol as the capital C: [symbol]alipic
  docs/brand/prototypes/wordmark/                   study sheets (PNG)

Stdlib only; PNGs are rendered with inkscape. The symbol geometry is imported from build-icon-v2.py.
"""
import importlib.util
import math
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
ASSETS = os.path.join(ROOT, "docs/brand/assets")
OUT = os.path.join(ROOT, "docs/brand/prototypes/wordmark")

_spec = importlib.util.spec_from_file_location("icon", os.path.join(HERE, "build-icon-v2.py"))
icon = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(icon)

INK, TEAL, TEAL_DARK, NIGHT = "#111111", "#0E6F7C", "#4FC3D1", "#111214"

# All values are centre-line units; y grows downwards, the baseline is y = 0.
R = 100           # bowl radius: x-height is 2R
W = 36            # stroke, uniform, round caps; matches the symbol's stroke in the integrated lock-up
CAP = 300         # cap height = ascender; the descender of p mirrors it (CAP - 2R below the baseline)
OPEN = 52         # degrees: how early the c and the C stop, the same sweep as the icon's right corners
GAP = 58          # distance between the outer edges of neighbouring letters; round neighbours sit tighter


def arc_c(cx, cy, r):
    """A c: circle open to the right."""
    t = math.radians(OPEN)
    sx, sy = cx + r * math.cos(t), cy - r * math.sin(t)
    ex, ey = cx + r * math.cos(t), cy + r * math.sin(t)
    return f"M {sx:.2f} {sy:.2f} A {r} {r} 0 1 0 {ex:.2f} {ey:.2f}"


def frame_c(x, width, height, r):
    """The capital C as the icon's frame: rounded square, right corners drawn for OPEN degrees only."""
    a = math.radians(OPEN)
    top, bottom, right = -height, 0, x + width
    ex, dy = right - r + r * math.sin(a), r * (1 - math.cos(a))
    return (f"M {ex:.2f} {top + dy:.2f} A {r} {r} 0 0 0 {right - r} {top} H {x + r} A {r} {r} 0 0 0 {x} {top + r} "
            f"V {bottom - r} A {r} {r} 0 0 0 {x + r} {bottom} H {right - r} A {r} {r} 0 0 0 {ex:.2f} {bottom - dy:.2f}")


def circle(cx, cy, r):
    return f"M {cx - r} {cy} A {r} {r} 0 1 0 {cx + r} {cy} A {r} {r} 0 1 0 {cx - r} {cy} Z"


def wordmark(with_c=True):
    """Returns (stroked path data list, filled dot list, width). Left edge of the ink is x = 0.
    Without the C the word starts at "a": used by the integrated lock-up, where the symbol is the C."""
    strokes, dots = [], []
    x = W / 2                                   # centre line of the first stroke
    if with_c:
        cw = CAP * 0.86
        strokes.append(frame_c(x, cw, CAP, CAP * 0.30))
        x += cw * 0.93 + GAP * 0.55 + W         # the open side lets the next letter move in
    # a: bowl + stem on the right
    strokes += [circle(x + R, -R, R), f"M {x + 2 * R} {-2 * R} V 0"]
    x += 2 * R + W + GAP
    # l
    strokes.append(f"M {x} {-CAP} V 0")
    x += W + GAP
    # i
    def i_at(px):
        strokes.append(f"M {px} {-2 * R} V 0")
        dots.append((px, -2 * R - W * 1.55, W * 0.62))
    i_at(x)
    x += W + GAP
    # p: stem on the left + bowl
    strokes += [f"M {x} {-2 * R} V {CAP - 2 * R}", circle(x + R, -R, R)]
    x += 2 * R + W + GAP
    # i
    i_at(x)
    x += W + GAP * 0.9
    # c
    strokes.append(arc_c(x + R, -R, R))
    t = math.radians(OPEN)
    width = x + R + R * math.cos(t) + W / 2
    return strokes, dots, width


def wordmark_group(ink, dx=0, dy=0, scale=1.0, with_c=True):
    strokes, dots, _ = wordmark(with_c)
    body = "".join(f'<path d="{d}"/>' for d in strokes)
    dot = "".join(f'<circle cx="{cx}" cy="{cy:.2f}" r="{r:.2f}" fill="{ink}" stroke="none"/>' for cx, cy, r in dots)
    return (f'<g transform="translate({dx:.2f} {dy:.2f}) scale({scale})" fill="none" stroke="{ink}" '
            f'stroke-width="{W}" stroke-linecap="round" stroke-linejoin="round">{body}{dot}</g>')


def symbol_group(ink, field, dx, dy, size):
    """The flat symbol without a tile: frame + default bust, scaled so the frame's outer height is `size`."""
    s = icon.Spec(icon.FULL.stroke, icon.FULL.net_gap, icon.FULL.right_sweep, shift_x=0, bust="swept")
    top = s.top - s.stroke / 2
    outer = (2 * icon.C - s.top) + s.stroke / 2 - top
    k = size / outer
    frame = "".join(f'<path d="{d}"/>' for d in icon.frame_paths(s))
    bust = "".join(icon.bust_paths(s))
    left = s.left - s.stroke / 2
    return (f'<g transform="translate({dx:.2f} {dy:.2f}) scale({k:.5f}) translate({-left} {-top})">'
            f'<g fill="none" stroke="{ink}" stroke-width="{s.stroke}" stroke-linecap="round">{frame}</g>'
            f'<g fill="{ink}">{bust}</g></g>'), size * (s.right - s.left + s.stroke) / outer


def svg(width, height, body, background=None):
    bg = f'<rect width="{width:.0f}" height="{height:.0f}" fill="{background}"/>' if background else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width:.0f} {height:.0f}" '
            f'width="{width:.0f}" height="{height:.0f}">\n<!-- Generated by scripts/brand/build-wordmark.py -->\n'
            f'{bg}{body}\n</svg>\n')


def wordmark_svg(ink=INK, background=None, pad=None):
    _, _, width = wordmark()
    pad = CAP * 0.5 if pad is None else pad     # clear space: half the cap height on every side
    above, below = CAP + W / 2, CAP - 2 * R + W / 2
    return svg(width + 2 * pad, above + below + 2 * pad, wordmark_group(ink, pad, pad + above), background)


def lockup_horizontal(ink=INK, background=None):
    _, _, width = wordmark()
    pad = CAP * 0.5
    above, below = CAP + W / 2, CAP - 2 * R + W / 2
    size = (above + below) * 1.0                # symbol spans ascender to descender
    sym, sym_w = symbol_group(ink, background, pad, pad, size)
    gap = CAP * 0.55
    body = sym + wordmark_group(ink, pad + sym_w + gap, pad + above)
    return svg(pad * 2 + sym_w + gap + width, above + below + 2 * pad, body, background)


def lockup_stacked(ink=INK, background=None):
    _, _, width = wordmark()
    pad = CAP * 0.5
    above, below = CAP + W / 2, CAP - 2 * R + W / 2
    size = width * 0.46
    sym, sym_w = symbol_group(ink, background, pad + (width - sym_w_of(size)) / 2, pad, size)
    body = sym + wordmark_group(ink, pad, pad + size + CAP * 0.45 + above)
    return svg(width + 2 * pad, size + CAP * 0.45 + above + below + 2 * pad, body, background)


def lockup_integrated(ink=INK, background=None):
    """The symbol stands in for the capital C: [symbol]alipic."""
    _, _, width = wordmark(with_c=False)
    pad = CAP * 0.5
    above, below = CAP + W / 2, CAP - 2 * R + W / 2
    size = CAP + W                              # the frame's outer height equals the outer cap height
    sym, sym_w = symbol_group(ink, background, pad, pad, size)
    gap = GAP * 0.75
    body = sym + wordmark_group(ink, pad + sym_w + gap, pad + above, with_c=False)
    return svg(pad * 2 + sym_w + gap + width, above + below + 2 * pad, body, background)


def sym_w_of(size):
    s = icon.FULL
    outer = (2 * icon.C - s.top) + s.stroke / 2 - (s.top - s.stroke / 2)
    return size * (s.right - s.left + s.stroke) / outer


def inkscape(src, png, width):
    subprocess.run(["inkscape", src, "--export-type=png", "-w", str(int(width)), "-o", png],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main():
    if not shutil.which("inkscape"):
        sys.exit("inkscape is required")
    os.makedirs(OUT, exist_ok=True)
    masters = {"calipic-wordmark.svg": wordmark_svg(), "calipic-lockup-horizontal.svg": lockup_horizontal(),
               "calipic-lockup-stacked.svg": lockup_stacked(),
               "calipic-lockup-integrated.svg": lockup_integrated()}
    for name, text in masters.items():
        with open(os.path.join(ASSETS, name), "w") as fh:
            fh.write(text)

    # Study sheet: colourways and small sizes, composed from rendered PNGs.
    ways = [("ink", INK, "#FFFFFF"), ("teal", TEAL, "#FFFFFF"), ("reversed", "#FFFFFF", TEAL), ("dark", TEAL_DARK, NIGHT)]
    tiles = []
    for tag, ink, bg in ways:
        for kind, fn in (("wordmark", wordmark_svg), ("horizontal", lockup_horizontal), ("stacked", lockup_stacked),
                         ("integrated", lockup_integrated)):
            path = os.path.join(OUT, f"{kind}-{tag}.svg")
            with open(path, "w") as fh:
                fh.write(fn(ink, bg))
            inkscape(path, path[:-4] + ".png", 1200 if kind != "stacked" else 700)
            os.remove(path)
            tiles.append((kind, tag))
    path = os.path.join(OUT, "small.svg")
    with open(path, "w") as fh:
        fh.write(lockup_horizontal())
    for px in (480, 240, 160, 110):
        inkscape(path, os.path.join(OUT, f"horizontal-ink-{px}w.png"), px)
    with open(path, "w") as fh:
        fh.write(lockup_integrated())
    for px in (480, 240, 160, 110):
        inkscape(path, os.path.join(OUT, f"integrated-ink-{px}w.png"), px)
    os.remove(path)
    print("built", ", ".join(masters), "and", OUT)


if __name__ == "__main__":
    main()
