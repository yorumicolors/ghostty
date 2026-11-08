#!/usr/bin/env bash
# Yorumi theme installer for Ghostty (Linux & macOS)
set -euo pipefail

# ── flavour, target config, and whether to activate ────────────────────────
FLAVOUR="ether"
CONFIG=""
ACTIVATE=1
DEFAULT_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"

while [ $# -gt 0 ]; do
  case "$1" in
    --flavour|-f)  FLAVOUR="${2:-}"; shift 2 ;;
    --config|-c)   CONFIG="${2:-}";  shift 2 ;;
    --no-activate) ACTIVATE=0; shift ;;
    -h|--help)
      echo "usage: ./install.sh [--flavour <name>] [--config <path>] [--no-activate]"
      echo "flavours: ether abyss bifrost kraken kabocha cosmic ryujin"
      exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

case " ether abyss bifrost kraken kabocha cosmic ryujin " in
  *" $FLAVOUR "*) ;;
  *) echo "unknown flavour '$FLAVOUR'. One of: ether abyss bifrost kraken kabocha cosmic ryujin" >&2; exit 2 ;;
esac


DEST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/themes"
mkdir -p "$DEST_DIR"

RAW_BASE="https://raw.githubusercontent.com/yorumicolors/ghostty/main"
FILES=("yorumi-ether" "yorumi-abyss" "yorumi-bifrost" "yorumi-kraken" "yorumi-kabocha" "yorumi-cosmic" "yorumi-ryujin")

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
fi

echo "Installing Yorumi theme for Ghostty..."

for f in "${FILES[@]}"; do
  basename_f="$(basename "$f")"
  target="$DEST_DIR/$basename_f"
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$f" ]]; then
    cp "$SCRIPT_DIR/$f" "$target"
  elif [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$basename_f" ]]; then
    cp "$SCRIPT_DIR/$basename_f" "$target"
  else
    curl -fsSL "$RAW_BASE/$f" -o "$target"
  fi
  echo "✓ Installed: $target"
done

cat << 'INFO'

Successfully installed the Yorumi files for Ghostty.

Activate it — the block below is rewritten by every run, so switching flavour is
just `./install.sh --flavour <name>`:

    # >>> yorumi >>>
    theme = yorumi-abyss
    # <<< yorumi <<<
INFO

# ── activation: one marked block, replaced whole ───────────────────────────
BEGIN="# >>> yorumi >>>"
END="# <<< yorumi <<<"

write_block() {
  CONFIG="${CONFIG:-$DEFAULT_CONFIG}"
  mkdir -p "$(dirname "$CONFIG")"
  [ -e "$CONFIG" ] || : > "$CONFIG"

  begins=$(grep -c -x -F -e "$BEGIN" "$CONFIG" || true)
  ends=$(grep -c -x -F -e "$END" "$CONFIG" || true)
  if [ "$begins" != "$ends" ]; then
    echo "yorumi: $CONFIG has $begins '$BEGIN' and $ends '$END' markers." >&2
    echo "yorumi: the config was not touched; fix or delete those lines, then run this again." >&2
    exit 1
  fi

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT

  cat > "$work/block" <<YORUMI_BLOCK
$BEGIN
theme = yorumi-$FLAVOUR
$END
YORUMI_BLOCK

  if grep -q -x -F -e "$BEGIN" "$CONFIG"; then
    awk -v b="$BEGIN" -v e="$END" -v bf="$work/block" '
      $0 == b { if (!done) { while ((getline line < bf) > 0) print line; close(bf); done = 1 } inside = 1; next }
      $0 == e { inside = 0; next }
      inside == 0 { print }' "$CONFIG" > "$work/out"
  else
    { cat "$CONFIG"; [ -s "$CONFIG" ] && printf '\n'; cat "$work/block"; } > "$work/out"
  fi

  if ! cmp -s "$CONFIG" "$work/out"; then
    [ -e "$CONFIG.yorumi-backup" ] || cp "$CONFIG" "$CONFIG.yorumi-backup"
    cp "$work/out" "$CONFIG"
    echo "✓ Block written to $CONFIG ($FLAVOUR)"
  else
    echo "✓ Block already current in $CONFIG ($FLAVOUR)"
  fi
}

if [ "$ACTIVATE" -eq 1 ]; then
  write_block
else
  echo "• Activation skipped (--no-activate); the files are installed."
fi
