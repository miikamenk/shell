-- base16 palette for nvim, rendered by caelestia from the current scheme.

local M = {}

function M.setup()
	require("base16-colorscheme").setup({
		-- Background tones
		base00 = "#{{ surface.hex }}", -- Default Background
		base01 = "#{{ surfaceContainer.hex }}", -- Lighter Background (status bars)
		base02 = "#{{ secondaryContainer.hex }}", -- Selection Background
		base03 = "#{{ outline.hex }}", -- Comments, Invisibles

		-- Foreground tones
		base04 = "#{{ onSurfaceVariant.hex }}", -- Dark Foreground (status bars)
		base05 = "#{{ onSurface.hex }}", -- Default Foreground
		base06 = "#{{ inverseOnSurface.hex }}", -- Light Foreground
		base07 = "#{{ onBackground.hex }}", -- Lightest Foreground

		-- Accents
		base08 = "#{{ error.hex }}", -- Variables, XML Tags, Errors
		base09 = "#{{ tertiary.hex }}", -- Integers, Constants
		base0A = "#{{ secondary.hex }}", -- Classes, Search Background
		base0B = "#{{ primary.hex }}", -- Strings, Diff Inserted
		base0C = "#{{ tertiaryFixed.hex }}", -- Regex, Escape Chars
		base0D = "#{{ primaryFixed.hex }}", -- Functions, Methods
		base0E = "#{{ secondaryFixed.hex }}", -- Keywords, Storage
		base0F = "#{{ onErrorContainer.hex }}", -- Deprecated, Embedded
	})
end

-- Reload on SIGUSR1, for a running nvim to pick up a scheme change.
local signal = vim.uv.new_signal()
signal:start(
	"sigusr1",
	vim.schedule_wrap(function()
		package.loaded["matugen"] = nil
		require("matugen").setup()
	end)
)

return M
