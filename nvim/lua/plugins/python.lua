return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters = opts.linters or {}

      opts.linters_by_ft.python = { "ruff", "mypy" }

      local function has_any(paths, ctx)
        return vim.fs.find(paths, { path = ctx.dirname, upward = true })[1]
      end

      opts.linters.mypy = vim.tbl_deep_extend("force", opts.linters.mypy or {}, {
        condition = function(ctx)
          return has_any({ "mypy.ini", ".mypy.ini", "pyproject.toml", "setup.cfg" }, ctx)
        end,
      })

      opts.linters.pylint = vim.tbl_deep_extend("force", opts.linters.pylint or {}, {
        condition = function(ctx)
          return has_any({ ".pylintrc", "pylintrc", "pyproject.toml", "setup.cfg" }, ctx)
        end,
      })

      opts.linters.pydocstyle = vim.tbl_deep_extend("force", opts.linters.pydocstyle or {}, {
        condition = function(ctx)
          return has_any({ "pydocstyle.toml", "pyproject.toml", "setup.cfg" }, ctx)
        end,
      })

      vim.api.nvim_create_user_command("LintPythonExtras", function()
        require("lint").try_lint({ "mypy", "pylint", "pydocstyle" })
      end, { desc = "Run mypy/pylint/pydocstyle once" })
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.python = { "ruff_fix", "ruff_format" }
    end,
  },
}
