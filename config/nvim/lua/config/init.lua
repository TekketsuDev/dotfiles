require('config.lazy')
require('config.macros')
pcall(require, 'config.dev_core')
-- Indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Avoid annoying warnings
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0

require('lazy').setup({
  -- tus plugins aquí
}, {
  change_detection = {
    notify = false,
    enabled = false,
  },
  checker = {
    enabled = true,
  },
})
-- Clipboard settings
vim.opt.clipboard = 'unnamedplus'
vim.g.clipboard = {
  name = 'wl-clipboard',
  copy = {
    ['+'] = 'wl-copy',
    ['*'] = 'wl-copy',
  },
  paste = {
    ['+'] = 'wl-paste',
    ['*'] = 'wl-paste',
  },
  cache_enabled = 0,
}
vim.opt.number = true
vim.opt.relativenumber = true

vim.o.undofile = true

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set terminal gui colors to true
vim.o.termguicolors = true
-- Example: set leader to space
vim.g.mapleader = ' '
vim.g.maplocalleader = ' ' -- optional, for local leader

-- Desactiva relativenumber en modo insert
vim.api.nvim_create_autocmd('InsertEnter', {
  callback = function()
    vim.opt.relativenumber = false
  end,
})

vim.api.nvim_create_autocmd('InsertLeave', {
  callback = function()
    vim.opt.relativenumber = true
  end,
})
if #vim.api.nvim_list_uis() == 0 then
  return {} -- No cargues snacks.nvim en modo headless
end
