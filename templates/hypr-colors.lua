-- Hyprland border colours, rendered by caelestia from the current scheme.

hl.config({
	general = {
		col = {
			-- Focus ring: accent on the focused window, transparent otherwise
			active_border = "rgba({{ primary.hex }}ff)",
			inactive_border = "rgba({{ surfaceContainerLow.hex }}00)",
		},
	},
	misc = {
		background_color = "rgba({{ surface.hex }}FF)",
	},
})

hl.window_rule({
	match = { pin = 1 },
	border_color = "rgba({{ primary.hex }}AA) rgba({{ primary.hex }}77)",
})
