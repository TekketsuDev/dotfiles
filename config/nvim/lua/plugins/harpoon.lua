return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()

    -- Add current file to Harpoon list
    vim.keymap.set("n", "<leader>a", function()
      harpoon:list():add()
    end, { desc = "Harpoon add file" })

    -- Toggle Harpoon quick menu
    vim.keymap.set("n", "<leader>h", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Harpoon quick menu" })

    -- Navigate to Harpoon files
    for i = 1, 5 do
      vim.keymap.set("n", "<leader>" .. i, function()
        harpoon:list():select(i)
      end, { desc = "Harpoon go to file " .. i })
    end

    -- Harpoon with Telescope
    vim.keymap.set("n", "<leader>f.", function()
      require("telescope").extensions.harpoon.marks()
    end, { desc = "Telescope Harpoon Marks" })
  end,
}
