return {
  'HiPhish/nvim-ts-rainbow2',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('nvim-treesitter.configs').setup({
      highlight = { enable = true },
      rainbow = {
        enable = true,
        -- choose a preset or define your own
        query = 'rainbow-parens',
        strategy = require('ts-rainbow.strategy.global'),
      },
    })
  end,
}
