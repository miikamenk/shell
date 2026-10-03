# fish colours, rendered by caelestia from the current scheme.
#
# Lands in ~/.config/fish/conf.d/ (as a symlink). Files there are sourced in
# alphabetical order, so this sorts after fish's own `fish_frozen_theme.fish`
# (c < f is wrong — but `--global` beats the universal scope those older
# `set -U fish_color_*` values live in, so it wins regardless of order).

# ── Syntax highlighting ──
set --global fish_color_normal {{ onSurface.hex }}
set --global fish_color_command {{ primary.hex }}
set --global fish_color_keyword {{ tertiary.hex }}
set --global fish_color_quote {{ success.hex }}
set --global fish_color_redirection {{ secondary.hex }}
set --global fish_color_end {{ tertiary.hex }}
set --global fish_color_error {{ error.hex }}
set --global fish_color_param {{ onSurfaceVariant.hex }}
set --global fish_color_option {{ secondary.hex }}
set --global fish_color_comment {{ outline.hex }}
set --global fish_color_operator {{ tertiary.hex }}
set --global fish_color_escape {{ secondary.hex }}
set --global fish_color_autosuggestion {{ outlineVariant.hex }}
set --global fish_color_cancel {{ error.hex }}
set --global fish_color_valid_path --underline

# ── Selection & search ──
set --global fish_color_selection {{ onSurface.hex }} --background={{ surfaceVariant.hex }}
set --global fish_color_search_match --background={{ surfaceContainerHigh.hex }}
set --global fish_color_history_current {{ primary.hex }} --bold

# ── Prompt ──
set --global fish_color_cwd {{ primary.hex }}
set --global fish_color_cwd_root {{ error.hex }}
set --global fish_color_user {{ tertiary.hex }}
set --global fish_color_host {{ primary.hex }}
set --global fish_color_host_remote {{ tertiary.hex }}
set --global fish_color_status {{ error.hex }}

# ── Completion pager ──
set --global fish_pager_color_prefix {{ primary.hex }} --bold
set --global fish_pager_color_completion {{ onSurface.hex }}
set --global fish_pager_color_description {{ outline.hex }}
set --global fish_pager_color_progress {{ onSurfaceVariant.hex }} --background={{ surfaceContainer.hex }}
set --global fish_pager_color_selected_background --background={{ surfaceVariant.hex }}
set --global fish_pager_color_selected_prefix {{ primary.hex }} --bold
set --global fish_pager_color_selected_completion {{ onSurface.hex }}
set --global fish_pager_color_selected_description {{ onSurfaceVariant.hex }}
