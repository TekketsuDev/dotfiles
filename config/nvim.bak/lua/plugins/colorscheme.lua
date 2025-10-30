return {
	{
  "neanias/everforest-nvim",
  version = false,
  lazy = false,
  priority = 1000,
  config = function()
    require("everforest").setup({
      background = "medium", -- opcional: "soft", "medium" (default), "hard"
      transparent_background = false,
      ui_contrast = "high", -- o "low", "medium"
      dim_inactive_windows = true,
      disable_italic_comments = false,
    })

    vim.o.background = "dark" -- o "light" según prefieras
    vim.cmd([[colorscheme everforest]])
  end,
},

}
