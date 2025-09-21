-- config/nvim/lua/plugins/dev_minimal.lua
-- Minimal, fast stack for C/C++/C, Bash, Lua (+ optional PowerShell)
return {
  ---------------------------------------------------------------------------
  -- External tools installer
  ---------------------------------------------------------------------------
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    opts = {
      ui = { border = "rounded" },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    opts = {
      ensure_installed = { "clangd", "bashls", "lua_ls" }, -- instala servidores
      automatic_installation = true,
    },
  },

  ---------------------------------------------------------------------------
  -- LSP bootstrap (NO lspconfig)
  ---------------------------------------------------------------------------
  {
    -- pequeño plugin “virtual” para configurar LSP nativo
    "dev/minimal-lsp",
    dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- capabilities (con nvim-cmp si está disponible)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      pcall(function()
        capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
      end)

      local function on_attach(client, bufnr)
        -- Deja tus mappings aquí si quieres; ahora lo dejamos vacío
      end

      local function start_on_ft(patterns, cfg)
        vim.api.nvim_create_autocmd("FileType", {
          pattern = patterns,
          callback = function(args)
            vim.lsp.start(vim.tbl_deep_extend("force", cfg, { bufnr = args.buf }))
          end,
          desc = "Auto-start LSP for " .. (cfg.name or "server"),
        })
      end

      -----------------------------------------------------------------------
      -- Lua (lua_ls)
      -----------------------------------------------------------------------
      local lua_cfg = vim.lsp.config({
        name = "lua_ls",
        cmd = { "lua-language-server" },
        root_dir = vim.fs.root(0, { ".luarc.json", ".luarc.jsonc", ".git" }),
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            diagnostics = { globals = { "vim" } },
          },
        },
      })
      start_on_ft({ "lua" }, lua_cfg)

      -----------------------------------------------------------------------
      -- C / C++ (clangd)
      -----------------------------------------------------------------------
      local clangd_cfg = vim.lsp.config({
        name = "clangd",
        cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=never" },
        root_dir = vim.fs.root(0, { "compile_commands.json", ".git" }),
        capabilities = capabilities,
        on_attach = on_attach,
      })
      start_on_ft({ "c", "cpp", "objc", "objcpp" }, clangd_cfg)

      -----------------------------------------------------------------------
      -- Bash (bashls)
      -----------------------------------------------------------------------
      local bash_cfg = vim.lsp.config({
        name = "bashls",
        cmd = { "bash-language-server", "start" },
        root_dir = vim.fs.root(0, { ".git", ".bashrc", ".shellcheckrc" }),
        capabilities = capabilities,
        on_attach = on_attach,
      })
      start_on_ft({ "sh", "bash" }, bash_cfg)

      -----------------------------------------------------------------------
      -- PowerShell (opcional) — solo si está instalado vía mason y hay pwsh
      -----------------------------------------------------------------------
      local has_pwsh = (vim.fn.executable("pwsh") == 1) or (vim.fn.executable("powershell") == 1)
      local ok_mr, mr = pcall(require, "mason-registry")
      if has_pwsh and ok_mr and mr.has_package and mr.has_package("powershell-editor-services") then
        local pkg = mr.get_package("powershell-editor-services")
        if pkg:is_installed() then
          local bundle = pkg:get_install_path()
          -- Script oficial de arranque del PSES
          local start_ps1 = bundle .. "/PowerShellEditorServices/Start-EditorServices.ps1"
          local shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
          local pses_cfg = vim.lsp.config({
            name = "powershell_es",
            cmd = {
              shell, "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass",
              "-Command", start_ps1,
              "-HostName", "nvim",
              "-HostProfileId", "Neovim",
              "-HostVersion", "1.0.0",
              "-LogLevel", "Normal",
              "-BundledModulesPath", bundle,
              "-EnableConsoleRepl",
            },
            capabilities = capabilities,
            on_attach = on_attach,
          })
          start_on_ft({ "ps1", "psm1", "psd1" }, pses_cfg)
        end
      end
    end,
  },

  ---------------------------------------------------------------------------
  -- Completion + snippets
  ---------------------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter" },
    dependencies = {
      "L3MON4D3/LuaSnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      vim.opt.completeopt = { "menu", "menuone", "noselect" }

      local cmp = require("cmp")
      local luasnip = require("luasnip")
      pcall(function() require("luasnip.loaders.from_vscode").lazy_load() end)

      local mappings
      local ok_macros, macros = pcall(require, "config.macros")
      if ok_macros and macros and macros.cmp_mappings then
        mappings = macros.cmp_mappings()
      else
        mappings = cmp.mapping.preset.insert({
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<Tab>"] = cmp.mapping(function(fb)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then luasnip.expand_or_jump()
            else fb() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fb)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then luasnip.jump(-1)
            else fb() end
          end, { "i", "s" }),
        })
      end

      cmp.setup({
        preselect = cmp.PreselectMode.Item,
        completion = { autocomplete = { "TextChanged" } },
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = mappings,
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
          { name = "buffer" },
        }),
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- Formatting (fast)
  ---------------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local max = 200 * 1024
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
        if ok and stats and stats.size > max then return nil end
        return { timeout_ms = 2000, lsp_fallback = true }
      end,
      formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        powershell = { "pwsh" },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Lint (ligero; opcional)
  ---------------------------------------------------------------------------
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")
      local function has(bin) return vim.fn.executable(bin) == 1 end

      lint.linters_by_ft = {
        sh = has("shellcheck") and { "shellcheck" } or {},
        bash = has("shellcheck") and { "shellcheck" } or {},
        lua = has("luacheck") and { "luacheck" } or {},
      }

      local group = vim.api.nvim_create_augroup("LintAutogroup", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        group = group,
        callback = function()
          local ft = vim.bo.filetype
          local linters = lint.linters_by_ft[ft]
          if type(linters) == "table" and #linters > 0 then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}

