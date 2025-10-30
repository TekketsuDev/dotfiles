-- lua/plugins/whichkey.lua
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
        { '<leader>f', group = '+file' },
        { '<leader>ff', '<cmd>Telescope find_files<CR>', desc = 'Find files' },
        -- { "<leader>fs", "<cmd>w<CR>", desc = "Save file" },  -- ejemplo
      })
    end,
  },
}
