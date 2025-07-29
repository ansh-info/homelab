-- ~/.config/nvim/mykittydarcula.lua
vim.cmd("highlight clear")
vim.o.background = "dark"
vim.g.colors_name = "mykittydarcula"

local colors = {
  bg = "#202020",
  fg = "#adadad",
  black = "#000000",
  red = "#fa5355",
  green = "#126e00",
  yellow = "#c2c300",
  blue = "#4581eb",
  magenta = "#fa54ff",
  cyan = "#33c2c1",
  white = "#adadad",
  brblack = "#545454",
  brred = "#fb7172",
  brgreen = "#67ff4f",
  bryellow = "#ffff00",
  brblue = "#6d9df1",
  brmagenta = "#fb82ff",
  brcyan = "#60d3d1",
  brwhite = "#eeeeee",
  sel_bg = "#eeeeee",
  sel_fg = "#202020",
  cursor_bg = "#ffffff",
  tab_active_fg = "#eeeeee",
  tab_active_bg = "#eeeeee",
  tab_inactive_fg = "#adadad",
  tab_inactive_bg = "#1a1a1a",
}

local hi = function(group, opts)
  local cmd = "highlight " .. group
  if opts.fg then
    cmd = cmd .. " guifg=" .. opts.fg
  end
  if opts.bg then
    cmd = cmd .. " guibg=" .. opts.bg
  end
  if opts.style then
    cmd = cmd .. " gui=" .. opts.style
  end
  vim.cmd(cmd)
end

hi("Normal", { fg = colors.fg, bg = colors.bg })
hi("Cursor", { fg = colors.bg, bg = colors.cursor_bg })
hi("Visual", { fg = colors.sel_fg, bg = colors.sel_bg })
hi("VisualNOS", { bg = colors.sel_bg })
hi("LineNr", { fg = colors.brblack, bg = colors.bg })
hi("CursorLine", { bg = "#262626" })
hi("CursorLineNr", { fg = colors.fg, bg = "#262626", style = "bold" })
hi("StatusLine", { fg = colors.fg, bg = "#262626" })
hi("StatusLineNC", { fg = colors.tab_inactive_fg, bg = colors.tab_inactive_bg })
hi("TabLine", { fg = colors.tab_inactive_fg, bg = colors.tab_inactive_bg })
hi("TabLineSel", { fg = colors.tab_active_fg, bg = colors.tab_active_bg })
hi("TabLineFill", { fg = colors.tab_inactive_fg, bg = colors.tab_inactive_bg })

-- Standard 16-color ui
hi("Normal", { fg = colors.fg, bg = colors.bg })
hi("Comment", { fg = colors.brblack, bg = colors.bg, style = "italic" })
hi("Constant", { fg = colors.cyan, bg = colors.bg })
hi("String", { fg = colors.green, bg = colors.bg })
hi("Character", { fg = colors.yellow, bg = colors.bg })
hi("Number", { fg = colors.magenta, bg = colors.bg })
hi("Boolean", { fg = colors.magenta, bg = colors.bg })
hi("Identifier", { fg = colors.blue, bg = colors.bg })
hi("Function", { fg = colors.blue, bg = colors.bg })
hi("Statement", { fg = colors.red, bg = colors.bg })
hi("Operator", { fg = colors.red, bg = colors.bg })
hi("PreProc", { fg = colors.yellow, bg = colors.bg })
hi("Type", { fg = colors.cyan, bg = colors.bg })
hi("Special", { fg = colors.magenta, bg = colors.bg })

-- Diagnostic and LSP highlights (optional, can add more)
hi("DiagnosticError", { fg = colors.red, bg = colors.bg })
hi("DiagnosticWarn", { fg = colors.yellow, bg = colors.bg })
hi("DiagnosticInfo", { fg = colors.blue, bg = colors.bg })
hi("DiagnosticHint", { fg = colors.cyan, bg = colors.bg })

-- Float windows (used by file tree, LazyGit, etc.)
hi("NormalFloat", { fg = colors.fg, bg = colors.bg }) -- or leave bg empty for transparency
hi("FloatBorder", { fg = colors.fg, bg = colors.bg })
hi("Pmenu", { fg = colors.fg, bg = colors.bg })
hi("PmenuSel", { fg = colors.sel_fg, bg = colors.sel_bg })

-- Neo-tree or NvimTree specific
hi("NeoTreeNormal", { fg = colors.fg, bg = colors.bg })
hi("NeoTreeNormalNC", { fg = colors.fg, bg = colors.bg })
hi("NeoTreeFloatBorder", { fg = colors.fg, bg = colors.bg })

-- Telescope
hi("TelescopeNormal", { fg = colors.fg, bg = colors.bg })
hi("TelescopeBorder", { fg = colors.fg, bg = colors.bg })

-- LazyGit (uses float)
hi("LazyNormal", { fg = colors.fg, bg = colors.bg })

-- LSP floating windows and popups
hi("NormalNC", { fg = colors.fg, bg = colors.bg })
hi("DiagnosticFloat", { fg = colors.fg, bg = colors.bg })
