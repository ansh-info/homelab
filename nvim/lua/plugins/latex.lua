return {
  -- Core LaTeX workflow (compilation + PDF viewer + mappings)
  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      -- compiler: latexmk in continuous mode
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        continuous = 1,
        callback = 1,
        options = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "-file-line-error" },
      }

      -- PDF viewer: Skim (macOS)
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_activate = 1

      -- QoL
      vim.g.vimtex_quickfix_mode = 0
      vim.g.tex_flavor = "latex"
    end,
  },

  -- Treesitter highlighting/folds
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "latex", "bibtex" })
    end,
  },

  -- Mason: install LSP + tools
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "texlab", "latexindent" })
    end,
  },

  -- LSP settings for texlab (lint/format/forward search)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        texlab = {
          settings = {
            texlab = {
              build = {
                executable = "latexmk",
                args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "-file-line-error", "%f" },
                onSave = false, -- VimTeX handles continuous builds
                forwardSearchAfter = true,
              },
              chktex = { onEdit = false, onOpenAndSave = true }, -- lint on save/open
              latexindent = { modifyLineBreaks = true }, -- formatter
              forwardSearch = {
                executable = "/Applications/Skim.app/Contents/SharedSupport/displayline",
                args = { "%l", "%p", "%f" },
              },
            },
          },
        },
      },
    },
  },
}
