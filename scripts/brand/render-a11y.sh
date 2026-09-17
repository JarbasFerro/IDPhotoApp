#!/bin/bash
# Calipic brand - accessibility & perception renders (work unit 3 of the colour-evidence round).
#
# Usage (from the repo root):
#   scripts/brand/render-a11y.sh [path/to/icon.svg]
#
# The icon defaults to docs/brand/assets/calipic-icon-draft-v0.svg, which is ONLY A DRAFT STAND-IN.
# Re-run with a refined icon path once one exists; the icon must keep the three recolour tokens
# #111111 (mark), #FFFFFF (field + hair-strand cutout) and #D9D9D9 (field stroke).
#
# Environment:
#   OUT_DIR     output directory        (default docs/brand/prototypes/a11y)
#   ICON_LABEL  label printed on sheets (default "draft v0 stand-in" for the default icon,
#               otherwise "stand-in: <file name>")
#   KEEP_SVG=1  also keep the intermediate SVG sources in $OUT_DIR/svg
#   INKSCAPE    inkscape binary        (default: inkscape on PATH, then /opt/homebrew/bin/inkscape)
#
# Produces, per simulation (normal, grayscale, protanopia, deuteranopia, tritanopia):
#   $OUT_DIR/sheet-<sim>.png                          all 4 candidates + accent/system-colour swatch rows
#   $OUT_DIR/candidates/candidate-<A-D>-<sim>.png     per-candidate strip (3 treatments + Increase Contrast)
# plus $OUT_DIR/tables.md (WCAG contrast + CIEDE2000 tables), which is also injected into
# docs/brand/prototypes/03-accessibility-color.md between its GENERATED markers.
#
# Idempotent: owned outputs are regenerated on every run and only replaced once all checks pass.
# Relative icon / OUT_DIR paths are resolved against the directory the script is called from.
# Requires inkscape, sips, python3.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
caller_dir="$PWD"

abspath() { # resolve a possibly-relative path against the caller's directory
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s\n' "$caller_dir/$1" ;;
  esac
}

default_icon="docs/brand/assets/calipic-icon-draft-v0.svg"
if [[ $# -ge 1 ]]; then
  icon="$(abspath "$1")"
else
  icon="$repo_root/$default_icon"
fi
if [[ -n "${OUT_DIR:-}" ]]; then
  out_dir="$(abspath "$OUT_DIR")"
else
  out_dir="$repo_root/docs/brand/prototypes/a11y"
fi
cd "$repo_root"
doc="docs/brand/prototypes/03-accessibility-color.md"
tools="scripts/brand/a11y_tools.py"

if [[ $# -gt 1 ]]; then
  echo "Usage: scripts/brand/render-a11y.sh [path/to/icon.svg]" >&2
  exit 2
fi
if [[ ! -f "$icon" ]]; then
  echo "error: icon SVG not found: $icon" >&2
  exit 1
fi
if [[ -n "${ICON_LABEL:-}" ]]; then
  label="$ICON_LABEL"
elif [[ "$icon" == "$repo_root/$default_icon" ]]; then
  label="draft v0 stand-in"
else
  label="stand-in: $(basename "$icon")"
fi

inkscape_bin="${INKSCAPE:-$(command -v inkscape || true)}"
if [[ -z "$inkscape_bin" && -x /opt/homebrew/bin/inkscape ]]; then
  inkscape_bin=/opt/homebrew/bin/inkscape
fi
for tool in "$inkscape_bin" sips python3; do
  if [[ -z "$tool" ]] || ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: required tool missing: ${tool:-inkscape}" >&2
    exit 1
  fi
done

echo "== colour-math selftest"
python3 "$tools" selftest

build_dir="$(mktemp -d "${TMPDIR:-/tmp}/calipic-a11y.XXXXXX")"
trap 'rm -rf "$build_dir"' EXIT

# Everything is built, rendered and verified inside $build_dir; the owned outputs in $out_dir are only
# replaced at the very end, so a failing run never leaves the evidence directory empty.
stage="$build_dir/stage"
mkdir -p "$stage/candidates"

echo "== build SVG sources ($label, icon: $icon)"
python3 "$tools" build "$icon" "$build_dir" "$label"

render() { # <svg> <png> <width>
  local log
  if ! log="$("$inkscape_bin" "$1" --export-type=png -w "$3" -o "$2" 2>&1)" || [[ ! -s "$2" ]]; then
    echo "error: inkscape failed to render $1" >&2
    echo "$log" >&2
    exit 1
  fi
}

echo "== render PNGs"
count=0
while IFS=$'\t' read -r kind svg png width height; do
  if [[ "$kind" == "probe" ]]; then
    target="$build_dir/$png"
  else
    target="$stage/$png"
  fi
  render "$build_dir/$svg" "$target" "$width"
  got="$(sips -g pixelWidth -g pixelHeight "$target" | awk '/pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {print w "x" h}')"
  if [[ "$got" != "${width}x${height}" ]]; then
    echo "error: $png is $got, expected ${width}x${height}" >&2
    exit 1
  fi
  if [[ "$kind" != "probe" ]]; then
    count=$((count + 1))
    echo "  $png  $got"
  fi
done < "$build_dir/manifest.tsv"

echo "== verify the filters really applied (decoded probe pixels vs python-computed simulation)"
for sim in normal grayscale protanopia deuteranopia tritanopia; do
  python3 "$tools" verify-probe "$build_dir/probe-$sim.png" "$sim"
done
# Every delivered grayscale PNG is checked at full resolution (sips converts to uncompressed BMP so the
# stdlib check is fast): no pixel may carry chroma.
for png in "$stage"/sheet-grayscale.png "$stage"/candidates/candidate-*-grayscale.png; do
  bmp="$build_dir/$(basename "${png%.png}").bmp"
  sips -s format bmp "$png" --out "$bmp" >/dev/null
  python3 "$tools" verify-gray "$bmp"
done

echo "== tables"
python3 "$tools" tables "$stage/tables.md"

echo "== install outputs into $out_dir"
mkdir -p "$out_dir/candidates"
rm -f "$out_dir"/sheet-*.png "$out_dir"/candidates/candidate-*.png "$out_dir/tables.md"
rm -rf "$out_dir/svg"
cp "$stage"/sheet-*.png "$stage/tables.md" "$out_dir/"
cp "$stage"/candidates/candidate-*.png "$out_dir/candidates/"
if [[ -f "$doc" ]]; then
  python3 "$tools" inject "$doc" "$out_dir/tables.md"
  echo "  tables injected into $doc"
fi

if [[ "${KEEP_SVG:-0}" == "1" ]]; then
  mkdir -p "$out_dir/svg"
  cp "$build_dir"/sheet-*.svg "$build_dir"/candidate-*.svg "$out_dir/svg/"
fi

echo "done: $count PNGs + tables.md in $out_dir"
