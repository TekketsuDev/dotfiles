-- config/nvim/lua/plugins/dev_minimal.lua
-- Minimal, fast stack for C/C++/C, Bash, PowerShell, Lua
return {
  ---------------------------------------------------------------------------
  -- Manager for external tools (LSP servers, formatters, etc.)
  ---------------------------------------------------------------------------
  {
    'williamboman/mason.nvim',
    build = ':MasonUpdate',
    opts = {
      ui = { border = 'rounded' },
    },
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'mason.nvim' },
    opts = {
      ensure_installed = { 'clangd', 'bashls', 'lua_ls' },
      automatic_installation = true,
    },
  },

  ---------------------------------------------------------------------------
  -- LSP: lightweight config for requested languages
  ---------------------------------------------------------------------------
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lspconfig = require('lspconfig')

      -- capabilities (use cmp if present)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      pcall(function()
        capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
      end)

      local function on_attach(client, bufnr)
        -- Mantén tus propios mappings; no añadimos nada aquí.
      end

      -- C/C++/C via clangd
      lspconfig.clangd.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = { 'clangd', '--background-index', '--clang-tidy', '--header-insertion=never' },
      })

      -- Bash
      lspconfig.bashls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- Lua (Neovim)
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            diagnostics = { globals = { 'vim' } },
          },
        },
      })

      -- PowerShell (PowerShellEditorServices)
      -- Configuración segura: solo se aplica si detectamos correctamente el bundle instalado por mason.
      if lspconfig.powershell_es then
        local bundle_path = nil
        local ok_mr, mr = pcall(require, 'mason-registry')
        if ok_mr and mr.has_package and mr.has_package('powershell-editor-services') then
          local ok_pkg, pkg = pcall(mr.get_package, 'powershell-editor-services')
          if ok_pkg and pkg and pkg.is_installed and pkg:is_installed() and pkg.get_install_path then
            bundle_path = pkg:get_install_path()
          end
        end

        local ok_setup = pcall(function()
          lspconfig.powershell_es.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            bundle_path = bundle_path, -- nil es aceptable: entonces no se inicia y avisamos
          })
        end)
      end
    end,
  },

  ---------------------------------------------------------------------------
  -- Completion (auto suggestions) + snippets (no new keymaps)
  ---------------------------------------------------------------------------
  {
    'hrsh7th/nvim-cmp',
    event = { 'InsertEnter' },
    dependencies = {
      'L3MON4D3/LuaSnip',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'saadparwaiz1/cmp_luasnip',
      'rafamadriz/friendly-snippets',
    },
    config = function()
      -- hace que el popup se vea y se comporte bien
      vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

      local cmp = require('cmp')
      local luasnip = require('luasnip')

      pcall(function()
        require('luasnip.loaders.from_vscode').lazy_load()
      end)

      -- mappings: usa los tuyos si existen; si no, fallback mínimo funcional
      local mappings
      local ok_macros, macros = pcall(require, 'config.macros')
      if ok_macros and macros and macros.cmp_mappings then
        mappings = macros.cmp_mappings()
      else
        mappings = cmp.mapping.preset.insert({
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        })
      end

      cmp.setup({
        preselect = cmp.PreselectMode.Item,
        completion = { autocomplete = { 'TextChanged' } },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = mappings,
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
          { name = 'buffer' },
        }),
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- Formatting (fast) — keeps buffers clean without inline diagnostics
  ---------------------------------------------------------------------------
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local max = 200 * 1024
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
        if ok and stats and stats.size > max then
          return nil
        end
        return { timeout_ms = 2000, lsp_fallback = true }
      end,
      formatters_by_ft = {
        c = { 'clang_format' },
        cpp = { 'clang_format' },
        lua = { 'stylua' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        powershell = { 'pwsh' },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- OPTIONAL: lightweight lint (off by default)
  ---------------------------------------------------------------------------
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      local lint = require('lint')
      local has = function(bin)
        return vim.fn.executable(bin) == 1
      end

      -- Solo activa linters si el binario existe
      lint.linters_by_ft = {
        sh = has('shellcheck') and { 'shellcheck' } or {},
        bash = has('shellcheck') and { 'shellcheck' } or {},
        lua = has('luacheck') and { 'luacheck' } or {}, -- <- evitar ENOENT
      }

      local group = vim.api.nvim_create_augroup('LintAutogroup', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
        group = group,
        callback = function()
          local ft = vim.bo.filetype
          local linters = lint.linters_by_ft[ft]
          if type(linters) == 'table' and #linters > 0 then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
