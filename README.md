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
-- Simple installation (activates automatically)
{ "yairh/bidi.nvim" }

-- Or with custom config later
{
  "yairh/bidi.nvim",
  config = function()
    require("bidi").setup({
      -- options will go here
    })
  end
}
```

## Usage

The plugin activates automatically on startup.

### Commands
- `:Bidi enable`: Enable bidi rendering globally.
- `:Bidi disable`: Disable bidi rendering globally (clears all bidi marks).
- `:Bidi buf_enable`: Enable bidi rendering for the current buffer only (overrides global disable).
- `:Bidi buf_disable`: Disable bidi rendering for the current buffer only (overrides global enable).

### Settings
You can toggle `set rightleft` in Neovim to switch the base direction of the window, and the plugin will adjust the rendering accordingly.