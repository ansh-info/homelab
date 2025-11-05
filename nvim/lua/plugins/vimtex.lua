return {
  {
    "lervag/vimtex",
    -- Do not lazy load, VimTeX handles it internally based on filetype
    lazy = false,
    init = function()
      -- Remap all VimTeX defaults to start with <leader>v
      vim.g.vimtex_mappings_prefix = "<leader>v"

      -- Use Skim for forward/inverse search on macOS
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_activate = 1

      -- Ensure latexmk provides continuous compilation
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        continuous = 1,
        executable = "latexmk",
        options = {
          "-pdf",
          "-interaction=nonstopmode",
          "-synctex=1",
        },
      }

      -- Kick off latexmk on buffer init for Overleaf-style live previews
      vim.api.nvim_create_autocmd("User", {
        pattern = "VimtexEventInitPost",
        callback = function()
          vim.cmd("silent! VimtexCompile")
        end,
      })
    end,
  },
}
