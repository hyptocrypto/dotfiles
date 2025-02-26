local wezterm = require("wezterm")
local config = {}

config.font = wezterm.font("JetBrains Mono")
config.window_background_opacity = 0.9 -- Adjust between 0.1 (more transparent) to 1.0 (opaque)
config.macos_window_background_blur = 20 -- Only for macOS, adjust for blur strength
config.font_size = 15
config.color_scheme = "nord"
config.harfbuzz_features = {
	"liga=0", -- Disables standard ligatures
	"calt=0", -- Disables contextual alternates
}
config.keys = {
	-- Move to the next tab
	{
		key = "Escape",
		mods = "SHIFT",
		action = wezterm.action.ActivateTabRelative(1),
	},
	-- Create a new pane
	{
		key = "d",
		mods = "SUPER|SHIFT", -- Cmd+Shift+D (Mac) / Win+Shift+D (Windows) splits horizontally
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "d",
		mods = "SUPER", -- Cmd+Shift+S (Mac) / Win+Shift+S (Windows) splits vertically
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},

	-- Switch panes with Super (⌘) + Esc
	{
		key = "Escape",
		mods = "CTRL",
		action = wezterm.action.ActivatePaneDirection("Next"), -- Move to the next pane
	},

	-- Close the current pane, or close the tab if it's the last pane
	{
		key = "w",
		mods = "SUPER",
		action = wezterm.action_callback(function(window, pane)
			local tab = window:active_tab()
			if #tab:panes() > 1 then
				window:perform_action(wezterm.action.CloseCurrentPane({ confirm = false }), pane)
			else
				window:perform_action(wezterm.action.CloseCurrentTab({ confirm = false }), pane)
			end
		end),
	},
}
return config
