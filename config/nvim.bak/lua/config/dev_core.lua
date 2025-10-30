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

require('nvim-treesitter.configs').setup({
  highlight = { enable = true }, -- ¡imprescindible!
  rainbow = {
    enable = true,
    query = 'rainbow-parens',
    strategy = require('ts-rainbow.strategy.global'),
  },
})
vim.api.nvim_set_hl(0, 'RainbowDelimiterRed', { fg = '#E06C75' })
vim.api.nvim_set_hl(0, 'RainbowDelimiterYellow', { fg = '#E5C07B' })
vim.api.nvim_set_hl(0, 'RainbowDelimiterBlue', { fg = '#61AFEF' })
vim.api.nvim_set_hl(0, 'RainbowDelimiterOrange', { fg = '#D19A66' })
vim.api.nvim_set_hl(0, 'RainbowDelimiterGreen', { fg = '#98C379' })
vim.api.nvim_set_hl(0, 'RainbowDelimiterViolet', { fg = '#C678DD' })
vim.api.nvim_set_hl(0, 'RainbowDelimiterCyan', { fg = '#56B6C2' })
