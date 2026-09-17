#!/usr/bin/env python3
"""Build the Calipic icon v2 refinement candidates from one parametric construction.

Usage (from the repo root):  scripts/brand/build-icon-v2.py

Writes
  docs/brand/assets/calipic-icon-v2-master.svg   flat master, full detail (>= 60 px)
  docs/brand/assets/calipic-icon-v2-small.svg    flat small-size master (< 60 px): wider gaps, heavier stroke
  docs/brand/prototypes/icon-v2/                 finished (depth/shadow/texture) variants, PNG renders, comparison sheets

The flat masters keep the v0 colour tokens (#111111 mark, #FFFFFF field, #D9D9D9 keyline) so the
round-1 evidence scripts (render-color-matrix.sh, render-icon-sizes.sh, render-a11y.sh) re-run on them unchanged.

Geometry is exact by construction: every frame segment is generated from the same numbers and mirrored around
y = 512, so symmetry, stroke, radii and caps cannot drift. Stdlib only; PNGs are rendered with inkscape.
"""
import math
import os
import shutil
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ASSETS = os.path.join(ROOT, "docs/brand/assets")
OUT = os.path.join(ROOT, "docs/brand/prototypes/icon-v2")

C = 512  # canvas centre; canvas is 1024


class Spec:
    """One construction. All values are in 1024-canvas units."""

    def __init__(self, stroke, net_gap, right_sweep, left=180, right=844, top=180, radius=130, shift_x=0, bust="swept"):
        self.stroke = stroke            # uniform frame stroke
        self.net_gap = net_gap          # visible gap between round caps (top, bottom, left)
        self.right_sweep = right_sweep  # degrees of the right corners that are drawn; < 90 widens the C opening
        self.left, self.right, self.top, self.radius = left, right, top, radius
        self.shift_x = shift_x          # optical correction for the open right side
        self.bust = bust                # which person sits in the frame; the frame itself never changes


FULL = Spec(stroke=72, net_gap=30, right_sweep=52, shift_x=14)
SMALL = Spec(stroke=82, net_gap=44, right_sweep=52, shift_x=14)


def frame_paths(s):
    """Four segments. Small gaps top/bottom/left; the right corners simply end, leaving the wide C opening."""
    L, R, T, r = s.left + s.shift_x, s.right + s.shift_x, s.top, s.radius
    B = 2 * C - T
    cx = (L + R) / 2
    g = (s.net_gap + s.stroke) / 2  # half the centre-line gap (caps are round, radius stroke/2)
    top_left = f"M {cx - g:g} {T} H {L + r} A {r} {r} 0 0 0 {L} {T + r} V {C - g:g}"
    bot_left = f"M {cx - g:g} {B} H {L + r} A {r} {r} 0 0 1 {L} {B - r} V {C + g:g}"
    a = math.radians(s.right_sweep)
    ex, dy = R - r + r * math.sin(a), r * (1 - math.cos(a))  # the right corners stop early: that is the C opening
    top_right = f"M {cx + g:g} {T} H {R - r} A {r} {r} 0 0 1 {ex:.2f} {T + dy:.2f}"
    bot_right = f"M {cx + g:g} {B} H {R - r} A {r} {r} 0 0 0 {ex:.2f} {B - dy:.2f}"
    return [top_left, bot_left, top_right, bot_right]


def hair_paths(name, x):
    """Hair is drawn over a shared head, so every person keeps the same face, ears, neck, shoulders and size."""
    if name == "swept":
        return [f'<path d="M {x - 150} 372 C {x - 104} 296 {x - 44} 258 {x + 24} 258 '
                f'C {x + 104} 258 {x + 150} 330 {x + 138} 420 C {x + 134} 448 {x + 126} 462 {x + 116} 470 '
                f'L {x - 116} 470 C {x - 116} 440 {x - 118} 410 {x - 124} 396 '
                f'C {x - 128} 384 {x - 138} 376 {x - 150} 372 Z"/>']
    short = (f'<path d="M {x - 128} 450 C {x - 140} 340 {x - 80} 270 {x} 270 '
             f'C {x + 80} 270 {x + 140} 340 {x + 128} 450 L {x + 116} 470 L {x - 116} 470 Z"/>')
    if name == "short":
        return [short]
    if name == "bun":
        return [short, f'<ellipse cx="{x}" cy="270" rx="54" ry="40"/>']
    if name == "bob":
        return [f'<path d="M {x - 150} 560 C {x - 176} 400 {x - 110} 262 {x} 262 '
                f'C {x + 110} 262 {x + 176} 400 {x + 150} 560 C {x + 150} 590 {x + 130} 604 {x + 108} 600 '
                f'L {x - 108} 600 C {x - 130} 604 {x - 150} 590 {x - 150} 560 Z"/>']
    if name == "long":
        return [f'<path d="M {x - 142} 664 V 404 C {x - 142} 312 {x - 86} 262 {x} 262 '
                f'C {x + 86} 262 {x + 142} 312 {x + 142} 404 V 664 Z"/>']
    if name == "curly":
        out = []
        for deg in range(190, 351, 20):  # soft scallops around the crown
            a = math.radians(deg)
            out.append(f'<circle cx="{x + 112 * math.cos(a):.1f}" cy="{408 + 112 * math.sin(a):.1f}" r="44"/>')
        return out
    raise ValueError(name)


BUSTS = ["swept", "short", "curly", "bob", "long", "bun"]


def bust_paths(s):
    """Simple, neutral front-facing bust: shared head with ears, neck, broad shoulders, flat print-like base."""
    x = C + s.shift_x
    head = (f'<path d="M {x + 116} 470 C {x + 136} 466 {x + 142} 490 {x + 134} 516 '
            f'C {x + 130} 534 {x + 122} 542 {x + 110} 542 '
            f'C {x + 100} 592 {x + 60} 628 {x} 628 C {x - 60} 628 {x - 100} 592 {x - 110} 542 '
            f'C {x - 122} 542 {x - 130} 534 {x - 134} 516 C {x - 142} 490 {x - 136} 466 {x - 116} 470 '
            f'C {x - 120} 370 {x - 70} 296 {x} 296 C {x + 70} 296 {x + 120} 370 {x + 116} 470 Z"/>')
    body = (f'<path d="M {x - 54} 596 C {x - 54} 640 {x - 66} 664 {x - 104} 676 '
            f'C {x - 172} 694 {x - 218} 716 {x - 232} 760 H {x + 232} '
            f'C {x + 218} 716 {x + 172} 694 {x + 104} 676 C {x + 66} 664 {x + 54} 640 {x + 54} 596 Z"/>')
    return [head, body] + hair_paths(s.bust, x)


def flat_svg(s, title):
    frame = "\n    ".join(f'<path d="{d}"/>' for d in frame_paths(s))
    bust = "\n    ".join(bust_paths(s))
    strand = ""
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" role="img" aria-labelledby="title desc">
  <title id="title">{title}</title>
  <desc id="desc">A portrait bust inside a rounded crop frame with small gaps at top, bottom and left and a wide opening on the right, so the frame reads as a capital C.</desc>
  <!-- Generated by scripts/brand/build-icon-v2.py. Do not hand-edit; change the Spec and rebuild. -->
  <rect x="28" y="28" width="968" height="968" rx="216" fill="#FFFFFF" stroke="#D9D9D9" stroke-width="4"/>
  <g fill="none" stroke="#111111" stroke-width="{s.stroke}" stroke-linecap="round" stroke-linejoin="round">
    {frame}
  </g>
  <g fill="#111111">
    {bust}
  </g>{strand}
</svg>
'''


# Teal was chosen by the founder on 2026-09-17 (BD-033). Gradient stops are working values around #0E6F7C.
FINISHES = {
    "teal": {"top": "#15899A", "bottom": "#0A5863"},
}


def finished_svg(s, name, f):
    """Full-bleed square (the system applies the icon mask). Depth comes from three restrained layers:
    a lit field with paper grain, a soft contact shadow, and a faintly modelled white mark."""
    frame = "\n      ".join(f'<path d="{d}"/>' for d in frame_paths(s))
    bust = "\n      ".join(bust_paths(s))
    cut = ""
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <title>Calipic icon v2 - finished study {name}</title>
  <!-- Generated by scripts/brand/build-icon-v2.py. Study, not a production asset. -->
  <defs>
    <linearGradient id="field" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="{f["top"]}"/><stop offset="1" stop-color="{f["bottom"]}"/>
    </linearGradient>
    <radialGradient id="light" cx="0.3" cy="0.12" r="0.9">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.22"/><stop offset="0.6" stop-color="#FFFFFF" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="mark" gradientUnits="userSpaceOnUse" x1="0" y1="150" x2="0" y2="880">
      <stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#E4EEF1"/>
    </linearGradient>
    <filter id="grain" x="0" y="0" width="1" height="1" color-interpolation-filters="sRGB">
      <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="7" result="n"/>
      <feColorMatrix in="n" type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0.33 0.33 0.33 0 -0.28"/>
    </filter>
    <filter id="shadow" x="-0.2" y="-0.2" width="1.4" height="1.4" color-interpolation-filters="sRGB">
      <feGaussianBlur in="SourceAlpha" stdDeviation="14"/>
      <feOffset dy="14"/>
      <feComponentTransfer><feFuncA type="linear" slope="0.30"/></feComponentTransfer>
    </filter>
    <mask id="cut" maskUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024">
      <rect width="1024" height="1024" fill="#FFFFFF"/>{cut}
    </mask>
    <g id="glyph" mask="url(#cut)">
      <g fill="none" stroke-width="{s.stroke}" stroke-linecap="round" stroke-linejoin="round">
      {frame}
      </g>
      <g stroke="none">
      {bust}
      </g>
    </g>
  </defs>
  <rect width="1024" height="1024" fill="url(#field)"/>
  <rect width="1024" height="1024" fill="url(#light)"/>
  <rect width="1024" height="1024" filter="url(#grain)" opacity="0.10"/>
  <use href="#glyph" fill="#000000" stroke="#000000" filter="url(#shadow)"/>
  <use href="#glyph" fill="url(#mark)" stroke="url(#mark)"/>
</svg>
'''


def inkscape(svg, png, width):
    subprocess.run(["inkscape", svg, "--export-type=png", "-w", str(width), "-o", png],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def sheet(path, rows, sizes, title, note):
    """rows: [(label, {size: png_filename})]. Icons are shown at true pixel size, masked."""
    pad, label_w, gap = 48, 250, 40
    width = pad * 2 + label_w + sum(sizes) + gap * len(sizes)
    row_h = max(sizes) + 70
    height = 150 + row_h * len(rows) + 40
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
           f'width="{width}" height="{height}" viewBox="0 0 {width} {height}" font-family="Helvetica, Arial, sans-serif">',
           f'<rect width="{width}" height="{height}" fill="#F2F2F7"/>',
           f'<text x="{pad}" y="62" font-size="34" font-weight="700" fill="#111">{title}</text>',
           f'<text x="{pad}" y="100" font-size="20" fill="#555">{note}</text>']
    y = 150
    n = 0
    for label, files in rows:
        out.append(f'<text x="{pad}" y="{y + 40}" font-size="24" font-weight="700" fill="#111">{label}</text>')
        x = pad + label_w
        for px in sizes:
            n += 1
            rx = 0.2237 * px
            out.append(f'<clipPath id="c{n}"><rect x="{x}" y="{y}" width="{px}" height="{px}" rx="{rx:.2f}"/></clipPath>')
            out.append(f'<image xlink:href="{files[px]}" x="{x}" y="{y}" width="{px}" height="{px}" '
                       f'clip-path="url(#c{n})" style="image-rendering:pixelated"/>')
            out.append(f'<rect x="{x}" y="{y}" width="{px}" height="{px}" rx="{rx:.2f}" fill="none" stroke="#00000018"/>')
            out.append(f'<text x="{x}" y="{y + px + 26}" font-size="16" fill="#666">{px} px</text>')
            x += px + gap
        y += row_h
    out.append("</svg>")
    with open(path, "w") as fh:
        fh.write("\n".join(out))
    inkscape(path, path[:-4] + ".png", width)  # natural width, so every icon keeps its true pixels
    os.remove(path)


def main():
    if not shutil.which("inkscape"):
        sys.exit("inkscape is required")
    os.makedirs(OUT, exist_ok=True)
    master = os.path.join(ASSETS, "calipic-icon-v2-master.svg")
    small = os.path.join(ASSETS, "calipic-icon-v2-small.svg")
    with open(master, "w") as fh:
        fh.write(flat_svg(FULL, "Calipic icon v2 master (refinement candidate)"))
    with open(small, "w") as fh:
        fh.write(flat_svg(SMALL, "Calipic icon v2 small-size master (refinement candidate)"))

    sizes = [512, 180, 120, 87, 60, 40, 29]
    rows = []
    v1 = os.path.join(ASSETS, "calipic-icon-v1-master.svg")
    for label, svg, stem in [("v1 candidate (flat)", v1, "v1-flat"), ("v2 master (flat)", master, "v2-flat"),
                             ("v2 small master", small, "v2-small-flat")]:
        files = {}
        for px in sizes:
            files[px] = f"{stem}-{px}.png"
            inkscape(svg, os.path.join(OUT, files[px]), px)
        rows.append((label, files))
    sheet(os.path.join(OUT, "sheet-geometry.svg"), rows, sizes,
          "Calipic icon - v1 candidate vs v2 geometry (flat)", "True pixel sizes. v2 small master is intended for sizes below 60 px.")

    rows = []
    for name, f in FINISHES.items():
        files = {}
        full_svg = os.path.join(OUT, f"v2-finished-{name}.svg")
        small_svg = os.path.join(OUT, f"v2-finished-{name}-small.svg")
        with open(full_svg, "w") as fh:
            fh.write(finished_svg(FULL, name, f))
        with open(small_svg, "w") as fh:
            fh.write(finished_svg(SMALL, name + " small", f))
        inkscape(full_svg, os.path.join(OUT, f"v2-finished-{name}-1024.png"), 1024)
        for px in sizes:
            files[px] = f"v2-finished-{name}-{px}.png"
            inkscape(full_svg if px >= 60 else small_svg, os.path.join(OUT, files[px]), px)
        rows.append((f"v2 finished {name}", files))
    sheet(os.path.join(OUT, "sheet-finished.svg"), rows, sizes,
          "Calipic icon v2 - finished studies (depth, shadow, grain)",
          "Full master at 60 px and above, small master below. Teal per BD-033; exact values still working values.")
    # Alternate app icons: same frame, a different person. Finished teal, shown at Home Screen and Settings sizes.
    vdir = os.path.join(OUT, "variants")
    os.makedirs(vdir, exist_ok=True)
    rows, vsizes = [], [256, 180, 60, 29]
    teal = FINISHES["teal"]
    for bust in BUSTS:
        full = Spec(FULL.stroke, FULL.net_gap, FULL.right_sweep, shift_x=FULL.shift_x, bust=bust)
        tiny = Spec(SMALL.stroke, SMALL.net_gap, SMALL.right_sweep, shift_x=SMALL.shift_x, bust=bust)
        paths = {}
        for tag, spec in (("", full), ("-small", tiny)):
            with open(os.path.join(vdir, f"v2-flat-{bust}{tag}.svg"), "w") as fh:
                fh.write(flat_svg(spec, f"Calipic icon v2 - {bust}{tag}"))
            paths[tag] = os.path.join(vdir, f"v2-finished-{bust}{tag}.svg")
            with open(paths[tag], "w") as fh:
                fh.write(finished_svg(spec, f"{bust}{tag}", teal))
        files = {}
        for px in vsizes:
            files[px] = f"variants/v2-finished-{bust}-{px}.png"
            inkscape(paths[""] if px >= 60 else paths["-small"], os.path.join(OUT, files[px]), px)
        rows.append((bust, files))
    sheet(os.path.join(OUT, "sheet-variants.svg"), rows, vsizes,
          "Calipic icon v2 - choose-your-icon set",
          "Finished teal. 256 / 180 / 60 / 29 px at true pixels; small master below 60 px.")
    print("built", master, small, OUT)


if __name__ == "__main__":
    main()
