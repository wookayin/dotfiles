-- https://wezfurlong.org/wezterm/config/files.html

-- Note: If you are using nightly, use the following command to upgrade
-- $ brew upgrade --cask wezterm-nightly --no-quarantine --greedy-latest

-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}
local M = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end


-- Config starts!
-- https://wezfurlong.org/wezterm/config/lua/config/index.html

function M.setup_appearances()
  -- Appearances: https://wezfurlong.org/wezterm/config/appearance.html
  config.adjust_window_size_when_changing_font_size = false
  config.hide_tab_bar_if_only_one_tab = true
  config.window_padding = {  -- in pixels
    left = 5, right = 5,
    top = 8, bottom = 8,
  }
end

function M.setup_fonts()
  -- Fonts: https://wezfurlong.org/wezterm/config/fonts.html
  config.font = wezterm.font_with_fallback {
    { family = 'JetBrainsMono NFM', weight = 'Light' },
    { family = 'JetBrainsMono Nerd Font Mono', weight = 'Light' },
    'Hack Nerd Font Mono',
    'Monaco',
    'Apple SD Gothic Neo',  -- for Korean (한글) letters
    'Apple Color Emoji'  -- Use macOS emoji, not Noto Color Emoji
  }
  config.cell_width = 0.85
  config.line_height = 0.89
  config.font_size = 18
  -- No ligatures
  config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }
end

function M.setup_keys()
  -- https://wezfurlong.org/wezterm/config/default-keys.html
  -- To see default keymaps list: $ wezterm show-keys --lua
  local act = wezterm.action
  config.keys = {
    -- Toggle fullscreen: not cmd-Enter, use cmd-Enter
    { mods = 'ALT', key = 'Enter', action = act.DisableDefaultAssignment },
    { mods = 'CMD', key = 'Enter', action = act.ToggleFullScreen },
  }

  -- https://wezfurlong.org/wezterm/config/lua/config/use_ime.html
  -- See https://github.com/wez/wezterm/issues/4061
  -- When using macOS IME (true), successive key repeat will get stuck
  -- unless the ApplePressAndHoldEnabled option is turned off.
  -- When turning off `use_ime`, key repeat will work but CJK input will be broken.
  config.use_ime = true

  -- https://wezfurlong.org/wezterm/config/keyboard-concepts.html#dead-keys
  config.use_dead_keys = false
end

function M.setup_misc()
  config.scrollback_lines = 10000
end

-- Debugging mode
function M.setup_debug()
  if false then
    config.debug_key_events = true
  end
end


-- Invoke all the M.setup_xxx functions.
for key, _ in pairs(M) do
  if string.sub(key, 1, 5) == 'setup' then
    M[key]()
  end
end
return config
