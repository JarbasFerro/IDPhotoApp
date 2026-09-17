#!/usr/bin/env bash
# Calipic brand evidence, unit 2: icon size + real-context sheets.
#
# Renders every provisional colour candidate (A-D) x treatment (T1-T3) of the
# icon at true iOS pixel sizes, builds enlarged inspection strips and context
# mock sheets (Home Screen x3 wallpapers, App Store search row, Settings list
# 29 pt, Spotlight 40 pt), and writes small-size structure metrics.
#
# The icon is a DRAFT STAND-IN: geometry is never altered, only colours are
# substituted. Re-run on a refined icon by passing its SVG path.
#
# Usage (from repo root):
#   scripts/brand/render-icon-sizes.sh [input.svg] [output-dir]
# Env overrides for a refined icon whose source colours / key points differ:
#   MARK_HEX (#111111)  FIELD_HEX (#FFFFFF)  STROKE_HEX (#D9D9D9)   6-digit hex
#   STRAND_WIDTH (12)   FRAME_WIDTH (72)     viewBox units, for metrics.tsv
#   PROBES  space-separated name:x:y:axis -- frame gaps to sample; x/y are
#           fractions of the canvas, axis is the direction the stroke runs
#           through the gap (h or v). Defaults are the v0 gap centres.
# Known limits when re-running on a refined icon: colours must be written as
# 6-digit hex attributes; the strand is detected as a self-closing
# path/line/polyline stroked in FIELD_HEX (otherwise strand metrics are n/a).
# Requires Inkscape >= 1.0 (uses --actions / export-do).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INPUT="${1:-$REPO_ROOT/docs/brand/assets/calipic-icon-draft-v0.svg}"
OUT="${2:-$REPO_ROOT/docs/brand/prototypes/icon-sizes}"
GEN="$REPO_ROOT/scripts/brand/render_icon_sizes.py"

MARK_HEX="${MARK_HEX:-#111111}"
FIELD_HEX="${FIELD_HEX:-#FFFFFF}"
STROKE_HEX="${STROKE_HEX:-#D9D9D9}"
STRAND_WIDTH="${STRAND_WIDTH:-12}"
FRAME_WIDTH="${FRAME_WIDTH:-72}"
PROBES="${PROBES:-top_gap:0.5:0.16797:h bottom_gap:0.5:0.83203:h left_gap:0.17578:0.5:v right_opening:0.82227:0.5:v}"

INKSCAPE="${INKSCAPE:-$(command -v inkscape || true)}"
[[ -n "$INKSCAPE" && -x "$INKSCAPE" ]] || { echo "error: inkscape not found (set INKSCAPE=/path)" >&2; exit 1; }
command -v python3 >/dev/null || { echo "error: python3 not found" >&2; exit 1; }
command -v sips >/dev/null || { echo "error: sips not found" >&2; exit 1; }
[[ -f "$INPUT" ]] || { echo "error: input SVG not found: $INPUT" >&2; exit 1; }
INPUT="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"

# Everything is built and verified in a temp dir, then swapped into $OUT, so a
# failed run never destroys the previous evidence set.
TMP="$(mktemp -d "${TMPDIR:-/tmp}/calipic-icon-sizes.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
case "$TMP" in *";"*) echo "error: temp path contains ';': $TMP" >&2; exit 1 ;; esac
WORK="$TMP/out"
mkdir -p "$WORK/svg" "$WORK/png" "$WORK/sheets" \
         "$TMP/nostrand-svg" "$TMP/nostrand-png" "$TMP/sheet-svg"

COLOUR_ARGS=(--input "$INPUT" --mark-hex "$MARK_HEX" --field-hex "$FIELD_HEX" --stroke-hex "$STROKE_HEX")
SIZES_STR="$(python3 "$GEN" sizes)"
IDS_STR="$(python3 "$GEN" ids)"
read -r -a SIZES <<<"$SIZES_STR"
read -r -a IDS <<<"$IDS_STR"
[[ ${#SIZES[@]} -gt 0 && ${#IDS[@]} -gt 0 ]] || { echo "error: generator returned no sizes/ids" >&2; exit 1; }

ink() { "$INKSCAPE" "$@" 2> >(grep -v -e '^$' -e 'Gtk-' -e 'GLib' -e 'dbus' >&2 || true); }

# Rasterise one SVG at every size in a single Inkscape run (true rasterisation
# from vector at each pixel size -- never a downscale of the 1024 px render).
render_sizes() { # <svg> <out-dir> <id>
  local actions="" s
  for s in "${SIZES[@]}"; do
    actions+="export-filename:$2/$3-$s.png;export-width:$s;export-height:$s;export-do;"
  done
  ink "$1" --export-type=png --actions="$actions" >/dev/null
}

echo "==> recolouring $(basename "$INPUT") (draft stand-in; geometry untouched)"
python3 "$GEN" variants "${COLOUR_ARGS[@]}" --out "$WORK/svg" --nostrand-out "$TMP/nostrand-svg"

echo "==> rasterising ${#IDS[@]} variants x ${#SIZES[@]} sizes"
for id in "${IDS[@]}"; do
  render_sizes "$WORK/svg/$id.svg" "$WORK/png" "$id"
  if [[ -f "$TMP/nostrand-svg/$id.svg" ]]; then
    render_sizes "$TMP/nostrand-svg/$id.svg" "$TMP/nostrand-png" "$id"
  fi
done

echo "==> composing strips + context sheets"
python3 "$GEN" sheets "${COLOUR_ARGS[@]}" --out "$TMP/sheet-svg" --png-dir "$WORK/png"
for svg in "$TMP"/sheet-svg/*.svg; do
  ink "$svg" --export-type=png -o "$WORK/sheets/$(basename "${svg%.svg}").png" >/dev/null
done

echo "==> measuring small-size structure"
PROBE_ARGS=()
for p in $PROBES; do PROBE_ARGS+=(--probe "$p"); done
python3 "$GEN" metrics "${COLOUR_ARGS[@]}" --png-dir "$WORK/png" \
  --nostrand-dir "$TMP/nostrand-png" --out "$WORK/metrics.tsv" \
  --strand-width "$STRAND_WIDTH" --frame-width "$FRAME_WIDTH" ${PROBE_ARGS[@]+"${PROBE_ARGS[@]}"}

echo "==> verifying outputs"
fail=0
dims() { sips -g pixelWidth -g pixelHeight "$1" 2>/dev/null | awk '/pixel/ {printf "%s ", $2}'; }
for id in "${IDS[@]}"; do
  for s in "${SIZES[@]}"; do
    f="$WORK/png/$id-$s.png"
    if [[ ! -s "$f" ]]; then echo "MISSING/EMPTY $f" >&2; fail=1; continue; fi
    got="$(dims "$f")"
    if [[ "$got" != "$s $s " ]]; then echo "BAD SIZE $f: got ${got}want $s $s" >&2; fail=1; fi
  done
done
SHEETS=(context-home-light context-home-dark context-home-busy
        context-appstore-light context-appstore-dark
        context-lists-light context-lists-dark strip-t1 strip-t2 strip-t3)
for name in "${SHEETS[@]}"; do
  f="$WORK/sheets/$name.png"
  if [[ ! -s "$f" ]]; then echo "MISSING/EMPTY $f" >&2; fail=1; continue; fi
  echo "    $name.png $(dims "$f")"
done
[[ -s "$WORK/metrics.tsv" ]] || { echo "MISSING metrics.tsv" >&2; fail=1; }
[[ $fail -eq 0 ]] || { echo "verification FAILED; $OUT left untouched" >&2; exit 1; }

# Idempotent publish: replace only the paths this script owns.
mkdir -p "$OUT"
rm -rf "$OUT/svg" "$OUT/png" "$OUT/sheets" "$OUT/metrics.tsv"
cp -R "$WORK/svg" "$WORK/png" "$WORK/sheets" "$WORK/metrics.tsv" "$OUT/"
echo "OK: $(( ${#IDS[@]} * ${#SIZES[@]} )) size renders + ${#SHEETS[@]} sheets + metrics.tsv in $OUT"
