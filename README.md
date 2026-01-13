# bidi.nvim

A Neovim plugin to support bidirectional text (mixing Left-to-Right and Right-to-Left).

> [!NOTE]
> Currently, this plugin only supports Hebrew.

## Features
- **Bidirectional Display:** Automatically reverses Hebrew text in standard mode (`set norightleft`) so it reads correctly.
- **Right-to-Left Mode Support:** Automatically reverses Latin text in `set rightleft` mode so it reads correctly.
- **Toggle Support:** Reacts to `set rightleft` / `set norightleft` changes dynamically.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "yairh/bidi.nvim",
  config = function()
    require("bidi").setup()
  end
}
```

## Usage

The plugin activates automatically on setup.
You can toggle `set rightleft` in Neovim to see the effect.