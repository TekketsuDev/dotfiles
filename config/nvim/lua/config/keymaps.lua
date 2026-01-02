vim.opt.shell = "zsh"
vim.opt.shellcmdflag = "-lc"

vim.keymap.set("n", "<leader>r", function()
  local root = vim.fn.systemlist("git -C " .. vim.fn.expand("%:p:h") .. " rev-parse --show-toplevel")[1]
  if not root or root == "" then
    root = vim.fn.getcwd()
  end

  local file = vim.fn.expand("%:p")
  local cmd = "cd " .. vim.fn.shellescape(root) .. " && ./scripts/run_current.sh " .. vim.fn.shellescape(file)

  vim.cmd("vsplit")
  vim.cmd("terminal zsh -ic " .. vim.fn.shellescape("cd " .. root .. " && ./scripts/run_current.sh " .. file))
  vim.cmd("startinsert")
end, { desc = "Compile & run current C file (Campus 42)" })
