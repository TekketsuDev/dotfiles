return {
  {
    "folke/snacks.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      dashboard = {
        enabled = true,
        width = 50,       -- ancho de cada pane
        pane_gap = 2,     -- espacio entre panes
        sections = {
          { section = "header" },
          {
            section = "keys",
            padding = 1,
            gap = 1,
          },
	  { 
	    pane = 2,
	    icon = " ", 
	    title = "Recent Files", 
	    section = "recent_files", 
	    indent = 2, 
	    padding = 1,
	  },
	  {
  pane = 2,
  section = "projects",
  title = "Repositorios",
  icon = " ",
  indent = 2,
  padding = 1,
  dirs = function()
    local paths = { vim.fn.expand("~/projects"), vim.fn.expand("~/") }
    local repos = {}

    for _, base in ipairs(paths) do
      local dirs = vim.fn.globpath(base, "*/.git", 0, 1)
      for _, gitdir in ipairs(dirs) do
        table.insert(repos, vim.fn.fnamemodify(gitdir, ":h"))
      end
    end

    return repos
  end,
  info = function(dir)
    local handle = io.popen("cd " .. dir .. " && git --no-pager status -sb 2>/dev/null")
    if not handle then return "" end
    local result = handle:read("*a")
    handle:close()
    return result:gsub("\n", " "):gsub("%s+$", "") -- en una sola línea
  end,
  action = function(dir)
    vim.cmd("cd " .. dir)
    require("telescope.builtin").find_files()
  end,
},	
	  {
	    section = "startup",
	    pane = 2,
    	  },
        },
      },
    },
  },
}

