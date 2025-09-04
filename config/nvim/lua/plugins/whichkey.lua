-- lua/plugins/whichkey.lua
return {
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = { window = { border = 'rounded' } },
    config = function(_, opts)
      local wk = require('which-key')
      wk.setup(opts)
      wk.add({
        ['<leader>f'] = { name = '+file' },
        ['<leader>ff'] = { '<cmd>Telescope find_files<CR>', 'Find Files' },
      })
    end,
  },
}
