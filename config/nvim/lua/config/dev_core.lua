-- config/nvim/lua/core/dev_core.lua
-- Startup speed + stable UI (no text shifting)

-- Lua bytecode cache (Neovim 0.9+)
pcall(function()
  vim.loader.enable()
end)

-- Keep sign column visible so lines don't shift when diagnostics appear
vim.opt.signcolumn = 'yes'

-- Diagnostics: no inline virtual text (stops text from moving); keep signs/underline
vim.diagnostic.config({
  virtual_text = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Small perf wins
vim.opt.lazyredraw = true
vim.opt.synmaxcol = 240
