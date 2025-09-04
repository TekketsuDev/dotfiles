return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  cmd = "Telescope",
  init = function()
    local builtin = require("telescope.builtin")
    vim.keymap.set("n", "<leader>ff", function()
      builtin.find_files({ hidden = true })
    end, { desc = "Find File" })

    vim.keymap.set("n", "<leader>fg", function()
      builtin.live_grep({
        additional_args = function()
          return { "--hidden", "--no-ignore" }
        end,
      })
    end, { desc = "Find with Grep" })

    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find Buffer" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find Help" })

    vim.keymap.set("n", "<leader>fn", function()
      require("telescope").extensions.file_browser.file_browser({
        path = "%:p:h",
        select_buffer = true,
      })
    end, { desc = "File Browser (current dir)" })
  end,
  opts = function()
    return {
      defaults = {
        vimgrep_arguments = {
          "rg", "-L", "--color=never", "--no-heading",
          "--with-filename", "--line-number", "--column", "--smart-case",
        },
        previewer = true,
        file_previewer = require("telescope.previewers").vim_buffer_cat.new,
        grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
        qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
      },
      extensions = {
        file_browser = {
          theme = "ivy",
          hijack_netrw = true,
          hidden = true,
        },
      },
    }
  end,
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    telescope.load_extension("file_browser")
  end,
}   
