-- Colours for the hyprglass plugin, rendered by caelestia from the current
-- scheme.
--
-- Raw palette tokens only. The blend that turns these into a glass tint lives
-- in ~/.config/hypr/custom/plugins.lua, because the template language has no
-- arithmetic and the recipe has to stay readable next to the preset it feeds.
--
-- plugins.lua reads both a `dark` and a `light` table, but caelestia publishes
-- one mode at a time, so both carry the active scheme. The desktop is in that
-- mode, so the preset actually in use is the one with the right colours.
-- Current mode: {{ mode }}.

local scheme = {
	source = "{{ primary_paletteKeyColor.hex }}",
	background = "{{ background.hex }}",
	primary_container = "{{ primaryContainer.hex }}",
}

return {
	dark = scheme,
	light = scheme,
}
