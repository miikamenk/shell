#!/usr/bin/env bash
#
# Make a scheme change land in Chromium-family browsers without restarting them.
#
# Rendering templates/chromium-policy.json is already the whole write — the
# managed-policy file is a symlink out of the (0777) policy dir into
# ~/.local/state/caelestia/theme, so no elevation is involved anywhere here.
# But Chromium reads platform policy once at startup and caches it, so the new
# BrowserThemeColor sits on disk unread until the next launch.
# --refresh-platform-policy makes a running instance re-read it, which is what
# turns a scheme change into a live repaint.
#
# Wired in as caelestia's theme.postHook (see docs/templates.md).
set -uo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

# Chromium merges *every* file in the managed-policy directory and gives
# priority to the last one in lexicographic order. A leftover ii-theme.json from
# iNiR therefore beats caelestia.json outright (c sorts before i) — the seed
# applies, just not ours, and chrome://policy reports it only as a quiet
# "Conflict" warning on a policy that is otherwise "working as intended".
# caelestia replaced that pipeline, so clear its file whenever this runs.
# Switching back to iNiR still works: it rewrites its own file and wins again by
# the same rule, so whichever tool applied a theme last is the one in effect.
rm -f /etc/chromium/policies/managed/ii-theme.json 2>/dev/null

# caelestia exports SCHEME_MODE into postHook. Set the browser's mode from it
# explicitly (2 = dark, 1 = light) rather than using 0, "follow the system":
# following the system means following the XDG portal, and Helium ships as an
# AppImage whose portal integration is not something to bet the theme on.
case "${SCHEME_MODE:-dark}" in
  light) COLOR_SCHEME=1 ;;
  *) COLOR_SCHEME=2 ;;
esac

# comm|launcher|profile dir. Matching is on comm, not the launcher name: they
# differ (Google Chrome's processes are `chrome`), comm is capped at 15 chars,
# and Helium ships as an AppImage with no launcher on PATH at all.
BROWSERS=(
  "chromium|chromium|$CONFIG/chromium"
  "chromium-browse|chromium-browser|$CONFIG/chromium"
  "chrome|google-chrome-stable|$CONFIG/google-chrome"
  "brave|brave|$CONFIG/BraveSoftware/Brave-Browser"
  "helium|helium|$CONFIG/net.imput.helium"
)

# Prefer a launcher on PATH — on Arch it is a wrapper that folds in
# ~/.config/*-flags.conf, and a flag file that moves --user-data-dir would move
# the singleton socket this needs to reach. Fall back to the running image,
# which is the only way in for an AppImage: its mount path is regenerated on
# every launch, so there is nothing stable to hardcode.
browser_exe() {
  local launcher="$1" pid="$2"
  if command -v "$launcher" >/dev/null 2>&1; then
    printf '%s\n' "$launcher"
  else
    printf '/proc/%s/exe\n' "$pid"
  fi
}

refresh_policy() {
  local exe="$1"
  "$exe" --refresh-platform-policy --no-startup-window >/dev/null 2>&1 &
  disown
}

# The browser's own preferences outrank the policy seed, and any one of these
# suppresses it outright:
#   is_grayscale2  — the "grayscale" swatch, which greys the whole palette and
#                    ignores the seed entirely (Helium ships with it on)
#   user_color2    — a seed picked in the browser, which wins over the policy
#   extensions.theme — an installed or auto-generated theme, which wins over both
#
# Only safe while the browser is closed: a running one holds Preferences in
# memory and rewrites the file on exit, so a live edit would just be discarded.
repair_prefs() {
  local prefs="$1/Default/Preferences" tmp
  [[ -f "$prefs" ]] || return 0

  tmp="$prefs.caelestia-tmp"
  if jq --argjson cs "$COLOR_SCHEME" '
    .extensions.theme.id = "" |
    .extensions.theme.use_system = false |
    .extensions.theme.use_custom = false |
    .browser.theme.color_scheme = $cs |
    .browser.theme.color_scheme2 = $cs |
    del(
      .browser.theme.user_color, .browser.theme.user_color2,
      .browser.theme.is_grayscale, .browser.theme.is_grayscale2
    )
  ' "$prefs" >"$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
    mv "$tmp" "$prefs"
  else
    rm -f "$tmp"
  fi
}

for entry in "${BROWSERS[@]}"; do
  IFS='|' read -r comm launcher profile <<<"$entry"
  [[ -d "$profile" ]] || continue

  # Only poke a browser that is already up: --refresh-platform-policy against a
  # closed one starts a windowless background process instead of doing nothing.
  pid=$(pgrep -x "$comm" 2>/dev/null | head -1)
  if [[ -n "$pid" ]]; then
    refresh_policy "$(browser_exe "$launcher" "$pid")"
  else
    repair_prefs "$profile"
  fi
done
