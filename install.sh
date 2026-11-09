#!/usr/bin/env bash
# Yorumi theme installer for Ghostty (Linux & macOS)
set -euo pipefail

# ── flavour, target config, and whether to activate ────────────────────────
FLAVOUR=""
FLAVOURS="ether abyss bifrost kraken kabocha cosmic ryujin"
CONFIG=""
ACTIVATE=1

# replace $1 with $2 atomically, keeping the original file mode
commit() {
  tmp="$1.yorumi-tmp.$$"
  if [ -e "$1" ]; then cp -p "$1" "$tmp"; else : > "$tmp"; fi
  if cat "$2" > "$tmp"; then mv "$tmp" "$1"; else rm -f "$tmp"; return 1; fi
}

# No default flavour. Ask, or fail where nobody can answer.
ask_flavour() {
  # a real open, not a -r test: /dev/tty exists even when nothing is attached
  if ! { exec 3<>/dev/tty; } 2>/dev/null; then
    echo "no flavour given. pass --flavour <name>: $FLAVOURS" >&2
    exit 2
  fi
  i=0
  {
    echo "Yorumi flavours:"
    for f in $FLAVOURS; do i=$((i + 1)); echo "  $i) $f"; done
  } >&3
  while :; do
    printf 'flavour (1-%s or a name): ' "$i" >&3
    answer=""
    IFS= read -r answer <&3 || {
      exec 3>&-
      echo "no flavour given. pass --flavour <name>: $FLAVOURS" >&2
      exit 2
    }
    [ -z "$answer" ] && continue
    case "$answer" in
      *[!0-9]*) candidate="$answer" ;;
      *) candidate=""
         n=0
         for f in $FLAVOURS; do n=$((n + 1)); [ "$n" -eq "$answer" ] && candidate="$f"; done ;;
    esac
    case " $FLAVOURS " in
      *" $candidate "*) FLAVOUR="$candidate"; exec 3>&-; return 0 ;;
    esac
    printf 'not a flavour: %s\n' "$answer" >&3
  done
}

DEFAULT_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"

while [ $# -gt 0 ]; do
  case "$1" in
    --flavour|-f)
      [ -n "${2:-}" ] || { echo "--flavour needs a flavour name. One of: $FLAVOURS" >&2; exit 2; }
      FLAVOUR="$2"; shift 2 ;;
    --config|-c)
      [ -n "${2:-}" ] || { echo "--config needs a path" >&2; exit 2; }
      CONFIG="$2"; shift 2 ;;
    --no-activate) ACTIVATE=0; shift ;;
    -h|--help)
      echo "usage: ./install.sh [--flavour <name>] [--config <path>] [--no-activate]"
      echo "flavours: $FLAVOURS"
      exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -n "$FLAVOUR" ]; then
  case " $FLAVOURS " in
    *" $FLAVOUR "*) ;;
    *) echo "unknown flavour '$FLAVOUR'. One of: $FLAVOURS" >&2; exit 2 ;;
  esac
fi

[ -z "$FLAVOUR" ] && [ "$ACTIVATE" -eq 1 ] && ask_flavour


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
    part="$DEST_DIR/$basename_f.part.$$"
    if ! curl -fsSL "$RAW_BASE/$f" -o "$part"; then
      rm -f "$part"
      echo "yorumi: could not download $f from $RAW_BASE" >&2
      echo "yorumi: if that repository is not public yet, clone it and run ./install.sh from the checkout." >&2
      exit 3
    fi
    mv "$part" "$target"
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
  mkdir -p "$(dirname "$CONFIG")" || { echo "yorumi: cannot create $(dirname "$CONFIG")" >&2; exit 1; }
  [ -e "$CONFIG" ] || : > "$CONFIG"

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT

  # every comparison runs on a copy with the CRs stripped; the endings come
  # back on the way out, so a CRLF config is neither duplicated nor converted
  tr -d '\r' < "$CONFIG" > "$work/in"
  crlf=""
  if [ -s "$CONFIG" ] && [ "$(wc -c < "$work/in")" -lt "$(wc -c < "$CONFIG")" ]; then
    crlf=1
  fi

  # markers are counted on trimmed lines: an indented block still pairs, and
  # an END before its BEGIN counts as broken
  counts=$(awk -v b="$BEGIN" -v e="$END" '
    function trim(x) { sub(/^[ \t]+/, "", x); sub(/[ \t]+$/, "", x); return x }
    { t = trim($0)
      if (t == b) { nb++; depth++ }
      else if (t == e) { ne++; if (depth > 0) depth--; else bad = 1 }
    }
    END { printf "%d %d %d\n", nb + 0, ne + 0, bad + 0 }' "$work/in")
  begins=${counts%% *}
  rest=${counts#* }
  ends=${rest%% *}
  order=${rest#* }
  if [ "$begins" != "$ends" ] || [ "$order" != 0 ]; then
    echo "yorumi: $CONFIG has $begins '$BEGIN' and $ends '$END' markers." >&2
    echo "yorumi: the config was not touched; fix or delete those lines, then run this again." >&2
    exit 1
  fi

  cat > "$work/body" <<YORUMI_BODY
theme = yorumi-$FLAVOUR
YORUMI_BODY

  # the block is ours alone: it is taken out wherever it sits and written back
  # where the app reads it last, so nothing after it can shadow it and a second
  # copy cannot survive a flavour switch
  awk -v b="$BEGIN" -v e="$END" -v bf="$work/body" -v mode="end" '
    function trim(x) { sub(/^[ \t]+/, "", x); sub(/[ \t]+$/, "", x); return x }
    function emit(   line) {
      print b
      while ((getline line < bf) > 0) print line
      close(bf); print e
    }
    { L[NR] = $0 }
    END {
      n = NR

      # 1. drop every copy of our block, and the blank line we put after it,
      #    so a rerun cannot grow the file by one blank per run
      m = 0; inside = 0; skipblank = 0
      for (i = 1; i <= n; i++) {
        t = trim(L[i])
        if (t == b) { inside = 1; continue }
        if (inside && t == e) { inside = 0; skipblank = 1; continue }
        if (inside) continue
        if (skipblank && t == "") { skipblank = 0; continue }
        skipblank = 0
        m++; K[m] = L[i]
      }
      n = m

      # 2. where the app reads it last: the end of the file, or — in a Lua
      #    config — immediately above the returned table
      pos = n + 1
      if (mode == "lua") {
        for (i = n; i >= 1; i--) if (K[i] ~ /^return[ \t(]/) { pos = i; break }
      }

      # 3. write it
      for (i = 1; i < pos; i++) print K[i]
      if (pos > 1 && trim(K[pos - 1]) != "") print ""
      emit()
      if (pos <= n) print ""
      for (i = pos; i <= n; i++) print K[i]
    }
  ' "$work/in" > "$work/out"

  if [ -n "$crlf" ]; then
    awk -v cr="$(printf '\r')" '{ printf "%s%s\n", $0, cr }' "$work/out" > "$work/crlf"
    mv "$work/crlf" "$work/out"
  fi

  if ! cmp -s "$CONFIG" "$work/out"; then
    [ -e "$CONFIG.yorumi-backup" ] || [ ! -s "$CONFIG" ] || cp -p "$CONFIG" "$CONFIG.yorumi-backup"
    if ! commit "$CONFIG" "$work/out"; then
      echo "yorumi: could not write $CONFIG" >&2
      exit 1
    fi
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
