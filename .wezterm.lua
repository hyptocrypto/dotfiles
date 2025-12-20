local wezterm = require("wezterm")
local config = {}

config.font = wezterm.font("JetBrains Mono", { weight = "DemiBold" })
config.window_background_opacity = 0.9 -- Adjust between 0.1 (more transparent) to 1.0 (opaque)
config.macos_window_background_blur = 20 -- Only for macOS, adjust for blur strength
config.max_fps = 120
config.enable_tab_bar = true
config.enable_scroll_bar = true
config.font_size = 15
config.color_scheme = "nord"
config.inactive_pane_hsb = {
	saturation = 0.8,
	brightness = 0.3,
}
config.window_padding = {
	left = 0,
	right = 0,
	top = 4,
	bottom = 0,
}
config.harfbuzz_features = {
	"liga=0", -- Disables standard ligatures
	"calt=0", -- Disables contextual alternates
}
config.keys = {

	-- disable default close-pane binding
	{ key = "c", mods = "LEADER", action = "DisableDefaultAssignment" },
	{ key = "p", mods = "CTRL", action = wezterm.action.ActivateCopyMode },

	-- Move to the next tab
	{
		key = "Escape",
		mods = "SHIFT",
		action = wezterm.action.ActivateTabRelative(1),
	},
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

	{
		key = "h",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "j",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		key = "k",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = "l",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Right"),
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
