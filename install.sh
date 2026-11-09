#!/usr/bin/env bash
# Yorumi theme installer for Ghostty (Linux & macOS)
set -euo pipefail

# ── flavour, target config, and whether to activate ────────────────────────
FLAVOUR=""
FLAVOURS="ether abyss bifrost kraken kabocha cosmic ryujin"
CONFIG=""
ACTIVATE=1

# Print the real file $1's bytes belong in, following any final-component
# symlink chain. Plain readlink: -f is GNU, and this must also work on macOS
# and in Git Bash. Nothing is written here, so a bad link leaves the file alone.
resolve_config() {
  local cfg="$1" link hops=0
  while [ -L "$cfg" ]; do
    hops=$((hops + 1))
    if [ "$hops" -gt 40 ]; then
      echo "yorumi: $1 is a symbolic link loop; configuration unchanged" >&2
      return 1
    fi
    if ! link=$(readlink "$cfg"); then
      echo "yorumi: cannot read the symbolic link $cfg; configuration unchanged" >&2
      return 1
    fi
    case "$link" in
      /*) cfg="$link" ;;
      *) cfg="$(dirname "$cfg")/$link" ;;
    esac
  done
  if [ "$hops" -gt 0 ] && [ ! -e "$cfg" ]; then
    echo "yorumi: $1 points at $cfg, which does not exist; configuration unchanged" >&2
    return 1
  fi
  printf '%s\n' "$cfg"
}

# replace $1 (already resolved) with $2 atomically: the temp is a safely named
# sibling of the real file, so the rename never crosses a filesystem, and a
# failed write leaves $1 exactly as it was. cp -p carries the mode, owner and
# timestamps of an existing config onto the temp, as before.
commit() {
  local tmp mode
  # Fail closed before copying: cp -p would clone an immutable (uchg) or
  # otherwise unwritable config's flags onto the temp, which could then be
  # neither written nor removed. An append-open writes no bytes, and it only
  # runs for a file that already exists.
  if [ -e "$1" ] && ! : 2>/dev/null >> "$1"; then
    echo "yorumi: $1 is not writable (read-only or protected); configuration unchanged" >&2
    return 1
  fi
  if ! tmp=$(mktemp "$1.yorumi-tmp.XXXXXX"); then
    echo "yorumi: cannot create a temporary file next to $1" >&2
    return 1
  fi
  if [ -e "$1" ]; then
    cp -p "$1" "$tmp" || { rm -f "$tmp"; return 1; }
  else
    # a fresh config keeps the mode a `: >` under this umask would have given it
    mode=$(umask)
    chmod "$(printf '%o' "$(( 0666 & ~0$mode ))")" "$tmp" || { rm -f "$tmp"; return 1; }
  fi
  if cat "$2" > "$tmp" && mv "$tmp" "$1"; then
    return 0
  fi
  rm -f "$tmp"
  return 1
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

if [[ "${XDG_CONFIG_HOME:-}" = /* ]]; then
  _YORUMI_XDG="$XDG_CONFIG_HOME"
else
  _YORUMI_XDG="$HOME/.config"
fi
_YORUMI_CANDS=("$_YORUMI_XDG/ghostty/config.ghostty" "$_YORUMI_XDG/ghostty/config")
if [ "$(uname -s)" = "Darwin" ]; then
  _YORUMI_CANDS+=("$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty" "$HOME/Library/Application Support/com.mitchellh.ghostty/config")
fi
_YORUMI_CFG=""
for _c in "${_YORUMI_CANDS[@]}"; do
  if [ -e "$_c" ]; then _YORUMI_CFG="$_c"; fi
done
[ -z "$_YORUMI_CFG" ] && _YORUMI_CFG="$_YORUMI_XDG/ghostty/config"
DEFAULT_CONFIG="$_YORUMI_CFG"

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


DEST_DIR="$_YORUMI_XDG/ghostty/themes"
mkdir -p "$DEST_DIR"
DEST_DIR="$(cd "$DEST_DIR" && pwd -P)"

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

cat << INFO

Successfully installed the Yorumi files for Ghostty.

Activate it — the block below is rewritten by every run, so switching flavour is
just ./install.sh --flavour <name>:

    # >>> yorumi >>>
    theme = yorumi-${FLAVOUR:-<flavour>}
    # <<< yorumi <<<
INFO

# ── activation: one marked block, replaced whole ───────────────────────────
BEGIN="# >>> yorumi >>>"
END="# <<< yorumi <<<"

write_block() {
  CONFIG="${CONFIG:-$DEFAULT_CONFIG}"
  CONFIG_REAL=$(resolve_config "$CONFIG") || exit 1
  mkdir -p "$(dirname "$CONFIG_REAL")" || { echo "yorumi: cannot create $(dirname "$CONFIG_REAL")" >&2; exit 1; }

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT

  # every comparison runs on a copy with the CRs stripped; the endings come
  # back on the way out, so a CRLF config is neither duplicated nor converted
  if [ -e "$CONFIG_REAL" ]; then
    tr -d '\r' < "$CONFIG_REAL" > "$work/in"
  else
    : > "$work/in"
  fi
  crlf=""
  if [ -s "$CONFIG_REAL" ] && [ "$(wc -c < "$work/in")" -lt "$(wc -c < "$CONFIG_REAL")" ]; then
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

  if ! cmp -s "$CONFIG_REAL" "$work/out"; then
    if [ -e "$CONFIG_REAL" ] && ! : 2>/dev/null >> "$CONFIG_REAL"; then
      echo "yorumi: $CONFIG_REAL is not writable (read-only or protected); configuration unchanged" >&2
      return 1
    fi
    [ -e "$CONFIG_REAL.yorumi-backup" ] || [ ! -s "$CONFIG_REAL" ] || cp -p "$CONFIG_REAL" "$CONFIG_REAL.yorumi-backup"
    if ! commit "$CONFIG_REAL" "$work/out"; then
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
