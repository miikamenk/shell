#!/usr/bin/env bash
# Run iNiR's third-party theming pipeline against caelestia's current scheme.
#
# Wired in as caelestia's theme.postHook (see README.md), so every wallpaper or
# scheme change re-themes everything iNiR knows how to theme: terminal configs,
# GTK/Qt/Kvantum, VSCode forks, Neovim, Zed, OpenCode, Chromium, SDDM, Steam,
# Spicetify, cava, Pear Desktop.
#
# Usage:
#   apply.sh                     # all targets enabled in iNiR's config
#   apply.sh terminals editors   # only these targets
#   apply.sh --list              # show available targets
#   apply.sh --convert-only      # just refresh the colour files
set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$XDG_STATE_HOME/caelestia/inir-theme.log"
LOCK_FILE="$XDG_STATE_HOME/caelestia/inir-theme.lock"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

# Locate the iNiR checkout that owns scripts/colors. The installed shell wins
# over a dev checkout so theming matches whatever iNiR is actually deployed.
resolve_inir_dir() {
  local candidate
  for candidate in \
    "${CAELESTIA_INIR_DIR:-}" \
    "$XDG_CONFIG_HOME/quickshell/inir" \
    "$XDG_CONFIG_HOME/quickshell/ii" \
    "$HOME/Projects/Personal/iNiR"; do
    [[ -n "$candidate" ]] || continue
    if [[ -x "$candidate/scripts/colors/applycolor.sh" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

# Mirrors iNiR's own venv lookup — materialyoucolor/PIL live there, not in the
# system interpreter.
resolve_python() {
  local venv
  if [[ -n "${INIR_VENV:-}" ]]; then
    venv="${INIR_VENV/#\~/$HOME}"
  elif [[ -n "${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-}" ]]; then
    venv="${ILLOGICAL_IMPULSE_VIRTUAL_ENV/#\~/$HOME}"
  else
    venv="$XDG_STATE_HOME/quickshell/.venv"
  fi

  if [[ -x "$venv/bin/python3" ]]; then
    printf '%s\n' "$venv/bin/python3"
  else
    printf '%s\n' python3
  fi
}

# iNiR's SDDM sync reads the wallpaper from iNiR's *config.json*, not from the
# state file this bridge writes, so the login theme's colours follow caelestia
# but its background image would stay on whatever iNiR last set. Point it at
# caelestia's wallpaper directly. install-pixel-sddm.sh makes the theme dir
# user-owned precisely so this needs no elevation, and iNiR copies to
# background.png regardless of source format too.
sync_sddm_background() {
  local colors_dir="$1"
  local assets_dir=/usr/share/sddm/themes/ii-pixel/assets
  [[ -d "$assets_dir" && -w "$assets_dir" ]] || return 0

  # Subshell: module-runtime.sh defines its own SCRIPT_DIR/STATE_DIR
  if ! (source "$colors_dir/lib/module-runtime.sh" && target_manifest_enabled "$colors_dir/targets/sddm.json") >/dev/null 2>&1; then
    return 0
  fi

  local wall
  wall="$(cat "$XDG_STATE_HOME/caelestia/wallpaper/path.txt" 2>/dev/null)" || return 0
  [[ -n "$wall" && -f "$wall" ]] || return 0

  if cp -f "$wall" "$assets_dir/background.png"; then
    log "sddm background -> $(basename "$wall")"
  fi
}

rotate_log() {
  local max_bytes=$((1024 * 1024))
  [[ -f "$LOG_FILE" ]] || return 0
  local size
  size="$(stat -c %s "$LOG_FILE" 2>/dev/null || printf '0')"
  ((size > max_bytes)) || return 0
  tail -c $((max_bytes / 4)) "$LOG_FILE" > "$LOG_FILE.rotated" && mv -f "$LOG_FILE.rotated" "$LOG_FILE"
}

main() {
  local convert_only=false
  local list_only=false
  local targets=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --convert-only) convert_only=true ;;
      --list) list_only=true ;;
      -h | --help)
        sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
        return 0
        ;;
      *) targets+=("$1") ;;
    esac
    shift
  done

  local inir_dir
  if ! inir_dir="$(resolve_inir_dir)"; then
    log "no iNiR checkout with scripts/colors found — nothing to do"
    return 0
  fi

  local colors_dir="$inir_dir/scripts/colors"

  if [[ "$list_only" == true ]]; then
    local python_cmd
    python_cmd="$(resolve_python)"
    "$python_cmd" "$colors_dir/list-targets.py"
    return 0
  fi

  log "using iNiR at $inir_dir"

  local python_cmd
  python_cmd="$(resolve_python)"
  "$python_cmd" "$SCRIPT_DIR/scheme-to-inir.py" --inir-dir "$inir_dir"

  if [[ "$convert_only" == true ]]; then
    log "converted only, skipping appliers"
    return 0
  fi

  local ran_sddm=false
  if [[ ${#targets[@]} -gt 0 ]]; then
    log "applying targets: ${targets[*]}"
    bash "$colors_dir/apply-targets.sh" "${targets[@]}"
    [[ " ${targets[*]} " == *" sddm "* ]] && ran_sddm=true
  else
    log "applying all enabled targets"
    bash "$colors_dir/applycolor.sh"
    ran_sddm=true
  fi

  [[ "$ran_sddm" == true ]] && sync_sddm_background "$colors_dir"

  log "done"
}

mkdir -p "$(dirname "$LOG_FILE")"
rotate_log

# Serialise runs: rapid wallpaper switching would otherwise have two pipelines
# writing the same GTK/terminal configs at once. Later run wins, earlier waits.
exec 9>"$LOCK_FILE"
if ! flock -w 30 9; then
  log "another inir-theme run held the lock for 30s, giving up"
  exit 0
fi

main "$@" 2>&1 | tee -a "$LOG_FILE"
exit "${PIPESTATUS[0]}"
