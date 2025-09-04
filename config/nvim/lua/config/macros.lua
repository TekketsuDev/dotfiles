-- Función segura para mover líneas en visual mode
local function safe_move_lines(direction)
  return function()
    local first_line = vim.fn.line("'<")
    local last_line = vim.fn.line("'>")
    local total_lines = vim.fn.line("$")

    if direction == "down" and last_line == total_lines then
      return -- no puede bajar más
    elseif direction == "up" and first_line == 1 then
      return -- no puede subir más
    end

    local cmd = direction == "down"
        and ":m '>+1<CR>gv=gv"
        or ":m '<-2<CR>gv=gv"

    vim.cmd(cmd)
  end
end

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = vim.fn.stdpath("config") .. "/lua/config/macros.lua",
  callback = function()
    package.loaded["config.macros"] = nil
    require("config.macros")
    vim.notify("macros recargado")
  end,
})

vim.keymap.set("v", "<A-j>", safe_move_lines("down"), { desc = "Mover línea abajo" })
vim.keymap.set("v", "<A-k>", safe_move_lines("up"), { desc = "Mover línea arriba" })

-- Indentar en visual mode
vim.keymap.set("v", "<A-h>", "<gv", { desc = "Indentar izquierda" })
vim.keymap.set("v", "<A-l>", ">gv", { desc = "Indentar derecha" })

