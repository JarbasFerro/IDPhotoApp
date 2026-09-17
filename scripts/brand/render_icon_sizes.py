#!/usr/bin/env python3
"""SVG/metric generator behind scripts/brand/render-icon-sizes.sh (stdlib only).

Subcommands
  variants  write recoloured app-icon composites of the input icon SVG
  sheets    write size-strip and context-sheet SVGs (exported to PNG by the caller)
  metrics   decode the rendered PNGs and quantify small-size structure survival

The input icon is treated as a flat stand-in: geometry is never edited, only the
mark / field / field-stroke colours are substituted.
"""
import argparse
import os
import pathlib
import random
import re
import struct
import sys
import zlib

# --------------------------------------------------------------------------
# Provisional test palette (shared across the colour-evidence units).
# These are test values, NOT brand decisions (BD-033 stays open).
# --------------------------------------------------------------------------
CANDIDATES = {
    "A": {"name": "Deep blue", "light": "#1F3FA8", "dark": "#7C98F5"},
    "B": {"name": "Dark cyan / blue-teal", "light": "#0E6F7C", "dark": "#4FC3D1"},
    "C": {"name": "Graphite + cool accent", "light": "#5B7C99", "dark": "#9DB7CF",
          "ink_light": "#1C1F24", "ink_dark": "#F2F3F5"},
    "D": {"name": "Warm challenger (amber-ochre)", "light": "#B26A00", "dark": "#F0B55A"},
}
TREATMENTS = {
    1: "T1 accent mark / white field",
    2: "T2 white mark / accent field",
    3: "T3 dark-mode mark / #111214 field",
}
DARK_FIELD = "#111214"
SIZES = [1024, 180, 120, 87, 80, 60, 58, 40, 29]
STRIP_SIZES = [180, 120, 87, 80, 60, 58, 40, 29]
ENLARGE_SIZES = [87, 80, 60, 58, 40, 29]
IOS_RX = 0.2237  # iOS icon corner approximation, fraction of width
STAND_IN = "draft v0 stand-in"
FONT = "Helvetica Neue, Helvetica, Arial, sans-serif"


def colours(cand, treatment):
    """Return (mark, field) for a candidate/treatment."""
    c = CANDIDATES[cand]
    if treatment == 1:
        return (c.get("ink_light", c["light"]), "#FFFFFF")
    if treatment == 2:
        return ("#FFFFFF", c["light"])
    return (c.get("ink_dark", c["dark"]), DARK_FIELD)


# --------------------------------------------------------------------------
# Input icon handling
# --------------------------------------------------------------------------
class Icon:
    def __init__(self, path, mark_hex, field_hex, stroke_hex):
        with open(path, encoding="utf-8") as fh:
            src = fh.read()
        m = re.search(r"<svg\b[^>]*>", src)
        if not m:
            sys.exit(f"error: {path} has no <svg> root")
        vb = re.search(r'viewBox="([^"]+)"', m.group(0))
        if not vb:
            sys.exit(f"error: {path} root <svg> needs a viewBox")
        parts = [float(v) for v in vb.group(1).replace(",", " ").split()]
        if len(parts) != 4 or parts[2] <= 0 or parts[2] != parts[3]:
            sys.exit(f"error: {path} viewBox must be square, got '{vb.group(1)}'")
        self.vb = parts
        body = src[m.end():]
        end = body.rfind("</svg>")
        if end < 0:
            sys.exit(f"error: {path} has no closing </svg>")
        body = body[:end]
        body = re.sub(r"<!--.*?-->", "", body, flags=re.S)
        body = re.sub(r"<title\b.*?</title>", "", body, flags=re.S)
        body = re.sub(r"<desc\b.*?</desc>", "", body, flags=re.S)
        self.body = body.strip()
        self.mark_hex, self.field_hex, self.stroke_hex = mark_hex, field_hex, stroke_hex
        if len({mark_hex.lower(), field_hex.lower(), stroke_hex.lower()}) != 3:
            sys.exit("error: mark, field and stroke source colours must be three different "
                     "6-digit hex values")
        for hx in (mark_hex, field_hex, stroke_hex):
            if not re.fullmatch(r"#[0-9A-Fa-f]{6}", hx):
                sys.exit(f"error: source colour '{hx}' must be 6-digit hex (#RRGGBB)")
        self.ids = sorted(set(re.findall(r'\bid="([^"]+)"', self.body)), key=len, reverse=True)
        self._tile_n = 0
        for label, hx in (("mark", mark_hex), ("field", field_hex)):
            if not re.search(re.escape(hx), self.body, flags=re.I):
                sys.exit(f"error: {label} colour {hx} not found in {path}; "
                         f"set MARK_HEX / FIELD_HEX / STROKE_HEX for this icon")
        # Negative-space details (the hair strand) = stroked in the field colour.
        self.cutout_re = re.compile(
            r"<(path|line|polyline)\b[^>]*\bstroke=\"%s\"[^>]*/>" % re.escape(field_hex),
            flags=re.I | re.S)
        self.has_cutout = bool(self.cutout_re.search(self.body))

    def recolour(self, mark, field, without_cutout=False):
        body = self.cutout_re.sub("", self.body) if without_cutout else self.body
        table = {self.mark_hex.lower(): mark, self.field_hex.lower(): field,
                 self.stroke_hex.lower(): field}  # no keyline: iOS draws none
        pat = re.compile("(?:%s)(?![0-9A-Fa-f])" % "|".join(re.escape(k) for k in table),
                         flags=re.I)
        body = pat.sub(lambda mm: table[mm.group(0).lower()], body)
        # A sheet inlines many tiles: make ids (defs, clips, masks) unique per tile so
        # url(#id) references never resolve to another candidate's copy.
        self._tile_n += 1
        for ident in self.ids:
            new = f"t{self._tile_n}-{ident}"
            esc = re.escape(ident)
            body = re.sub(r'\bid="%s"' % esc, f'id="{new}"', body)
            body = re.sub(r'url\(#%s\)' % esc, f'url(#{new})', body)
            body = re.sub(r'href="#%s"' % esc, f'href="#{new}"', body)
        return body

    def tile(self, cand, treatment, x, y, size, keyline=None, without_cutout=False):
        """App-icon composite: full-bleed field in the iOS corner shape + the mark."""
        mark, field = colours(cand, treatment)
        rx = size * IOS_RX
        vb = " ".join(f"{v:g}" for v in self.vb)
        out = [f'<rect x="{x:g}" y="{y:g}" width="{size:g}" height="{size:g}" '
               f'rx="{rx:.3f}" fill="{field}"/>',
               f'<svg x="{x:g}" y="{y:g}" width="{size:g}" height="{size:g}" viewBox="{vb}">'
               f'{self.recolour(mark, field, without_cutout)}</svg>']
        if keyline:
            out.append(keyline_rect(x, y, size, keyline))
        return "".join(out)


def keyline_rect(x, y, size, keyline):
    colour, opacity = keyline
    return (f'<rect x="{x:g}" y="{y:g}" width="{size:g}" height="{size:g}" '
            f'rx="{size * IOS_RX:.3f}" fill="none" stroke="{colour}" '
            f'stroke-opacity="{opacity:g}" stroke-width="0.5"/>')


def svg_doc(w, h, scale, inner, bg=None):
    bgrect = f'<rect width="{w:g}" height="{h:g}" fill="{bg}"/>' if bg else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'xmlns:xlink="http://www.w3.org/1999/xlink" '
            f'width="{w * scale:g}" height="{h * scale:g}" viewBox="0 0 {w:g} {h:g}">'
            f'{bgrect}{inner}</svg>\n')


def text(x, y, s, size=11, fill="#1C1C1E", weight="400", anchor="start", opacity=1.0):
    s = s.replace("&", "&amp;").replace("<", "&lt;")
    return (f'<text x="{x:g}" y="{y:g}" font-family="{FONT}" font-size="{size:g}" '
            f'font-weight="{weight}" fill="{fill}" fill-opacity="{opacity:g}" '
            f'text-anchor="{anchor}">{s}</text>')


# --------------------------------------------------------------------------
# Neutral placeholder icons: generic glyphs in typical iOS icon colours.
# Drawn from scratch in a 60x60 space; deliberately not any real app's logo.
# --------------------------------------------------------------------------
W = "#FFFFFF"
PLACEHOLDERS = [
    ("Notes", "#FFFFFF",
     '<rect width="60" height="17" fill="#FFCC00"/>'
     '<g stroke="#C7C7CC" stroke-width="2.4" stroke-linecap="round">'
     '<path d="M13 28H47M13 37H47M13 46H36"/></g>'),
    ("Video", "#FF3B30", f'<path d="M23 17 L45 30 L23 43 Z" fill="{W}"/>'),
    ("Places", "#34C759",
     f'<path d="M30 49 C22 38 17 32 17 25 a13 13 0 0 1 26 0 C43 32 38 38 30 49 Z" fill="{W}"/>'
     '<circle cx="30" cy="25" r="5" fill="#34C759"/>'),
    ("Inbox", "#0A84FF",
     f'<rect x="12" y="18" width="36" height="25" rx="4" fill="{W}"/>'
     '<path d="M13 20 L30 33 L47 20" fill="none" stroke="#0A84FF" stroke-width="2.6"/>'),
    ("Timer", "#1C1C1E",
     f'<circle cx="30" cy="30" r="18" fill="{W}"/>'
     '<path d="M30 30V18M30 30L39 35" stroke="#1C1C1E" stroke-width="2.6" '
     'stroke-linecap="round" fill="none"/>'),
    ("Forecast", "#5AC8FA",
     '<circle cx="39" cy="23" r="9" fill="#FFD60A"/>'
     f'<g fill="{W}"><circle cx="23" cy="37" r="8"/><circle cx="33" cy="34" r="10"/>'
     '<circle cx="42" cy="38" r="7"/><rect x="23" y="37" width="19" height="8"/></g>'),
    ("Tasks", "#FFFFFF",
     '<g fill="none" stroke="#0A84FF" stroke-width="2.6"><circle cx="18" cy="21" r="4"/>'
     '<circle cx="18" cy="39" r="4"/></g><circle cx="18" cy="21" r="2" fill="#0A84FF"/>'
     '<path d="M28 21H46M28 39H46" stroke="#8E8E93" stroke-width="2.6" stroke-linecap="round"/>'),
    ("Budget", "#0B2545",
     f'<g fill="{W}"><rect x="15" y="33" width="7" height="12" rx="1.5"/>'
     '<rect x="26.5" y="25" width="7" height="20" rx="1.5"/>'
     '<rect x="38" y="16" width="7" height="29" rx="1.5"/></g>'),
    ("Market", "#FF9500",
     f'<path d="M16 24H44L41 47H19Z" fill="{W}"/>'
     f'<path d="M23 25V21a7 7 0 0 1 14 0V25" fill="none" stroke="{W}" stroke-width="2.6"/>'),
    ("Radio", "#FF2D55",
     f'<circle cx="24" cy="41" r="6" fill="{W}"/>'
     f'<path d="M30 41V17L43 14V22L30 25" fill="{W}"/>'),
    ("Reader", "#A2845E",
     f'<path d="M30 20C25 16 18 16 13 18V43C18 41 25 41 30 45C35 41 42 41 47 43V18'
     f'C42 16 35 16 30 20Z" fill="{W}"/>'
     '<path d="M30 20V45" stroke="#A2845E" stroke-width="2"/>'),
    # dock
    ("Calls", "#30D158",
     f'<rect x="21" y="12" width="18" height="36" rx="5" fill="{W}"/>'
     '<rect x="27" y="41" width="6" height="2.4" rx="1.2" fill="#30D158"/>'),
    ("Web", "#FFFFFF",
     '<circle cx="30" cy="30" r="18" fill="none" stroke="#0A84FF" stroke-width="2.8"/>'
     '<ellipse cx="30" cy="30" rx="8" ry="18" fill="none" stroke="#0A84FF" stroke-width="2.4"/>'
     '<path d="M12 30H48" stroke="#0A84FF" stroke-width="2.4"/>'),
    ("Chat", "#00A3A3",
     f'<path d="M14 18h32a4 4 0 0 1 4 4v16a4 4 0 0 1-4 4H28l-9 7v-7h-5a4 4 0 0 1-4-4V22'
     f'a4 4 0 0 1 4-4Z" fill="{W}"/>'),
    ("Setup", "#8E8E93",
     f'<circle cx="30" cy="30" r="15" fill="none" stroke="{W}" stroke-width="6" '
     'stroke-dasharray="5.9 5.9"/>'
     f'<circle cx="30" cy="30" r="12" fill="none" stroke="{W}" stroke-width="4"/>'),
]

_clip_counter = [0]


def placeholder(idx, x, y, size, keyline=None):
    name, field, glyph = PLACEHOLDERS[idx]
    _clip_counter[0] += 1
    cid = f"pc{_clip_counter[0]}"
    rx = size * IOS_RX
    k = size / 60.0
    out = (f'<clipPath id="{cid}"><rect x="{x:g}" y="{y:g}" width="{size:g}" height="{size:g}" '
           f'rx="{rx:.3f}"/></clipPath>'
           f'<g clip-path="url(#{cid})"><rect x="{x:g}" y="{y:g}" width="{size:g}" '
           f'height="{size:g}" fill="{field}"/>'
           f'<g transform="translate({x:g} {y:g}) scale({k:.5f})">{glyph}</g></g>')
    if keyline:
        out += keyline_rect(x, y, size, keyline)
    return out


# --------------------------------------------------------------------------
# Context cells (all coordinates in iOS points; sheets export at @3x)
# --------------------------------------------------------------------------
def wallpaper(kind, w, h):
    if kind == "light":
        return (f'<rect width="{w}" height="{h}" fill="#E9EDF3"/>'
                f'<circle cx="{w * 0.85:g}" cy="{h * 0.1:g}" r="{w * 0.6:g}" fill="#DCE3EC"/>'
                f'<circle cx="{w * 0.1:g}" cy="{h:g}" r="{w * 0.55:g}" fill="#F3F5F8"/>')
    if kind == "dark":
        return (f'<rect width="{w}" height="{h}" fill="#0A0C11"/>'
                f'<circle cx="{w * 0.85:g}" cy="{h * 0.1:g}" r="{w * 0.6:g}" fill="#141821"/>'
                f'<circle cx="{w * 0.1:g}" cy="{h:g}" r="{w * 0.55:g}" fill="#06070A"/>')
    rnd = random.Random(20260917)  # deterministic "busy" multi-colour wallpaper
    pal = ["#FF5E3A", "#FFB400", "#19B5A5", "#2D6BFF", "#F2438C", "#7BD13C",
           "#0B1F4B", "#FFE9C7", "#E8452C", "#12A4E0"]
    out = [f'<rect width="{w}" height="{h}" fill="#F26B3A"/>']
    for _ in range(46):
        cx, cy = rnd.uniform(0, w), rnd.uniform(0, h)
        r = rnd.uniform(14, 70)
        col = rnd.choice(pal)
        if rnd.random() < 0.5:
            out.append(f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{col}"/>')
        else:
            out.append(f'<rect x="{cx - r:.1f}" y="{cy - r:.1f}" width="{2 * r:.1f}" '
                       f'height="{1.3 * r:.1f}" fill="{col}" '
                       f'transform="rotate({rnd.uniform(0, 90):.0f} {cx:.1f} {cy:.1f})"/>')
    return "".join(out)


HOME_W, HOME_H = 393, 470


def cell_home(icon, cand, treatment, kind):
    """Top of an iPhone Home Screen: 3 rows x 4 (Calipic + 11 placeholders) + dock."""
    w, h = HOME_W, HOME_H
    fg = "#1C1C1E" if kind == "light" else "#FFFFFF"
    out = [wallpaper(kind, w, h)]
    out.append(text(44, 34, "9:41", 16, fg, "600"))
    out.append(f'<rect x="{w - 62}" y="22" width="25" height="12" rx="3.5" fill="none" '
               f'stroke="{fg}" stroke-opacity="0.5"/>'
               f'<rect x="{w - 60}" y="24" width="18" height="8" rx="2" fill="{fg}"/>')
    size, left, gap, top, pitch = 60, 27, 33, 72, 96
    order = list(range(11))
    order.insert(5, None)  # Calipic sits mid-grid, fully surrounded by neighbours
    for i, p in enumerate(order):
        x = left + (i % 4) * (size + gap)
        y = top + (i // 4) * pitch
        if p is None:
            out.append(icon.tile(cand, treatment, x, y, size))
            label = "Calipic"
        else:
            out.append(placeholder(p, x, y, size))
            label = PLACEHOLDERS[p][0]
        if kind != "light":  # iOS label legibility shadow
            out.append(text(x + size / 2, y + size + 15.6, label, 11.5, "#000000", "500",
                            "middle", 0.35))
        out.append(text(x + size / 2, y + size + 15, label, 11.5, fg, "500", "middle"))
    dock_y = h - 96
    dock_fill = "#FFFFFF" if kind != "dark" else "#3A3A3C"
    out.append(f'<rect x="12" y="{dock_y}" width="{w - 24}" height="84" rx="30" '
               f'fill="{dock_fill}" fill-opacity="0.38"/>')
    for j in range(4):
        out.append(placeholder(11 + j, left + j * (size + gap), dock_y + 12, size))
    return "".join(out)


STORE_W, STORE_H = 393, 400


def cell_store(icon, cand, treatment, dark):
    w, h = STORE_W, STORE_H
    bg, fg, sub = ("#000000", "#FFFFFF", "#98989F") if dark else ("#FFFFFF", "#000000", "#8A8A8E")
    pill, shot, line = ("#1C1C1E", "#2C2C2E", "#38383A") if dark else ("#EEEEF0", "#E5E5EA", "#D1D1D6")
    key = ("#FFFFFF", 0.2) if dark else ("#000000", 0.17)
    out = [f'<rect width="{w}" height="{h}" fill="{bg}"/>',
           f'<rect x="16" y="14" width="{w - 32}" height="36" rx="10" fill="{pill}"/>',
           f'<circle cx="33" cy="31" r="5.5" fill="none" stroke="{sub}" stroke-width="1.6"/>',
           f'<path d="M37 35L41 39" stroke="{sub}" stroke-width="1.6" stroke-linecap="round"/>',
           text(48, 37, "id photo", 16, fg)]

    def row(y, tile_svg, title, subtitle):
        r = [tile_svg, text(88, y + 20, title, 15.5, fg, "600"),
             text(88, y + 38, subtitle, 12.5, sub),
             f'<rect x="{w - 90}" y="{y + 15}" width="74" height="30" rx="15" fill="{pill}"/>',
             text(w - 53, y + 35.5, "GET", 14.5, "#0A84FF", "700", "middle")]
        for k in range(3):
            r.append(f'<rect x="{16 + k * 123}" y="{y + 74}" width="115" height="120" '
                     f'rx="12" fill="{shot}"/>')
        return "".join(r)

    out.append(row(66, icon.tile(cand, treatment, 16, 66, 60, keyline=key),
                   "Calipic — ID Photos", "Placeholder subtitle copy"))
    out.append(f'<path d="M16 276H{w - 16}" stroke="{line}" stroke-width="0.5"/>')
    out.append(row(292, placeholder(3, 16, 292, 60, keyline=key),
                   "Competitor placeholder", "Generic neighbouring result"))
    return "".join(out)


LIST_W, LIST_H = 360, 486


def cell_lists(icon, cand, treatment, dark):
    """Settings-style grouped list (29pt icons) + Spotlight results (40pt icons)."""
    w, h = LIST_W, LIST_H
    bg, card, fg, sub, line = (("#000000", "#1C1C1E", "#FFFFFF", "#98989F", "#38383A") if dark
                               else ("#F2F2F7", "#FFFFFF", "#000000", "#8A8A8E", "#D1D1D6"))
    key = ("#FFFFFF", 0.2) if dark else ("#000000", 0.17)
    out = [f'<rect width="{w}" height="{h}" fill="{bg}"/>',
           text(16, 28, "SETTINGS LIST — 29 pt", 11, sub, "600")]
    rows = [(p, PLACEHOLDERS[p][0] if p is not None else "Calipic") for p in (4, 8, None, 3)]
    top, rh = 38, 44
    out.append(f'<rect x="16" y="{top}" width="{w - 32}" height="{rh * len(rows)}" rx="12" '
               f'fill="{card}"/>')
    for i, (p, label) in enumerate(rows):
        y = top + i * rh
        iy = y + (rh - 29) / 2
        out.append(icon.tile(cand, treatment, 32, iy, 29, keyline=key) if p is None
                   else placeholder(p, 32, iy, 29, keyline=key))
        out.append(text(75, y + 27.5, label, 16.5, fg))
        out.append(f'<path d="M{w - 40} {y + 16}l6 6l-6 6" fill="none" stroke="{sub}" '
                   f'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>')
        if i:
            out.append(f'<path d="M75 {y}H{w - 16}" stroke="{line}" stroke-width="0.5"/>')
    sy = top + rh * len(rows) + 30
    out.append(text(16, sy, "SPOTLIGHT — 40 pt", 11, sub, "600"))
    pill = "#1C1C1E" if dark else "#E3E3E8"
    out.append(f'<rect x="16" y="{sy + 10}" width="{w - 32}" height="36" rx="18" fill="{pill}"/>')
    out.append(f'<text x="34" y="{sy + 33.5:g}" font-family="{FONT}" font-size="16.5" '
               f'fill="{fg}">cali<tspan fill="{sub}">pic — Open</tspan></text>')
    ry = sy + 58
    hits = [(p, PLACEHOLDERS[p][0] if p is not None else "Calipic", "App") for p in (None, 9, 2)]
    out.append(f'<rect x="16" y="{ry}" width="{w - 32}" height="{56 * len(hits)}" rx="14" '
               f'fill="{card}"/>')
    for i, (p, label, kind) in enumerate(hits):
        y = ry + i * 56
        out.append(icon.tile(cand, treatment, 28, y + 8, 40, keyline=key) if p is None
                   else placeholder(p, 28, y + 8, 40, keyline=key))
        out.append(text(80, y + 26, label, 16.5, fg, "500"))
        out.append(text(80, y + 43, kind, 12.5, sub))
        if i:
            out.append(f'<path d="M80 {y}H{w - 16}" stroke="{line}" stroke-width="0.5"/>')
    return "".join(out)


def matrix_sheet(title, note, cell_w, cell_h, cell_fn, src_name):
    """Columns = candidates A-D, rows = treatments T1-T3."""
    pad, gap, label_w, head_h = 28, 24, 118, 116
    cands = list(CANDIDATES)
    w = pad * 2 + label_w + len(cands) * cell_w + (len(cands) - 1) * gap
    h = pad * 2 + head_h + len(TREATMENTS) * cell_h + (len(TREATMENTS) - 1) * gap
    out = [text(pad, pad + 24, f"Calipic — {title}", 24, "#111111", "700"),
           text(pad, pad + 48, f"Icon: {STAND_IN} ({src_name}) — flat recolour, geometry "
                "unchanged. Provisional test palette, not a colour decision (BD-033 open).",
                13, "#444444"),
           text(pad, pad + 67, note, 13, "#444444")]
    for ci, cand in enumerate(cands):
        x = pad + label_w + ci * (cell_w + gap)
        c = CANDIDATES[cand]
        out.append(text(x, pad + head_h - 28, f"{cand} — {c['name']}", 14, "#111111", "600"))
        out.append(text(x, pad + head_h - 11, f"light {c['light']} / dark {c['dark']}"
                        + (f" / ink {c['ink_light']} / {c['ink_dark']}" if "ink_light" in c else ""),
                        12, "#444444"))
        for ti, tr in enumerate(TREATMENTS):
            y = pad + head_h + ti * (cell_h + gap)
            _clip_counter[0] += 1
            cid = f"cell{_clip_counter[0]}"
            out.append(f'<clipPath id="{cid}"><rect width="{cell_w}" height="{cell_h}" rx="22"/>'
                       f'</clipPath><g transform="translate({x} {y})" clip-path="url(#{cid})">'
                       f'{cell_fn(cand, tr)}</g>')
    for ti, tr in enumerate(TREATMENTS):
        y = pad + head_h + ti * (cell_h + gap)
        words = TREATMENTS[tr].split(" ", 1)
        out.append(text(pad, y + 22, words[0], 18, "#111111", "700"))
        for li, chunk in enumerate(words[1].split(" / ")):
            out.append(text(pad, y + 42 + li * 16, chunk, 12, "#444444"))
    return svg_doc(w, h, 3, "".join(out), bg="#F4F4F6")


def file_uri(path):
    return pathlib.Path(path).resolve().as_uri().replace("&", "&amp;")


def strip_sheet(treatment, png_dir, src_name):
    """Per treatment: true-size row, smooth-enlarged row, pixel-grid-enlarged row."""
    dark = treatment == 3
    bg, fg, sub = ("#2B2D31", "#FFFFFF", "#B8BBC2") if dark else ("#E6E7EA", "#111111", "#444444")
    pad, gap, big = 32, 20, 180
    row_true = 180 + 26
    block_h = row_true + (big + 26) * 2 + 44
    true_w = sum(STRIP_SIZES) + gap * (len(STRIP_SIZES) - 1)
    w = pad * 2 + max(true_w, len(ENLARGE_SIZES) * (big + gap) - gap)
    h = pad * 2 + 84 + block_h * len(CANDIDATES)
    out = [text(pad, pad + 22, f"Calipic — icon size strip — {TREATMENTS[treatment]}",
                22, fg, "700"),
           text(pad, pad + 44, f"Icon: {STAND_IN} ({src_name}). Row 1: true rasterisation at "
                "1:1. Row 2: the same small PNGs enlarged to 180 px with smooth interpolation. "
                "Row 3: the same PNGs enlarged showing the pixel grid.", 12.5, sub),
           text(pad, pad + 61, "Provisional test palette, not a colour decision (BD-033 open). "
                "Judge colour + small-size structure, not drawing polish.", 12.5, sub)]
    for ci, cand in enumerate(CANDIDATES):
        y0 = pad + 84 + ci * block_h
        mark, field = colours(cand, treatment)
        out.append(text(pad, y0 + 14, f"{cand} — {CANDIDATES[cand]['name']}   mark {mark} "
                        f"on field {field}", 14, fg, "600"))
        x = pad
        for s in STRIP_SIZES:
            href = file_uri(os.path.join(png_dir, f"{cand}-t{treatment}-{s}.png"))
            yy = y0 + 24 + (180 - s)
            out.append(f'<image x="{x}" y="{yy}" width="{s}" height="{s}" xlink:href="{href}" '
                       f'href="{href}" style="image-rendering:pixelated"/>')
            out.append(text(x + s / 2, y0 + 24 + 180 + 15, f"{s}", 11, sub, "400", "middle"))
            x += s + gap
        for ri, mode in enumerate(("optimizeQuality", "pixelated")):
            yy = y0 + 24 + row_true + ri * (big + 26)
            x = pad
            for s in ENLARGE_SIZES:
                href = file_uri(os.path.join(png_dir, f"{cand}-t{treatment}-{s}.png"))
                out.append(f'<image x="{x}" y="{yy}" width="{big}" height="{big}" '
                           f'xlink:href="{href}" href="{href}" '
                           f'style="image-rendering:{mode}"/>')
                tag = "smooth" if ri == 0 else "pixel grid"
                out.append(text(x + big / 2, yy + big + 15, f"{s} px → 180 ({tag})", 11,
                                sub, "400", "middle"))
                x += big + gap
    return svg_doc(w, h, 1, "".join(out), bg=bg)


# --------------------------------------------------------------------------
# PNG decoding + metrics
# --------------------------------------------------------------------------
def read_png(path):
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: not a PNG")
    pos, idat, hdr = 8, b"", None
    while pos < len(data):
        ln, typ = struct.unpack(">I4s", data[pos:pos + 8])
        chunk = data[pos + 8:pos + 8 + ln]
        if typ == b"IHDR":
            hdr = struct.unpack(">IIBBBBB", chunk)
        elif typ == b"IDAT":
            idat += chunk
        pos += 12 + ln
    w, h, depth, ctype, _, _, interlace = hdr
    if depth != 8 or ctype not in (2, 6) or interlace:
        raise ValueError(f"{path}: unsupported PNG (depth {depth}, type {ctype})")
    bpp = 4 if ctype == 6 else 3
    raw = zlib.decompress(idat)
    stride = w * bpp
    rows, prev = [], bytearray(stride)
    for r in range(h):
        ft = raw[r * (stride + 1)]
        line = bytearray(raw[r * (stride + 1) + 1:(r + 1) * (stride + 1)])
        for i in (range(stride) if ft else ()):
            a = line[i - bpp] if i >= bpp else 0
            b = prev[i]
            c = prev[i - bpp] if i >= bpp else 0
            if ft == 1:
                line[i] = (line[i] + a) & 255
            elif ft == 2:
                line[i] = (line[i] + b) & 255
            elif ft == 3:
                line[i] = (line[i] + ((a + b) >> 1)) & 255
            elif ft == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 255
        rows.append(line)
        prev = line
    return w, h, bpp, rows


def hex_rgb(hx):
    return tuple(int(hx[i:i + 2], 16) for i in (1, 3, 5))


def mix_fraction(px, mark, field):
    """Project a pixel onto the mark->field line: 0 = pure mark, 1 = pure field."""
    num = sum((px[i] - mark[i]) * (field[i] - mark[i]) for i in range(3))
    den = sum((field[i] - mark[i]) ** 2 for i in range(3))
    return num / den


def sample(img, fx, fy, mark, field):
    w, h, bpp, rows = img
    x, y = fx * w - 0.5, fy * h - 0.5
    x0, y0 = max(0, min(w - 2, int(x))), max(0, min(h - 2, int(y)))
    tx, ty = min(1.0, max(0.0, x - x0)), min(1.0, max(0.0, y - y0))
    acc = 0.0
    for dy, wy in ((0, 1 - ty), (1, ty)):
        for dx, wx in ((0, 1 - tx), (1, tx)):
            o = (x0 + dx) * bpp
            acc += wx * wy * mix_fraction(rows[y0 + dy][o:o + 3], mark, field)
    return acc


def gap_openness(img, fx, fy, axis, mark, field):
    """Max field fraction within +/-1 px of the probe, scanned along the stroke axis.

    Scanning (instead of one point sample) removes the dependence on where the
    pixel grid happens to fall relative to a sub-pixel gap.
    """
    w, h = img[0], img[1]
    best = 0.0
    for k in range(-8, 9):
        d = k / 8.0
        x = fx + (d / w if axis == "h" else 0.0)
        y = fy + (d / h if axis == "v" else 0.0)
        best = max(best, sample(img, x, y, mark, field))
    return min(1.0, max(0.0, best))


def cmd_metrics(args):
    icon = load_icon(args)
    viewbox = icon.vb[2]
    probes = []
    for spec in args.probe:
        try:
            name, xs, ys, axis = spec.split(":")
            if axis not in ("h", "v"):
                raise ValueError(axis)
            probes.append((name, float(xs), float(ys), axis))
        except ValueError:
            sys.exit(f"error: bad probe '{spec}', want name:x:y:h|v")
    lines = ["# Calipic icon small-size structure metrics -- " + STAND_IN,
             "# input: " + os.path.basename(args.input),
             "# openness_*: 0 = gap fully closed (reads as mark colour), 1 = fully open "
             "(reads as field colour); max bilinear sample within +/-1 px of the gap centre, "
             "scanned along the stroke.",
             "# strand_peak: strongest pixel change the negative-space strand causes, as a "
             "fraction of full mark/field contrast. strand_px: nominal strand width in px.",
             "\t".join(["candidate", "treatment", "size_px"] +
                       [f"openness_{p[0]}" for p in probes] +
                       ["strand_peak", "strand_mean_top5", "strand_px", "frame_stroke_px"])]
    for cand in CANDIDATES:
        for tr in TREATMENTS:
            mark, field = (hex_rgb(c) for c in colours(cand, tr))
            for s in SIZES:
                img = read_png(os.path.join(args.png_dir, f"{cand}-t{tr}-{s}.png"))
                vals = [f"{gap_openness(img, px, py, ax, mark, field):.2f}"
                        for _, px, py, ax in probes]
                peak = top5 = "n/a"
                ns_path = os.path.join(args.nostrand_dir, f"{cand}-t{tr}-{s}.png")
                if os.path.exists(ns_path):
                    ns = read_png(ns_path)
                    diffs = []
                    w, h, bpp, rows = img
                    for yy in range(h):
                        ra, rb = rows[yy], ns[3][yy]
                        if ra == rb:
                            continue
                        for xx in range(w):
                            o = xx * bpp
                            if ra[o:o + 3] != rb[o:o + 3]:
                                diffs.append(abs(mix_fraction(ra[o:o + 3], mark, field) -
                                                 mix_fraction(rb[o:o + 3], mark, field)))
                    diffs.sort(reverse=True)
                    n5 = max(1, len(diffs) // 20)
                    peak = f"{diffs[0]:.2f}" if diffs else "0.00"
                    top5 = f"{sum(diffs[:n5]) / n5:.2f}" if diffs else "0.00"
                lines.append("\t".join([cand, f"T{tr}", str(s)] + vals + [
                    peak, top5, f"{args.strand_width * s / viewbox:.2f}",
                    f"{args.frame_width * s / viewbox:.2f}"]))
    with open(args.out, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")


# --------------------------------------------------------------------------
def load_icon(args):
    return Icon(args.input, args.mark_hex, args.field_hex, args.stroke_hex)


def cmd_variants(args):
    icon = load_icon(args)
    size = icon.vb[2]
    for cand in CANDIDATES:
        for tr in TREATMENTS:
            for without, d in ((False, args.out), (True, args.nostrand_out)):
                if without and not icon.has_cutout:
                    continue
                mark, field = colours(cand, tr)
                inner = (f'<title>Calipic icon {STAND_IN} — candidate {cand} '
                         f'({CANDIDATES[cand]["name"]}), {TREATMENTS[tr]}; mark {mark}, '
                         f'field {field}. Provisional test colour, not a decision.</title>'
                         + icon.tile(cand, tr, 0, 0, size, without_cutout=without))
                with open(os.path.join(d, f"{cand}-t{tr}.svg"), "w", encoding="utf-8") as fh:
                    fh.write(svg_doc(size, size, 1, inner))
    if not icon.has_cutout:
        print("note: no field-coloured stroked cutout found; strand metrics will be n/a",
              file=sys.stderr)


def cmd_sheets(args):
    icon = load_icon(args)
    name = os.path.basename(args.input)
    sheets = {}
    for kind, desc in (("light", "light wallpaper"), ("dark", "dark wallpaper"),
                       ("busy", "visually busy multi-colour wallpaper")):
        sheets[f"context-home-{kind}"] = matrix_sheet(
            f"Home Screen context, {desc} (@3x, 60 pt icon = 180 px)",
            "Neighbour icons are self-drawn neutral placeholders in typical iOS icon colours, "
            "not real apps. Placeholders are not re-tinted in the T3 row.",
            HOME_W, HOME_H, lambda c, t, k=kind: cell_home(icon, c, t, k), name)
    for dark in (False, True):
        ap = "dark" if dark else "light"
        sheets[f"context-appstore-{ap}"] = matrix_sheet(
            f"App Store search-result mock, {ap} appearance (@3x, 60 pt icon = 180 px)",
            "All copy and screenshots are placeholders. The App Store shows the default icon "
            "in both appearances; the T3 row is included for completeness only.",
            STORE_W, STORE_H, lambda c, t, d=dark: cell_store(icon, c, t, d), name)
        sheets[f"context-lists-{ap}"] = matrix_sheet(
            f"Settings list (29 pt = 87 px) + Spotlight (40 pt = 120 px), {ap} appearance (@3x)",
            "A 0.5 pt keyline is drawn on every icon in list contexts, as iOS does.",
            LIST_W, LIST_H, lambda c, t, d=dark: cell_lists(icon, c, t, d), name)
    for tr in TREATMENTS:
        sheets[f"strip-t{tr}"] = strip_sheet(tr, os.path.abspath(args.png_dir), name)
    for key, svg in sheets.items():
        with open(os.path.join(args.out, key + ".svg"), "w", encoding="utf-8") as fh:
            fh.write(svg)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="cmd", required=True)

    def common(p):
        p.add_argument("--input", required=True)
        p.add_argument("--mark-hex", default="#111111")
        p.add_argument("--field-hex", default="#FFFFFF")
        p.add_argument("--stroke-hex", default="#D9D9D9")

    p = sub.add_parser("variants"); common(p)
    p.add_argument("--out", required=True)
    p.add_argument("--nostrand-out", required=True)
    p.set_defaults(fn=cmd_variants)
    p = sub.add_parser("sheets"); common(p)
    p.add_argument("--out", required=True)
    p.add_argument("--png-dir", required=True)
    p.set_defaults(fn=cmd_sheets)
    p = sub.add_parser("metrics"); common(p)
    p.add_argument("--png-dir", required=True)
    p.add_argument("--nostrand-dir", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--probe", action="append", default=[])
    p.add_argument("--strand-width", type=float, default=12)
    p.add_argument("--frame-width", type=float, default=72)
    p.set_defaults(fn=cmd_metrics)
    p = sub.add_parser("sizes")
    p.set_defaults(fn=lambda a: print(" ".join(str(s) for s in SIZES)))
    p = sub.add_parser("ids")
    p.set_defaults(fn=lambda a: print(" ".join(f"{c}-t{t}" for c in CANDIDATES for t in TREATMENTS)))
    args = ap.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
