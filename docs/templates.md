# Theme templates

Extra apps themed from caelestia's scheme, using caelestia's own template
mechanism. No second colour pipeline — `caelestia scheme set` and `caelestia
wallpaper` already render these as part of applying a theme. One hook survives,
for Chromium alone, because a rendered file cannot poke a running browser; see
below.

Previously this was a bridge that ran iNiR's appliers against caelestia's
colours. That meant two colour models in play, and they disagreed: iNiR assumes
`term0` *is* the terminal background, caelestia keeps ANSI black and the surface
apart, so every new shell repainted its window in ANSI black. These templates
use caelestia's tokens directly, so there is nothing left to disagree with.

## How it hangs together

```
caelestia scheme set / caelestia wallpaper
  └─ apply_colours()                     caelestia/utils/theme.py
       ├─ built-in targets               gtk, qt, fuzzel, btop, cava, discord,
       │                                 spicetify, hypr scheme, term sequences
       ├─ apply_user_templates()         ~/.config/caelestia/templates/*
       │                                   -> ~/.local/state/caelestia/theme/*
       └─ postHook                       scripts/chromium-theme-refresh.sh
```

`~/.config/caelestia/templates` is a symlink to the repo's `templates/`, so the
templates stay in git. Rendered output all lands flat in
`~/.local/state/caelestia/theme/`, named after the template, and each app's
config is a symlink into it.

Only templates live in `templates/` — caelestia renders *every* file it finds
there, which is why this document sits in `docs/` instead.

## Wiring

| Template | Consumer |
| --- | --- |
| `caelestia-colors.fish` | symlink `~/.config/fish/conf.d/caelestia-colors.fish` |
| `kitty.conf` | `include`d directly from `~/.config/kitty/kitty.conf` |
| `alacritty.toml` | symlink `~/.config/alacritty/colors.toml` (already `import`ed) |
| `hypr-colors.lua` | symlink `~/.config/hypr/hyprland/colors.lua` |
| `hyprglass-colors.lua` | symlink `~/.config/hypr/hyprland/hyprglass-colors.lua` |
| `hyprlock-colors.conf` | symlink `~/.config/hypr/hyprlock/colors.conf` |
| `nvim-matugen.lua` | symlink `~/.config/nvim/lua/matugen.lua` |
| `herdr-config.toml` | symlink `~/.config/herdr/config.toml` |
| `chromium-policy.json` | symlink `/etc/chromium/policies/managed/caelestia.json`, plus the postHook below |
| `niri-borders.kdl` | symlink `~/.config/niri/config.d/99-generated-colors.kdl` |
| `firefox-materialfox.css` | none — no Firefox profile here |
| `steam-millennium.css` | none — Millennium not installed |
| `homeassistant.sh` | none — run it by hand |

Re-create a symlink with, e.g.:

```bash
ln -sfn ~/.local/state/caelestia/theme/kitty.conf ~/.config/kitty/theme.conf
```

The Chromium one is the exception: its target is under `/etc`, so it takes one
privileged step, once, after which nothing in the pipeline needs elevation
again. Re-create it with:

```bash
sudo mkdir -p /etc/chromium/policies/managed
sudo chmod a+rwx /etc/chromium/policies/managed
ln -sfn ~/.local/state/caelestia/theme/chromium-policy.json \
  /etc/chromium/policies/managed/caelestia.json
```

## Template syntax

caelestia's, not matugen's: `{{ token.form }}` where `form` is `hex`,
`hexalpha`, `rgb` or `rgbalpha`, plus `{{ mode }}` for `dark`/`light`. Token
names are the camelCase keys of `~/.local/state/caelestia/scheme.json` —
`onSurface`, `surfaceContainerHigh`, `primary_paletteKeyColor`, `term0`–`term15`
and whatever extras a scheme carries.

`hex` has **no** leading `#`, so templates write `#{{ surface.hex }}`. `rgb`
emits a full `rgb(r,g,b)`, so it is not wrapped.

Two things matugen's syntax had and this does not:

- **No `app_*` tokens.** iNiR derived a second palette of them; here they map
  onto the Material tokens they came from — `app_headerbar_bg` is `background`,
  `app_card_bg` is `surfaceContainerLow`, `app_accent` is `primary`, and so on.
- **No `.dark`/`.light` variants.** caelestia publishes one mode at a time.
  `hyprglass-colors.lua` needs both tables, so both carry the active scheme; the
  desktop is in that mode, so the preset in use has the right colours.

## Terminals

The terminal templates deliberately use the same mapping as `gen_sequences()` in
caelestia's `theme.py`: foreground `onSurface`, background `surface`, cursor
`secondary`, colours 0–15 from `term0`–`term15`.

That matters. A terminal reads its config when a window opens, and then the
shell's first prompt cats `~/.local/state/caelestia/sequences.txt`. If the two
disagreed, every new window and tab would visibly repaint on the first prompt —
which is exactly what the old bridge did.

`~/.bashrc`, `~/.zshrc` and `fish/config.fish` cat caelestia's sequences file,
not iNiR's.

## Not covered

- **SDDM.** The `ii-pixel` theme lives in `/usr/share/sddm/themes/`, and the
  `sddm` user cannot read through `/home/menk` (mode `0700`), so a symlink into
  the state dir would break the login screen rather than theme it. Syncing it
  needs a privileged copy out of `$HOME` on every change — a script, which is
  what this replaced. Its colours are frozen at whatever last wrote them.
- **VSCode, Zed, OpenCode, Spicetify, pear-desktop.** caelestia has built-in
  targets for Zed and Spicetify; the rest were iNiR features with nothing
  installed to consume them.

## caelestia settings this relies on

`~/.config/caelestia/cli.json`:

```json
{
  "theme": {
    "enableChromium": false,
    "postHook": "$HOME/.config/quickshell/caelestia/scripts/chromium-theme-refresh.sh"
  }
}
```

There is no `enableGtk: false` any more — GTK is caelestia's again.

## Chromium

`enableChromium` is off because caelestia's built-in `apply_chromium` writes its
policy through `sudo -n tee`, which needs passwordless sudo this machine does
not have — it has silently done nothing all along. The policy dir is `0777`, so
the symlink above writes it with no elevation at all. The built-in also seeds
Chromium with `surface`; `BrowserThemeColor` is a *seed* that Chromium runs
Material You over, and a near-black near-neutral surface comes back out as stock
dark grey, so `chromium-policy.json` uses the palette key colour instead.

Rendering the template is the whole write, but it is not the whole update, and
the two remaining pieces are why `scripts/chromium-theme-refresh.sh` exists:

- **Live repaint.** Chromium reads platform policy once at startup and caches
  it, so a freshly rendered seed sits on disk unread. `chromium
  --refresh-platform-policy --no-startup-window` makes a running instance
  re-read it — same trick iNiR used. The hook only does this to a browser that
  is already up: run against a closed one, that flag starts a windowless
  background process instead of doing nothing.
- **Preferences that outrank the seed.** There is no `BrowserColorScheme` policy
  — not in Chromium 150 or Helium 0.15; the name is absent from both binaries,
  and a policy file carrying it loads with the key silently discarded
  (`Enterprise.Policies` counts two, not three). Everything about how the seed
  is *used* lives in preferences instead, and any of these suppresses it:
  `browser.theme.is_grayscale2` greys the palette and ignores the seed outright,
  `user_color2` is a seed picked in the browser and wins over the policy, and
  `extensions.theme.*` is an installed or auto-generated theme that wins over
  both. The hook clears all three and pins `color_scheme2` to `0`, "follow the
  system", so dark/light tracks the XDG portal — which caelestia already drives,
  via the dconf `color-scheme` write in `apply_gtk`.

Preferences are only rewritten while the browser is **closed**. A running
browser holds them in memory and rewrites the file on exit, so a live edit would
just be discarded — hence the split: policy refresh for a running browser,
preference repair for a closed one. A browser that has one of the overriding
preferences set therefore needs to be closed once before it picks up the theme;
after that, scheme changes land live.

### Which browser

The daily driver here is **Helium**, and it is the awkward case:

- It is an **AppImage**, so there is no launcher on `PATH` and its mount path is
  regenerated on every launch — nothing stable to hardcode. The hook resolves
  the executable from `/proc/<pid>/exe` of the running process instead, which is
  also why matching is on `comm` rather than a binary name.
- Its profile is `~/.config/net.imput.helium`, not `~/.config/chromium`.
- It ships with `is_grayscale2` **on**, which is what kept the theme grey no
  matter what the policy said.

It reads `/etc/chromium/policies/managed` like stock Chromium, though — same
directory, same file, no second symlink — and it supports both
`BrowserThemeColor` and `--refresh-platform-policy`. It does *not* have the
`--set-user-color` / `--set-color-scheme` flags that Omarchy's Chromium fork
adds and that iNiR used for instant updates, so policy refresh is the only live
path.

One wart: `_comment` is not a policy either, so `chrome://policy` lists it as an
unknown one. It stays because it is the only explanation a reader lands on if
they find the file in `/etc` rather than this repo.
