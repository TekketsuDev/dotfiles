-- config/macros.lua
-- config/macros.lua
local M = {}

function M.cmp_mappings()
  local ok, cmp = pcall(require, 'cmp')
  if not ok then
    return {}
  end
  return cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<Tab>'] = cmp.mapping(function(fb)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fb()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fb)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fb()
      end
    end, { 'i', 's' }),
    ['<C-e>'] = cmp.mapping.abort(),
  })
end

-- Usa which-key o set directo, pero no ambos para la misma tecla
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<CR>', { desc = 'Find Files' })

return M
