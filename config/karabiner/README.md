# Configs for Karabiner

Based on Karabiner-Elements 12.5.0


## Setup

Manually copy <s>or symlink</s> to the following location:

```
~/.config/karabiner/karabiner.json
```

If `karabiner.json` is a symbolic link, Karabiner-Elements may create a copy of `karabiner.json` and corrupt the link and the source file.

```bash
\cp -f ~/.dotfiles/config/karabiner/karabiner.json ~/.config/karabiner/karabiner.json
killall Karabiner-Elements; open /Applications/Karabiner-Elements.app
```


## Features

- Exchange Caps Lock <-> Left Control  (works for both Realforce and Internal Keyboard)
- Exchange Left option <-> Left command ON Realforce
- Right command -> F18  (should be mapped to switching input source)
- Right option -> F18 ON Realforce  (for switching input source)
- Home & End key mapping (to Command + LeftArrow / Command + RightArrow)
    - Tip: iTerm2 keymapping configuration
      - `⌘ ←` to Send Escape Sequence `[H`  (i.e., `\e[H`)
      - `⌘ →` to Send Escape Sequence `[F`  (i.e., `\e[F`)
- Remap `<Ctrl-w>` to "kill words" in Google Chrome and Safari


## USB Vendor ID & Product ID

- Torpre (2131)
  - 326: REALFORCE 87 US

- Apple (1452)
  - 834: Internal Keyboard (Macbook Pro 14" 2021)

- Logitech (1133)
