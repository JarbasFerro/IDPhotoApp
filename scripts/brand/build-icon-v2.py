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


def _p(d):
    return f'<path d="{d}"/>'


def _both(fn):
    """Draw a shape on the left (sign -1) and its mirror on the right (sign +1)."""
    return [fn(-1), fn(1)]


def _cap(x, top=270):
    return _p(f"M {x - 128} 450 C {x - 140} 340 {x - 80} {top} {x} {top} "
              f"C {x + 80} {top} {x + 140} 340 {x + 128} 450 L {x + 116} 470 L {x - 116} 470 Z")


def _swept(x):
    return [_p(f"M {x - 150} 372 C {x - 104} 296 {x - 44} 258 {x + 24} 258 "
               f"C {x + 104} 258 {x + 150} 330 {x + 138} 420 C {x + 134} 448 {x + 126} 462 {x + 116} 470 "
               f"L {x - 116} 470 C {x - 116} 440 {x - 118} 410 {x - 124} 396 "
               f"C {x - 128} 384 {x - 138} 376 {x - 150} 372 Z")]


def _spiky(x):
    pts = [(-128, 440), (-122, 330), (-98, 262), (-72, 308), (-44, 240), (-16, 294), (16, 236), (44, 294),
           (76, 246), (98, 312), (124, 276), (128, 440)]
    return [_p("M " + " L ".join(f"{x + dx} {y}" for dx, y in pts) + " Z")]


def _curly(x):
    out = []
    for deg in range(190, 351, 20):
        a = math.radians(deg)
        out.append(f'<circle cx="{x + 112 * math.cos(a):.1f}" cy="{408 + 112 * math.sin(a):.1f}" r="44"/>')
    return out


def _braids(x):
    out = [_cap(x)]
    for sgn in (-1, 1):
        for i, y in enumerate(range(470, 691, 44)):
            out.append(f'<circle cx="{x + sgn * (146 + i * 2)}" cy="{y}" r="{30 - i * 2}"/>')
    return out


def _alien(x):
    out = [_p(f"M {x} 656 C {x - 60} 630 {x - 184} 500 {x - 176} 400 C {x - 168} 316 {x - 90} 276 {x} 276 "
              f"C {x + 90} 276 {x + 168} 316 {x + 176} 400 C {x + 184} 500 {x + 60} 630 {x} 656 Z")]
    for s in (-1, 1):
        out.append(_p(f"M {x + s * 52} 300 L {x + s * 100} 244 L {x + s * 112} 254 L {x + s * 70} 312 Z"))
        out.append(f'<circle cx="{x + s * 110}" cy="244" r="20"/>')
    return out


def _ellipse_ring(x, cy, rx, ry, w):
    def loop(a, b):
        return f"M {x - a} {cy} A {a} {b} 0 1 0 {x + a} {cy} A {a} {b} 0 1 0 {x - a} {cy} Z"
    return _p(loop(rx, ry) + " " + loop(rx - w, ry - w))


def _locs(x):
    out = [_p(f"M {x - 186} 470 C {x - 186} 330 {x - 104} 256 {x} 256 C {x + 104} 256 {x + 186} 330 {x + 186} 470 Z")]
    for sgn in (-1, 1):
        for dx, bottom in ((114, 704), (170, 636)):
            out.append(f'<rect x="{x + sgn * dx - 15}" y="440" width="30" height="{bottom - 440}" rx="15"/>')
    return out


def _headphones(x):
    band = (f"M {x - 176} 450 A 176 176 0 0 1 {x + 176} 450 L {x + 150} 450 A 150 150 0 0 0 {x - 150} 450 Z")
    return [_p(band)] + _both(lambda s: f'<rect x="{x + s * 146 - 34}" y="428" width="68" height="144" rx="26"/>')


def _dino(x):
    out = [_p(f"M {x - 92} 604 C {x - 112} 500 {x - 102} 400 {x - 40} 350 C {x} 320 {x + 60} 316 {x + 112} 334 "
              f"C {x + 172} 350 {x + 204} 380 {x + 208} 420 C {x + 210} 452 {x + 192} 472 {x + 160} 476 "
              f"L {x + 44} 484 C {x + 62} 524 {x + 52} 572 {x + 56} 604 Z")]
    for bx, by, tx, ty, ex, ey in ((-60, 372, -112, 300, -24, 336), (-98, 448, -166, 392, -78, 392),
                                   (-106, 532, -176, 490, -104, 470)):
        out.append(_p(f"M {x + bx} {by} L {x + tx} {ty} L {x + ex} {ey} Z"))
    return out


# name -> (group, draws the shared human head?, narrow child shoulders?, extra shapes[, cut-out shapes])
VARIANTS = {
    "swept":     ("people", True, False, _swept),
    "short":     ("people", True, False, lambda x: [_cap(x)]),
    "bald":      ("people", True, False, lambda x: []),
    "spiky":     ("people", True, False, _spiky),
    "curly":     ("people", True, False, _curly),
    "afro":      ("people", True, False, lambda x: [f'<circle cx="{x}" cy="404" r="166"/>']),
    "bob":       ("people", True, False, lambda x: [_p(
        f"M {x - 150} 560 C {x - 176} 400 {x - 110} 262 {x} 262 C {x + 110} 262 {x + 176} 400 {x + 150} 560 "
        f"C {x + 150} 590 {x + 130} 604 {x + 108} 600 L {x - 108} 600 C {x - 130} 604 {x - 150} 590 {x - 150} 560 Z")]),
    "bun":       ("people", True, False, lambda x: [_cap(x), f'<ellipse cx="{x}" cy="270" rx="54" ry="40"/>']),
    "spacebuns": ("people", True, False, lambda x: [_cap(x)] + _both(
        lambda s: f'<circle cx="{x + s * 96}" cy="294" r="46"/>')),
    "ponytail":  ("people", True, False, lambda x: [_cap(x), _p(
        f"M {x + 92} 300 C {x + 170} 288 {x + 216} 360 {x + 206} 452 C {x + 200} 522 {x + 182} 582 {x + 160} 618 "
        f"C {x + 166} 540 {x + 160} 470 {x + 126} 420 Z")]),
    "pigtails":  ("people", True, False, lambda x: [_cap(x)] + _both(lambda s: _p(
        f"M {x + s * 122} 410 C {x + s * 180} 424 {x + s * 194} 520 {x + s * 178} 612 "
        f"C {x + s * 172} 642 {x + s * 150} 650 {x + s * 142} 630 C {x + s * 152} 560 {x + s * 142} 500 {x + s * 116} 470 Z"))),
    "braids":    ("people", True, False, _braids),
    "cap":       ("people", True, False, lambda x: [
        _p(f"M {x - 126} 410 C {x - 130} 310 {x - 70} 262 {x} 262 C {x + 70} 262 {x + 130} 310 {x + 126} 410 Z"),
        f'<rect x="{x + 30}" y="376" width="196" height="34" rx="17"/>']),
    "beanie":    ("people", True, False, lambda x: [
        _p(f"M {x - 132} 424 C {x - 138} 320 {x - 78} 276 {x} 276 C {x + 78} 276 {x + 138} 320 {x + 132} 424 Z"),
        f'<circle cx="{x}" cy="264" r="28"/>']),
    "hat":       ("people", True, False, lambda x: [
        f'<ellipse cx="{x}" cy="376" rx="212" ry="30"/>',
        _p(f"M {x - 102} 376 C {x - 106} 292 {x - 70} 250 {x} 250 C {x + 70} 250 {x + 106} 292 {x + 102} 376 Z")]),
    "locs":      ("people", True, False, _locs),
    "turban":    ("people", True, False, lambda x: [_p(
        f"M {x - 142} 424 C {x - 176} 330 {x - 102} 244 {x} 240 C {x + 102} 244 {x + 176} 330 {x + 142} 424 "
        f"C {x + 80} 394 {x - 80} 394 {x - 142} 424 Z")], lambda x: [_p(
        f"M {x - 116} 386 C {x - 40} 334 {x + 40} 304 {x + 100} 264 L {x + 110} 280 "
        f"C {x + 50} 320 {x - 30} 350 {x - 106} 402 Z")]),
    "hijab":     ("people", True, False, lambda x: [_p(
        f"M {x} 250 C {x + 120} 250 {x + 160} 340 {x + 156} 450 C {x + 154} 530 {x + 132} 580 {x + 122} 612 "
        f"C {x + 150} 640 {x + 196} 668 {x + 224} 708 L {x - 224} 708 C {x - 196} 668 {x - 150} 640 {x - 122} 612 "
        f"C {x - 132} 580 {x - 154} 530 {x - 156} 450 C {x - 160} 340 {x - 120} 250 {x} 250 Z")],
        lambda x: [_ellipse_ring(x, 474, 106, 134, 20)]),
    "glasses":   ("people", True, False, _swept, lambda x: [
        f'<rect x="{x - 96}" y="440" width="82" height="60" rx="24"/>',
        f'<rect x="{x + 14}" y="440" width="82" height="60" rx="24"/>',
        f'<rect x="{x - 16}" y="456" width="32" height="12"/>',
        f'<rect x="{x - 130}" y="454" width="36" height="12"/>', f'<rect x="{x + 94}" y="454" width="36" height="12"/>']),
    "headphones": ("people", True, False, _headphones),
    "graduate":  ("people", True, False, lambda x: [_cap(x), _p(
        f"M {x - 178} 306 L {x} 250 L {x + 178} 306 L {x} 362 Z"),
        f'<rect x="{x + 132}" y="306" width="12" height="96" rx="6"/>', f'<circle cx="{x + 138}" cy="410" r="16"/>']),
    "cat":       ("fun", False, False, lambda x: [f'<ellipse cx="{x}" cy="474" rx="152" ry="130"/>'] + _both(
        lambda s: _p(f"M {x + s * 146} 430 L {x + s * 132} 262 L {x + s * 38} 356 Z"))),
    "bunny":     ("fun", False, False, lambda x: [f'<ellipse cx="{x}" cy="494" rx="126" ry="118"/>'] + _both(
        lambda s: f'<ellipse cx="{x + s * 58}" cy="336" rx="34" ry="94" '
                  f'transform="rotate({s * 12} {x + s * 58} 430)"/>')),
    "bear":      ("fun", False, False, lambda x: [f'<circle cx="{x}" cy="476" r="140"/>'] + _both(
        lambda s: f'<circle cx="{x + s * 108}" cy="352" r="52"/>')),
    "fox":       ("fun", False, False, lambda x: [_p(
        f"M {x} 644 C {x - 40} 624 {x - 150} 548 {x - 184} 474 L {x - 132} 446 C {x - 132} 384 {x - 80} 344 {x} 344 "
        f"C {x + 80} 344 {x + 132} 384 {x + 132} 446 L {x + 184} 474 C {x + 150} 548 {x + 40} 624 {x} 644 Z")] + _both(
        lambda s: _p(f"M {x + s * 138} 452 L {x + s * 154} 248 L {x + s * 34} 352 Z"))),
    "panda":     ("fun", False, False, lambda x: [f'<circle cx="{x}" cy="476" r="140"/>'] + _both(
        lambda s: f'<circle cx="{x + s * 108}" cy="352" r="52"/>'), lambda x: _both(
        lambda s: f'<ellipse cx="{x + s * 54}" cy="468" rx="30" ry="42" '
                  f'transform="rotate({s * -22} {x + s * 54} 468)"/>') + [f'<ellipse cx="{x}" cy="540" rx="22" ry="14"/>']),
    "frog":      ("fun", False, False, lambda x: [f'<ellipse cx="{x}" cy="506" rx="156" ry="112"/>'] + _both(
        lambda s: f'<circle cx="{x + s * 84}" cy="392" r="52"/>'), lambda x: _both(
        lambda s: f'<circle cx="{x + s * 84}" cy="388" r="20"/>')),
    "dinosaur":  ("fun", False, False, _dino, lambda x: [
        f'<circle cx="{x + 36}" cy="388" r="15"/>',
        _p(f"M {x + 212} 432 L {x + 84} 442 L {x + 84} 454 L {x + 208} 450 Z")]),
    "astronaut": ("fun", False, False, lambda x: [f'<circle cx="{x}" cy="444" r="170"/>',
                                                  f'<rect x="{x - 118}" y="596" width="236" height="44" rx="22"/>'],
                  lambda x: [f'<rect x="{x - 110}" y="376" width="220" height="132" rx="60"/>']),
    "robot":     ("fun", False, False, lambda x: [
        f'<rect x="{x - 132}" y="322" width="264" height="284" rx="40"/>',
        f'<rect x="{x - 8}" y="262" width="16" height="64"/>', f'<circle cx="{x}" cy="258" r="24"/>'] + _both(
        lambda s: f'<rect x="{x + s * 146 - 16}" y="426" width="32" height="76" rx="10"/>')),
    "alien":     ("fun", False, True, _alien),
    "party":     ("fun", True, False, lambda x: [_cap(x), _p(f"M {x + 20} 300 L {x + 168} 240 L {x + 128} 396 Z"),
                                                 f'<circle cx="{x + 172}" cy="238" r="20"/>']),
    "viking":    ("fun", True, False, lambda x: [_p(
        f"M {x - 130} 412 C {x - 134} 318 {x - 72} 272 {x} 272 C {x + 72} 272 {x + 134} 318 {x + 130} 412 Z")] + _both(
        lambda s: _p(f"M {x + s * 118} 366 C {x + s * 190} 356 {x + s * 216} 294 {x + s * 198} 238 "
                     f"C {x + s * 180} 292 {x + s * 152} 312 {x + s * 110} 318 Z"))),
}
BUSTS = list(VARIANTS)


def bust_paths(s):
    """The person in the frame. Everyone shares the same neck, shoulders and flat print-like base; people also
    share one head with ears, so only the hair or headwear changes. The frame itself never changes."""
    x = C + s.shift_x
    _, human_head, narrow, extras = VARIANTS[s.bust][:4]
    parts = []
    if human_head:
        parts.append(_p(f"M {x + 116} 470 C {x + 136} 466 {x + 142} 490 {x + 134} 516 "
                        f"C {x + 130} 534 {x + 122} 542 {x + 110} 542 "
                        f"C {x + 100} 592 {x + 60} 628 {x} 628 C {x - 60} 628 {x - 100} 592 {x - 110} 542 "
                        f"C {x - 122} 542 {x - 130} 534 {x - 134} 516 C {x - 142} 490 {x - 136} 466 {x - 116} 470 "
                        f"C {x - 120} 370 {x - 70} 296 {x} 296 C {x + 70} 296 {x + 120} 370 {x + 116} 470 Z"))
    w, n = (176, 44) if narrow else (232, 54)  # shoulder half-width, neck half-width
    parts.append(_p(f"M {x - n} 596 C {x - n} 640 {x - n - 12} 664 {x - n - 46} 676 "
                    f"C {x - w + 56} 694 {x - w + 14} 716 {x - w} 760 H {x + w} "
                    f"C {x + w - 14} 716 {x + w - 56} 694 {x + n + 46} 676 C {x + n + 12} 664 {x + n} 640 {x + n} 596 Z"))
    return parts + extras(x)


def cut_paths(s, paint):
    """Negative-space details (glasses, a visor, eye patches). Flat masters paint them in the field colour;
    finished icons use them as a mask so the lit field shows through."""
    entry = VARIANTS[s.bust]
    if len(entry) < 5:
        return []
    return [shape.replace("<path ", f'<path fill="{paint}" fill-rule="evenodd" stroke="none" ', 1)
            .replace("<ellipse ", f'<ellipse fill="{paint}" stroke="none" ', 1)
            .replace("<circle ", f'<circle fill="{paint}" stroke="none" ', 1)
            .replace("<rect ", f'<rect fill="{paint}" stroke="none" ', 1) for shape in entry[4](C + s.shift_x)]


def flat_svg(s, title):
    frame = "\n    ".join(f'<path d="{d}"/>' for d in frame_paths(s))
    bust = "\n    ".join(bust_paths(s))
    strand = "".join("\n  " + c for c in cut_paths(s, "#FFFFFF"))
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
    cut = "".join(cut_paths(s, "#000000"))
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


def grid(path, cells, cols=7):
    """Choose-your-icon overview: every variant at Home Screen size (180 px) with its 60 px render beside it."""
    pad, cw, ch = 48, 270, 250
    groups = []
    for name, group, files in cells:
        if not groups or groups[-1][0] != group:
            groups.append((group, []))
        groups[-1][1].append((name, files))
    height = 110 + sum(60 + ch * -(-len(items) // cols) for _, items in groups) + 20
    width = pad * 2 + cw * cols
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
           f'width="{width}" height="{height}" viewBox="0 0 {width} {height}" font-family="Helvetica, Arial, sans-serif">',
           f'<rect width="{width}" height="{height}" fill="#F2F2F7"/>',
           f'<text x="{pad}" y="62" font-size="34" font-weight="700" fill="#111">Calipic - choose-your-icon set</text>']
    y, n = 110, 0
    for group, items in groups:
        out.append(f'<text x="{pad}" y="{y + 30}" font-size="24" font-weight="700" fill="#111">{group}</text>')
        y += 60
        for i, (name, files) in enumerate(items):
            x, cy = pad + cw * (i % cols), y + ch * (i // cols)
            for px, dx, dy in ((180, 0, 0), (60, 196, 120)):
                n += 1
                rx = 0.2237 * px
                out.append(f'<clipPath id="g{n}"><rect x="{x + dx}" y="{cy + dy}" width="{px}" height="{px}" rx="{rx:.2f}"/></clipPath>')
                out.append(f'<image xlink:href="{files[px]}" x="{x + dx}" y="{cy + dy}" width="{px}" height="{px}" clip-path="url(#g{n})"/>')
            out.append(f'<text x="{x}" y="{cy + 208}" font-size="18" fill="#444">{name}</text>')
        y += ch * -(-len(items) // cols)
    out.append("</svg>")
    with open(path, "w") as fh:
        fh.write("\n".join(out))
    inkscape(path, path[:-4] + ".png", width)
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
    cells = []
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
        for px in (180, 60):
            files[px] = f"variants/v2-finished-{bust}-{px}.png"
            inkscape(paths[""], os.path.join(OUT, files[px]), px)
        cells.append((bust, VARIANTS[bust][0], files))
    grid(os.path.join(OUT, "sheet-variants.svg"), cells)
    print("built", master, small, OUT)


if __name__ == "__main__":
    main()
