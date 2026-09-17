#!/bin/bash
# Renders the controlled colour matrix for the Calipic icon (brand handoff 06, step 1).
#
# The icon geometry is never touched: each variant is the input SVG with only three colour tokens
# substituted (mark #111111, field + hair-strand cutout #FFFFFF, field hairline #D9D9D9).
# The input defaults to the flat "draft v0 stand-in"; pass a refined icon to re-run the same matrix:
#
#   scripts/brand/render-color-matrix.sh                       # draft v0 -> docs/brand/prototypes/color-matrix
#   scripts/brand/render-color-matrix.sh path/to/icon.svg      # other icon, same output dir
#   scripts/brand/render-color-matrix.sh path/to/icon.svg out  # other icon, other output dir
#   CALIPIC_ICON_LABEL="refined v1" scripts/brand/render-color-matrix.sh path/to/icon.svg
#
# The input must keep the same colour tokens (#111111 mark, #FFFFFF field/cutout; #D9D9D9 optional),
# spelled exactly like that; any other paint is left unchanged and reported as a warning.
# Output: 12 SVG + 12 PNG (1024 px), two contact sheets (SVG + PNG), contrast.tsv. Idempotent:
# previous outputs of this script are removed first. Palette values are provisional test values,
# not brand decisions (BD-033 remains open).
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
input="${1:-$repo_root/docs/brand/assets/calipic-icon-draft-v0.svg}"
out_dir="${2:-$repo_root/docs/brand/prototypes/color-matrix}"
label="${CALIPIC_ICON_LABEL:-draft v0 stand-in}"
inkscape_bin="${INKSCAPE:-$(command -v inkscape || echo /opt/homebrew/bin/inkscape)}"

if [[ ! -f "$input" ]]; then echo "error: input SVG not found: $input" >&2; exit 2; fi
if [[ ! -x "$inkscape_bin" ]]; then echo "error: inkscape not found (set INKSCAPE=/path/to/inkscape)" >&2; exit 2; fi

mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"

# The generator removes this script's previous outputs (exact file names only), writes the SVGs and
# contrast.tsv, and prints the 12 variant base names on stdout.
variant_names="$(python3 - "$input" "$out_dir" "$label" <<'PY'
import os
import re
import sys
from xml.sax.saxutils import escape

src_path, out_dir, label = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src_path, encoding="utf-8") as fh:
    src = fh.read()

MARK, FIELD, HAIRLINE = "#111111", "#FFFFFF", "#D9D9D9"
DARK_FIELD = "#111214"
DARK_HAIRLINE = "#2C2E33"  # keeps the dark field edge visible on a black page

# Provisional test values, not decisions. C uses ink for the mark; its accent is the treatment-2 field.
CANDIDATES = [
    # id, slug, name (one entry per sheet label line), light mark, accent field, mark on accent field, dark mark
    ("A", "deep-blue", ("Deep blue",), "#1F3FA8", "#1F3FA8", "#FFFFFF", "#7C98F5"),
    ("B", "dark-cyan", ("Dark cyan /", "blue-teal"), "#0E6F7C", "#0E6F7C", "#FFFFFF", "#4FC3D1"),
    ("C", "graphite", ("Graphite +", "cool accent"), "#1C1F24", "#5B7C99", "#1C1F24", "#F2F3F5"),
    ("D", "warm-ochre", ("Warm challenger", "(amber-ochre)"), "#B26A00", "#B26A00", "#FFFFFF", "#F0B55A"),
]
TREATMENTS = [
    # id, slug, column header, short column header for the compact sheet
    (1, "mark-on-white", "1 - accent mark on white field", "1 - mark on white"),
    (2, "mark-on-accent", "2 - white mark on accent field (C: ink mark)", "2 - mark on accent"),
    (3, "dark-mode", "3 - dark-mode field", "3 - dark mode"),
]
SHEETS = ("contact-sheet-large", "contact-sheet-120px")

names = ["%s%d-%s-%s" % (c[0], t[0], c[1], t[1]) for c in CANDIDATES for t in TREATMENTS]
for stale in [n + ext for n in names + list(SHEETS) for ext in (".svg", ".png")] + ["contrast.tsv"]:
    try:
        os.remove(os.path.join(out_dir, stale))
    except FileNotFoundError:
        pass

for token, what in ((MARK, "mark"), (FIELD, "field/cutout")):
    if not re.search(re.escape(token), src, re.I):
        sys.exit("error: input SVG has no %s colour token %s; cannot recolour it" % (what, token))
if not re.search(re.escape(HAIRLINE), src, re.I):
    print("note: input has no %s field hairline; skipping hairline adjustment" % HAIRLINE, file=sys.stderr)

# Anything painted outside the three tokens is left as-is; say so instead of hiding it.
known = {MARK.lower(), FIELD.lower(), HAIRLINE.lower(), "none", "currentcolor", "inherit"}
without_comments = re.sub(r"<!--.*?-->", "", src, flags=re.S)
paints = re.findall(r"""(?:fill|stroke|stop-color|flood-color)\s*[:=]\s*["']?\s*(url\([^)]*\)|rgba?\([^)]*\)|[#\w]+)""", without_comments)
others = sorted({p for p in paints if p.lower() not in known and not p.startswith("url(")})
if others:
    print("warning: paints outside the colour tokens stay unchanged in every variant: %s" % ", ".join(others), file=sys.stderr)

m = re.search(r'viewBox\s*=\s*"([^"]+)"', src)
if not m:
    sys.exit("error: input SVG has no viewBox")
view_box = m.group(1)
ROOT_RE = re.compile(r"<svg\b([^>]*)>(.*)</svg\s*>", re.S)
if not ROOT_RE.search(src):
    sys.exit("error: input is not a single <svg> document")
# Root attributes the nested copies must not inherit (placement, ids, a11y wiring of the standalone file).
DROP_ROOT_ATTRS = re.compile(r"""\s(?:x|y|width|height|viewBox|id|role|aria-[\w-]+)\s*=\s*("[^"]*"|'[^']*')""")


def recolour(text, mark, field, hairline):
    """Single-pass substitution so a mark recoloured to white is not re-mapped as field."""
    table = {MARK.lower(): mark, FIELD.lower(): field, HAIRLINE.lower(): hairline}
    pattern = "|".join(re.escape(k) for k in table)
    return re.sub(pattern, lambda mo: table[mo.group(0).lower()], text, flags=re.I)


def inline_copy(doc, cell):
    """Root attributes + body of a recoloured document, safe to repeat inside one sheet."""
    root_attrs, body = ROOT_RE.search(doc).groups()
    root_attrs = DROP_ROOT_ATTRS.sub("", " " + root_attrs.strip())
    body = re.sub(r"<title\b.*?</title>|<desc\b.*?</desc>|<!--.*?-->", "", body, flags=re.S)
    # Namespace ids per cell so gradients/clips/filters of a refined icon resolve within their own copy.
    body = re.sub(r'\bid\s*=\s*"([^"]+)"', lambda mo: 'id="%s-%s"' % (cell, mo.group(1)), body)
    body = re.sub(r"""url\(\s*['"]?#([^)'"]+)['"]?\s*\)""", lambda mo: "url(#%s-%s)" % (cell, mo.group(1)), body)
    body = re.sub(r'\bhref\s*=\s*"#([^"]+)"', lambda mo: 'href="#%s-%s"' % (cell, mo.group(1)), body)
    return root_attrs, body


def luminance(hex_colour):
    chans = [int(hex_colour[i:i + 2], 16) / 255.0 for i in (1, 3, 5)]
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in chans]
    return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]


def contrast(a, b):
    la, lb = luminance(a), luminance(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


variants = []  # (cell id, name lines, treatment description, mark, field, (root attrs, inner body))
for cid, slug, name, light_mark, accent_field, on_accent_mark, dark_mark in CANDIDATES:
    for tid, tslug, _, _ in TREATMENTS:
        if tid == 1:
            mark, field, hairline = light_mark, "#FFFFFF", HAIRLINE
        elif tid == 2:
            mark, field, hairline = on_accent_mark, accent_field, accent_field
        else:
            mark, field, hairline = dark_mark, DARK_FIELD, DARK_HAIRLINE
        cell = "%s%d" % (cid, tid)
        mark_kind = "ink" if cid == "C" else ("white" if tid == 2 else "accent")
        tdesc = "%s mark on %s field" % (mark_kind, ("white", "accent", "dark-mode")[tid - 1])
        note = "Calipic colour matrix %s: %s, treatment %d (%s). %s: colour test only, geometry unchanged, not a final icon. mark %s, field %s." % (
            cell, " ".join(name), tid, tdesc, label, mark, field)
        note = "<!-- %s -->" % re.sub(r"-{2,}", "-", note).rstrip("-")  # "--" is illegal inside XML comments
        recoloured = recolour(src, mark, field, hairline)
        doc = re.sub(r"(<svg\b[^>]*>)", lambda mo: mo.group(1) + "\n  " + note, recoloured, count=1)
        with open(os.path.join(out_dir, "%s-%s-%s.svg" % (cell, slug, tslug)), "w", encoding="utf-8") as fh:
            fh.write(doc)
        variants.append((cell, name, tdesc, mark, field, inline_copy(recoloured, cell)))

with open(os.path.join(out_dir, "contrast.tsv"), "w", encoding="utf-8") as fh:
    fh.write("cell\tcandidate\ttreatment\tmark\tfield\tmark_vs_field_contrast\n")
    for cell, name, tdesc, mark, field, _ in variants:
        fh.write("%s\t%s\t%s\t%s\t%s\t%.2f\n" % (cell, " ".join(name), tdesc, mark, field, contrast(mark, field)))


def sheet(path, icon, gap, left, top, footer, font, page_pad, compact=False):
    """4 rows (candidates) x 3 columns (treatments). Column 3 sits on a black panel (dark Home Screen)."""
    caption = font + 8
    cell_w, cell_h = icon + gap, icon + gap + caption
    width = left + 3 * cell_w + page_pad
    height = top + 4 * cell_h + footer
    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" font-family="Helvetica Neue, Helvetica, Arial, sans-serif">' % (width, height, width, height),
        '<rect width="%d" height="%d" fill="#F2F2F7"/>' % (width, height),
        '<rect x="%d" y="%d" width="%d" height="%d" fill="#000000"/>' % (left + 2 * cell_w, top - gap // 2, cell_w, 4 * cell_h + gap // 2),
        '<text x="%d" y="%d" font-size="%d" font-weight="600" fill="#1C1C1E">Calipic icon colour matrix - %s</text>' % (page_pad, page_pad + font, int(font * 1.3), escape(label)),
    ]
    for col, (_, _, header, short_header) in enumerate(TREATMENTS):
        parts.append('<text x="%d" y="%d" font-size="%d" text-anchor="middle" fill="#3A3A3C">%s</text>' % (
            left + col * cell_w + cell_w // 2, top - gap // 2 - font // 2, font, escape(short_header if compact else header)))
    for idx, (cell, name, _, mark, field, (root_attrs, body)) in enumerate(variants):
        row, col = divmod(idx, 3)
        x = left + col * cell_w + gap // 2
        y = top + row * cell_h
        if col == 0:
            parts.append('<text x="%d" y="%d" font-size="%d" font-weight="600" fill="#1C1C1E">%s</text>' % (page_pad, y + icon // 2, font, escape(cell[0])))
            for line_no, line in enumerate(name):
                parts.append('<text x="%d" y="%d" font-size="%d" fill="#3A3A3C">%s</text>' % (page_pad, y + icon // 2 + (line_no + 1) * int(font * 1.25), int(font * 0.85), escape(line)))
        parts.append('<svg%s x="%d" y="%d" width="%d" height="%d" viewBox="%s">%s</svg>' % (root_attrs, x, y, icon, icon, view_box, body))
        parts.append('<text x="%d" y="%d" font-size="%d" text-anchor="middle" fill="%s">%s  mark %s / field %s</text>' % (
            x + icon // 2, y + icon + caption, int(font * 0.8), "#AEAEB2" if col == 2 else "#3A3A3C", cell, mark, field))
    footer_lines = ["%s: flat colour test only. Geometry unchanged and not final;" % (label[:1].upper() + label[1:]),
                    "depth/texture finishing will come later. Provisional test values, not decisions."]
    if not compact:
        footer_lines = [" ".join(footer_lines)]
    for line_no, line in enumerate(footer_lines):
        parts.append('<text x="%d" y="%d" font-size="%d" fill="#636366">%s</text>' % (
            page_pad, height - footer + (line_no + 1) * int(font * 1.3), int(font * 0.8), escape(line)))
    parts.append("</svg>")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(parts) + "\n")


sheet(os.path.join(out_dir, SHEETS[0] + ".svg"), icon=512, gap=64, left=300, top=150, footer=70, font=24, page_pad=40)
# Exported at 1x so each icon is a true 120 px raster (Home Screen @2x class size).
sheet(os.path.join(out_dir, SHEETS[1] + ".svg"), icon=120, gap=64, left=170, top=90, footer=56, font=13, page_pad=20, compact=True)
print("\n".join(names))
PY
)"

render() { # <svg> <png> [width]; without a width the SVG's own pixel size is used (1x)
  local args=("$1" --export-type=png -o "$2") log
  if [[ $# -ge 3 ]]; then args+=(-w "$3"); fi
  # Inkscape is chatty even on success, so its output is only shown when the export fails.
  if ! log="$("$inkscape_bin" "${args[@]}" 2>&1)" || [[ ! -s "$2" ]]; then
    echo "error: inkscape failed to export $1" >&2
    echo "$log" >&2
    exit 1
  fi
}

count=0
while IFS= read -r name; do
  render "$out_dir/$name.svg" "$out_dir/$name.png" 1024
  count=$((count + 1))
done <<< "$variant_names"
if [[ $count -ne 12 ]]; then echo "error: expected 12 variants, rendered $count" >&2; exit 1; fi
render "$out_dir/contact-sheet-large.svg" "$out_dir/contact-sheet-large.png"
render "$out_dir/contact-sheet-120px.svg" "$out_dir/contact-sheet-120px.png"

echo "Rendered $count variants + 2 contact sheets from $input"
echo "Output: $out_dir"
cat "$out_dir/contrast.tsv"
