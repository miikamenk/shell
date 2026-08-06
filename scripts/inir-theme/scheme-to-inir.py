#!/usr/bin/env python3
"""Translate caelestia's current scheme into the files iNiR's theming modules read.

iNiR's third-party appliers (scripts/colors/modules/*.sh) all consume the same
small set of generated files under $XDG_STATE_HOME/quickshell/user/generated.
caelestia keeps its scheme in a single scheme.json with camelCase, hash-less
hex. This writes the iNiR-shaped files from that scheme so the modules run
unmodified and every app ends up on caelestia's live colours.

app-palette.json's derived app_* tokens are produced by importing iNiR's own
build_app_palette(), so the contract stays in sync with iNiR rather than being
reimplemented here.
"""

from __future__ import annotations

import argparse
import contextlib
import io
import json
import os
import re
import sys
from pathlib import Path

XDG_CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
XDG_STATE_HOME = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")

CAELESTIA_STATE = XDG_STATE_HOME / "caelestia"
INIR_GENERATED = XDG_STATE_HOME / "quickshell/user/generated"

# Order and membership mirror iNiR's material_colors.scss so anything that
# pairs names to values positionally sees the same file it always has.
SCSS_KEYS = [
    "primary_paletteKeyColor",
    "secondary_paletteKeyColor",
    "tertiary_paletteKeyColor",
    "neutral_paletteKeyColor",
    "neutral_variant_paletteKeyColor",
    "background",
    "onBackground",
    "surface",
    "surfaceDim",
    "surfaceBright",
    "surfaceContainerLowest",
    "surfaceContainerLow",
    "surfaceContainer",
    "surfaceContainerHigh",
    "surfaceContainerHighest",
    "onSurface",
    "surfaceVariant",
    "onSurfaceVariant",
    "inverseSurface",
    "inverseOnSurface",
    "outline",
    "outlineVariant",
    "shadow",
    "scrim",
    "surfaceTint",
    "primary",
    "onPrimary",
    "primaryContainer",
    "onPrimaryContainer",
    "inversePrimary",
    "secondary",
    "onSecondary",
    "secondaryContainer",
    "onSecondaryContainer",
    "tertiary",
    "onTertiary",
    "tertiaryContainer",
    "onTertiaryContainer",
    "error",
    "onError",
    "errorContainer",
    "onErrorContainer",
    "primaryFixed",
    "primaryFixedDim",
    "onPrimaryFixed",
    "onPrimaryFixedVariant",
    "secondaryFixed",
    "secondaryFixedDim",
    "onSecondaryFixed",
    "onSecondaryFixedVariant",
    "tertiaryFixed",
    "tertiaryFixedDim",
    "onTertiaryFixed",
    "onTertiaryFixedVariant",
    "success",
    "onSuccess",
    "successContainer",
    "onSuccessContainer",
] + [f"term{i}" for i in range(16)]

# camelCase keys that make up iNiR's palette.json, in its own order.
PALETTE_KEYS = [
    "primary",
    "onPrimary",
    "primaryContainer",
    "onPrimaryContainer",
    "primaryFixed",
    "primaryFixedDim",
    "onPrimaryFixed",
    "onPrimaryFixedVariant",
    "secondary",
    "onSecondary",
    "secondaryContainer",
    "onSecondaryContainer",
    "secondaryFixed",
    "secondaryFixedDim",
    "onSecondaryFixed",
    "onSecondaryFixedVariant",
    "tertiary",
    "onTertiary",
    "tertiaryContainer",
    "onTertiaryContainer",
    "tertiaryFixed",
    "tertiaryFixedDim",
    "onTertiaryFixed",
    "onTertiaryFixedVariant",
    "error",
    "onError",
    "errorContainer",
    "onErrorContainer",
    "background",
    "onBackground",
    "surface",
    "onSurface",
    "surfaceDim",
    "surfaceBright",
    "surfaceVariant",
    "onSurfaceVariant",
    "surfaceContainerLowest",
    "surfaceContainerLow",
    "surfaceContainer",
    "surfaceContainerHigh",
    "surfaceContainerHighest",
    "outline",
    "outlineVariant",
    "inverseSurface",
    "inverseOnSurface",
    "inversePrimary",
    "shadow",
    "scrim",
    "surfaceTint",
    "success",
    "onSuccess",
    "successContainer",
    "onSuccessContainer",
]

# Sane M3 dark fallbacks for tokens a hand-written scheme may omit. Only used
# when the scheme itself has no value and no obvious in-scheme substitute.
FALLBACK_SOURCES = {
    "primary_paletteKeyColor": ("primary",),
    "secondary_paletteKeyColor": ("secondary",),
    "tertiary_paletteKeyColor": ("tertiary",),
    "neutral_paletteKeyColor": ("outline", "onSurfaceVariant"),
    "neutral_variant_paletteKeyColor": ("outlineVariant", "surfaceVariant"),
    "background": ("surface",),
    "onBackground": ("onSurface",),
    "surface": ("background",),
    "surfaceDim": ("surface", "background"),
    "surfaceBright": ("surfaceContainerHighest", "surface"),
    "surfaceContainerLowest": ("surface", "background"),
    "surfaceContainerLow": ("surfaceContainer", "surface"),
    "surfaceContainer": ("surfaceContainerLow", "surface"),
    "surfaceContainerHigh": ("surfaceContainer",),
    "surfaceContainerHighest": ("surfaceContainerHigh",),
    "surfaceVariant": ("surfaceContainerHigh", "surface"),
    "onSurfaceVariant": ("onSurface",),
    "inverseSurface": ("onSurface",),
    "inverseOnSurface": ("surface",),
    "outlineVariant": ("surfaceVariant", "outline"),
    "surfaceTint": ("primary",),
    "inversePrimary": ("primaryContainer", "primary"),
    "shadow": (),
    "scrim": (),
}

HEX_RE = re.compile(r"^#?[0-9a-fA-F]{6}$")


def snake(name: str) -> str:
    """onSurfaceVariant -> on_surface_variant (matches iNiR's palette.json keys)."""
    if name.endswith("_paletteKeyColor"):
        return name
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def norm(value: str) -> str:
    """Normalise a scheme colour to iNiR's uppercase #RRGGBB."""
    value = value.strip()
    if not HEX_RE.match(value):
        raise ValueError(f"not a 6-digit hex colour: {value!r}")
    return "#" + value.lstrip("#").upper()


def resolve(colours: dict[str, str], key: str) -> str:
    if key in colours:
        return colours[key]
    for alt in FALLBACK_SOURCES.get(key, ()):
        if alt in colours:
            return colours[alt]
    return "#000000"


def load_scheme(path: Path | None, from_env: bool) -> dict:
    """Read the scheme from caelestia's state file, or the postHook's SCHEME_* env.

    The state file is the default even under the postHook: runs are serialised by
    a lock, so a queued run must pick up the newest scheme rather than replay the
    stale one it was spawned with.
    """
    env_colours = os.environ.get("SCHEME_COLOURS")
    if from_env and path is None and env_colours:
        return {
            "name": os.environ.get("SCHEME_NAME", ""),
            "flavour": os.environ.get("SCHEME_FLAVOUR", ""),
            "mode": os.environ.get("SCHEME_MODE", "dark"),
            "variant": os.environ.get("SCHEME_VARIANT", ""),
            "colours": json.loads(env_colours),
        }

    path = path or CAELESTIA_STATE / "scheme.json"
    return json.loads(path.read_text())


def load_build_app_palette(inir_dir: Path):
    """Import iNiR's generator just to borrow build_app_palette().

    It generates on import, so feed it a cheap --color run and swallow its
    stdout. ~60ms, and it keeps the app_* contract owned by iNiR.
    """
    import importlib.util

    generator = inir_dir / "scripts/colors/generate_colors_material.py"
    spec = importlib.util.spec_from_file_location("inir_generate_colors", generator)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {generator}")

    module = importlib.util.module_from_spec(spec)
    saved_argv = sys.argv
    sys.argv = ["generate_colors_material.py", "--color", "#808080", "--mode", "dark"]
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            spec.loader.exec_module(module)
    finally:
        sys.argv = saved_argv

    return module.build_app_palette


def transparency_enabled() -> bool:
    shell_config = XDG_CONFIG_HOME / "caelestia/shell.json"
    try:
        config = json.loads(shell_config.read_text())
    except (OSError, json.JSONDecodeError):
        return False
    return bool(config.get("appearance", {}).get("transparency", {}).get("enabled", False))


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.tmp")
    tmp.write_text(content)
    os.replace(tmp, path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--inir-dir",
        type=Path,
        required=True,
        help="root of the iNiR checkout providing scripts/colors",
    )
    parser.add_argument(
        "--scheme",
        type=Path,
        default=None,
        help="scheme.json to read (default: caelestia's state scheme.json)",
    )
    parser.add_argument(
        "--from-env",
        action="store_true",
        help="read the scheme from caelestia's postHook $SCHEME_* env instead",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=INIR_GENERATED,
        help=f"where to write iNiR's generated files (default: {INIR_GENERATED})",
    )
    parser.add_argument(
        "--wallpaper",
        type=Path,
        default=None,
        help="current wallpaper path (default: caelestia's state)",
    )
    args = parser.parse_args()

    scheme = load_scheme(args.scheme, args.from_env)
    mode = scheme.get("mode", "dark")
    raw = scheme.get("colours") or {}
    if not raw:
        print("scheme has no colours", file=sys.stderr)
        return 1

    colours = {}
    for name, value in raw.items():
        try:
            colours[name] = norm(value)
        except ValueError:
            continue  # non-colour extras (klink flags etc. are colours; junk isn't)

    missing = [k for k in SCSS_KEYS if k not in colours]
    if missing:
        print(f"scheme missing {len(missing)} token(s), substituting: {' '.join(missing)}", file=sys.stderr)

    filled = {key: resolve(colours, key) for key in SCSS_KEYS}

    # material_colors.scss
    scss = [
        f"$darkmode: {'True' if mode == 'dark' else 'False'};",
        f"$transparent: {'True' if transparency_enabled() else 'False'};",
    ]
    scss += [f"${key}: {filled[key]};" for key in SCSS_KEYS]
    atomic_write(args.out_dir / "material_colors.scss", "\n".join(scss) + "\n")

    # palette.json / terminal.json / colors.json
    palette = {snake(key): filled[key] for key in PALETTE_KEYS}
    terminal = {f"term{i}": filled[f"term{i}"] for i in range(16)}
    colors = {**palette, **terminal}

    build_app_palette = load_build_app_palette(args.inir_dir)
    app_palette = build_app_palette(palette)

    for name, data in (
        ("palette.json", palette),
        ("app-palette.json", app_palette),
        ("colors.json", colors),
        ("terminal.json", terminal),
    ):
        atomic_write(args.out_dir / name, json.dumps(data, indent=2) + "\n")

    # theme-meta.json / color.txt — chrome and steam read mode and the seed here
    wallpaper = args.wallpaper
    if wallpaper is None:
        try:
            wallpaper = Path((CAELESTIA_STATE / "wallpaper/path.txt").read_text().strip())
        except OSError:
            wallpaper = None

    seed = filled["primary_paletteKeyColor"]
    meta = {
        "source": "image" if wallpaper else "color",
        "source_path": str(wallpaper) if wallpaper else None,
        "seed_color": seed,
        "mode": mode,
        "scheme": scheme.get("variant") or scheme.get("name") or "",
        "transparent": transparency_enabled(),
        "generated_by": "caelestia scripts/inir-theme/scheme-to-inir.py",
        "caelestia_scheme": scheme.get("name", ""),
        "caelestia_flavour": scheme.get("flavour", ""),
    }
    atomic_write(args.out_dir / "theme-meta.json", json.dumps(meta, indent=2) + "\n")
    atomic_write(args.out_dir / "color.txt", seed)

    if wallpaper:
        atomic_write(args.out_dir / "wallpaper/path.txt", str(wallpaper) + "\n")

    print(
        f"wrote iNiR colour inputs to {args.out_dir} "
        f"(scheme={scheme.get('name', '?')}/{scheme.get('flavour', '?')} mode={mode})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
