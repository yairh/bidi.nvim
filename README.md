# bidi.nvim

A Neovim plugin to support bidirectional text (mixing Left-to-Right and Right-to-Left).

> [!NOTE]
> Currently, this plugin only supports Hebrew.

## Features
- **Bidirectional Display:** Automatically reverses Hebrew text in standard mode (`set norightleft`) so it reads correctly.
- **Right-to-Left Mode Support:** Automatically reverses Latin text in `set rightleft` mode so it reads correctly.
- **Toggle Support:** Reacts to `set rightleft` / `set norightleft` changes dynamically.
- **Granular Control:** Enable or disable bidi rendering globally or per-buffer.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
-- Simple installation
{
  "yairh/bidi.nvim",
  -- To activate only when opening a buffer (lazy loading):
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("bidi").setup()
  end,
}
```

Since `lazy.nvim` handles lazy loading, you can use `event` or `cmd` to control when the plugin (and its bidi rendering) activates.

## Usage

### Commands
- `:Bidi enable`: Enable bidi rendering globally.
- `:Bidi disable`: Disable bidi rendering globally (clears all bidi marks).
- `:Bidi buf_enable`: Enable bidi rendering for the current buffer only (overrides global disable).
- `:Bidi buf_disable`: Disable bidi rendering for the current buffer only (overrides global enable).

### Settings
You can toggle `set rightleft` in Neovim to switch the base direction of the window, and the plugin will adjust the rendering accordingly.

### Running Tests

```shell
nvim -c "set rtp+=." -l tests/test_bidi.lua

```
