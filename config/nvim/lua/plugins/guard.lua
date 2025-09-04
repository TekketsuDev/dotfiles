return {
  "nvimdev/guard.nvim",
  event = "BufReadPre",
  dependencies = {
    "nvimdev/guard-collection",
  },
  config = function()
    vim.defer_fn(function()
      local ok_guard, guard = pcall(require, "guard")
      local ok_ft, ft = pcall(require, "guard.filetype")
      if not (ok_guard and ok_ft) then return end

      -- Stylua para Lua
      ft("lua"):fmt({
        cmd = "stylua",
        args = { "-" },
        stdin = true,
      })

      -- Clang-format para C, C++ y JSON
      ft("c,cpp,json"):fmt("clang-format")

      -- Activar formateo al guardar
      guard.setup({
        fmt_on_save = true,
        lsp_as_default_formatter = false,
      })
    end, 0)
  end,
}

