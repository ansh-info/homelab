vim.cmd("highlight clear")
vim.o.background = "dark"
vim.g.colors_name = "jet_brains_darcula"

local colors = {
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

  sel_bg = "#44475a",
  sel_fg = "#ffffff",
  cursor_bg = "#ffffff",

  tab_active_fg = "#ffffff",
  tab_active_bg = "#3c3c3c",
  tab_inactive_fg = "#888888",
  tab_inactive_bg = "#2a2a2a",

  comment_fg = "#5c6370",
  cursor_line_bg = "#333333",
  statusline_bg = "#3c3c3c",
  float_border = "#888888",
}

-- Utility highlight function
local hi = function(group, opts)
  local cmd = "highlight " .. group
  if opts.fg then
    cmd = cmd .. " guifg=" .. opts.fg
  end
  if opts.bg ~= nil then
    if opts.bg == false then
      cmd = cmd .. " guibg=NONE"
    else
      cmd = cmd .. " guibg=" .. opts.bg
    end
  end
  if opts.style then
    cmd = cmd .. " gui=" .. opts.style
  end
  vim.cmd(cmd)
end

-- Base editor
hi("Normal", { fg = colors.fg, bg = false })
hi("NormalNC", { fg = colors.fg, bg = false })
hi("Cursor", { fg = "#000000", bg = colors.cursor_bg })
hi("Visual", { fg = colors.sel_fg, bg = colors.sel_bg })
hi("VisualNOS", { bg = colors.sel_bg })
hi("LineNr", { fg = colors.brblack, bg = false })
hi("CursorLine", { bg = colors.cursor_line_bg })
hi("CursorLineNr", { fg = "#eeeeee", bg = colors.cursor_line_bg, style = "bold" })

-- Statusline / Tabs
hi("StatusLine", { fg = colors.fg, bg = colors.statusline_bg })
hi("StatusLineNC", { fg = colors.tab_inactive_fg, bg = colors.tab_inactive_bg })
hi("TabLine", { fg = colors.tab_inactive_fg, bg = colors.tab_inactive_bg })
hi("TabLineSel", { fg = colors.tab_active_fg, bg = colors.tab_active_bg })
hi("TabLineFill", { fg = colors.tab_inactive_fg, bg = colors.tab_inactive_bg })

-- Syntax
-- hi("Comment", { fg = colors.comment_fg, style = "italic" })
-- hi("Comment", { fg = "#4a4a4a", style = "italic" })
-- hi("Comment", { fg = "#3c3c3c", style = "italic" })

-- Warm dark orange comments and docstrings
hi("Comment", { fg = "#cc7832", style = "italic" })
hi("@comment", { fg = "#cc7832", style = "italic" })
hi("@string.documentation", { fg = "#cc7832", style = "italic" })
hi("TSComment", { fg = "#cc7832", style = "italic" })
hi("TSStringDoc", { fg = "#cc7832", style = "italic" })

hi("Constant", { fg = colors.cyan })
hi("String", { fg = colors.green })
hi("Character", { fg = colors.yellow })
hi("Number", { fg = colors.magenta })
hi("Boolean", { fg = colors.magenta })
hi("Identifier", { fg = colors.blue })
hi("Function", { fg = colors.blue })
hi("Statement", { fg = colors.red })
hi("Operator", { fg = colors.red })
hi("PreProc", { fg = colors.yellow })
hi("Type", { fg = colors.cyan })
hi("Special", { fg = colors.magenta })

-- Diagnostics / LSP
hi("DiagnosticError", { fg = colors.red })
hi("DiagnosticWarn", { fg = colors.yellow })
hi("DiagnosticInfo", { fg = colors.blue })
hi("DiagnosticHint", { fg = colors.cyan })
hi("DiagnosticFloat", { fg = colors.fg, bg = false })

-- Floating windows
hi("NormalFloat", { fg = colors.fg, bg = false })
hi("FloatBorder", { fg = colors.float_border, bg = false })
hi("Pmenu", { fg = colors.fg, bg = false })
hi("PmenuSel", { fg = colors.sel_fg, bg = colors.sel_bg })

-- Tree plugins
hi("NeoTreeNormal", { fg = colors.fg, bg = false })
hi("NeoTreeNormalNC", { fg = colors.fg, bg = false })
hi("NeoTreeFloatBorder", { fg = colors.float_border, bg = false })

-- Telescope
hi("TelescopeNormal", { fg = colors.fg, bg = false })
hi("TelescopeBorder", { fg = colors.float_border, bg = false })

-- LazyGit
hi("LazyNormal", { fg = colors.fg, bg = false })

-- Snacks.nvim (custom file explorer)
hi("SnackExplorerSelection", { bg = false }) -- remove selection background
hi("SnackExplorerFocusedLine", { bg = false }) -- optional: dim or keep transparent
hi("SnackExplorerLine", { bg = false }) -- fallback for line-level bg
hi("CursorLine", { bg = "#333333" }) -- if snacks uses CursorLine
hi("SnackExplorerSelection", { bg = "#2e2e2e" }) -- subtle highlight

-- Make Neo-tree cursor line transparent or dim
hi("NeoTreeCursorLine", { bg = false }) -- fully transparent
-- OR if you want a subtle line:
-- hi("NeoTreeCursorLine", { bg = "#2f2f2f" })

-- Optional: cleanup icons if needed
hi("NeoTreeFileName", { fg = colors.fg, bg = false })
hi("NeoTreeFileNameOpened", { fg = colors.fg, bg = false })
hi("NeoTreeSymbolicLinkTarget", { fg = colors.cyan, bg = false })
