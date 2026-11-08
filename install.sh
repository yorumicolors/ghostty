#!/usr/bin/env bash
# Yorumi theme installer for Ghostty (Linux & macOS)
set -euo pipefail

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

Successfully installed Yorumi for Ghostty!
Set `theme` in `~/.config/ghostty/config`:
    theme = yorumi-abyss
INFO
