# iNiR theming bridge

Reuses iNiR's third-party colour appliers from caelestia, so changing wallpaper
(or scheme) in caelestia re-themes every app iNiR knows how to theme, using
caelestia's live colours.

## How it hangs together

```
caelestia wallpaper -f <img>
  └─ caelestia-cli applies its own targets (hypr, term sequences, discord, …)
     └─ theme.postHook  →  apply.sh                    (detached, lock-serialised)
                             ├─ scheme-to-inir.py      caelestia scheme.json → iNiR's inputs
                             ├─ iNiR applycolor.sh     runs every enabled iNiR target
                             └─ SDDM background sync   (see below)
```

Colours only track the wallpaper when caelestia's scheme is `dynamic`
(`caelestia scheme set -n dynamic`). Under a fixed scheme like
`catppuccin/mocha` the hook still fires on every wallpaper change and
re-applies, but the palette itself doesn't move.

`scheme-to-inir.py` translates `~/.local/state/caelestia/scheme.json` into the
files iNiR's modules read from `$XDG_STATE_HOME/quickshell/user/generated`:

| File | Contents |
| --- | --- |
| `material_colors.scss` | `$darkmode`, `$transparent`, every M3 token, `$term0`–`$term15` |
| `palette.json` | M3 tokens, snake_case, `#RRGGBB` |
| `app-palette.json` | `palette.json` plus iNiR's derived `app_*` tokens |
| `colors.json` | `palette.json` plus the terminal colours |
| `terminal.json` | `term0`–`term15` |
| `theme-meta.json` | mode, seed colour, source wallpaper |
| `color.txt` | seed colour (Chromium generates GM3 from this) |
| `wallpaper/path.txt` | current wallpaper |

The derived `app_*` tokens come from importing iNiR's own `build_app_palette()`
rather than reimplementing it, so the contract can't drift.

## Usage

```bash
./apply.sh                      # convert + run all targets enabled in iNiR's config
./apply.sh terminals editors    # only these targets
./apply.sh --list               # available targets
./apply.sh --convert-only       # refresh the colour files, run nothing
```

Log: `$XDG_STATE_HOME/caelestia/inir-theme.log`.

## Install

`~/.config/caelestia/cli.json`:

```json
{
  "theme": {
    "enableGtk": false,
    "postHook": "setsid --fork \"$HOME/.config/quickshell/caelestia/scripts/inir-theme/apply.sh\" >/dev/null 2>&1"
  }
}
```

`theme.postHook` (not `wallpaper.postHook`) so manual `caelestia scheme set`
also propagates.

The hook detaches on purpose. caelestia-cli holds an exclusive `theme.lock` for
the duration of the hook and *drops* concurrent scheme changes rather than
queueing them, so a synchronous multi-second pipeline would silently swallow
wallpaper switches. `apply.sh` takes its own `flock` instead, and each run reads
`scheme.json` fresh after acquiring it — a queued run therefore applies the
newest scheme, never a stale one.

## Who owns what

Most targets are namespaced and coexist fine — caelestia writes
`zed/themes/caelestia.json`, `spicetify/Themes/caelestia/`, `qtengine/`; iNiR
writes its own theme names, `qt5ct`/`qt6ct`/`Kvantum`. Both can be on.

Two files have a single owner:

- **`~/.config/gtk-{3,4}.0/gtk.css`** — both write it whole. `enableGtk: false`
  above hands it to iNiR, which emits the full libadwaita variable set, thunar
  CSS, and `settings.ini` sync. Set it back to `true` and drop iNiR's
  `appearance.wallpaperTheming.enableAppsAndShell` to reverse that.
- **`~/.config/cava/config`** — caelestia keeps it, since iNiR's
  `appearance.wallpaperTheming.enableCava` is off. Flip both if you want iNiR's
  cover-art gradient instead.

One iNiR module needed a nudge rather than a flag: `sync-pixel-sddm.py` takes its
colours from the generated palette (so they follow caelestia) but its *background
image* from iNiR's `config.json`, which this bridge deliberately does not write.
`apply.sh` therefore copies caelestia's wallpaper into
`/usr/share/sddm/themes/ii-pixel/assets/background.png` itself, after the sddm
target runs and only if that dir exists and is writable.

Which iNiR targets run is decided entirely by iNiR's own config
(`~/.config/inir/config.json` → `appearance.wallpaperTheming.*`) — this bridge
adds no second switchboard.

## Shared state

The generated files land in iNiR's state dir, which iNiR's shell also reads. One
desktop has one theme at a time, so that's intended: whichever shell you last
changed the wallpaper in owns the third-party colours. The side effect is that
iNiR's *own* shell colours will show caelestia's scheme until you change the
wallpaper from iNiR again. To isolate instead, run `apply.sh` with
`XDG_STATE_HOME` pointed elsewhere (note `generate_terminal_configs.py`
hardcodes one path and won't follow).

## Requirements

- iNiR checked out at `~/.config/quickshell/inir` (or `ii`, or
  `~/Projects/Personal/iNiR`; override with `CAELESTIA_INIR_DIR`)
- iNiR's venv at `$XDG_STATE_HOME/quickshell/.venv` for `materialyoucolor`
  (or `INIR_VENV`/`ILLOGICAL_IMPULSE_VIRTUAL_ENV`)

`apply.sh` exits 0 with a log line if iNiR isn't present, so the hook is safe to
leave configured.
