# pyright.nvim

## Configuration

To configure on LazyVim, place the following at a file like `lua/plugins/python.lua`:

```lua
return {
  {
    "ianliu/pyright.nvim",
    keys = {
      {
        "<leader>pe",
        function()
          require("pyright").telescope.python_envs()
        end,
        desc = "Choose a python env for pyright"
      }
    }
  }
}
```

## Features & Roadmap

 - [x] Provide a Telescope picker to choose a python environment for pyright LSP
 - [ ] Configure pyright LSP
 - [ ] Configure python DAP
