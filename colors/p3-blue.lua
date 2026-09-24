-- ═══════════════════════════════════════════════════════════════════════
--  p3-blue.lua — P3 Blue · Neovim 主题
--
--  取色自 ~/Pictures/wallpaper/结城理.jpg，与 Ghostty / yazi / Starship /
--  Zed 使用同一套调色板，保证跨工具观感一致。
--
--  安装位置：~/.config/nvim/colors/p3-blue.lua
--  启用方式：vim.cmd.colorscheme("p3-blue")
--
--  说明：init.lua 里的 set_transparent() 会在 ColorScheme 事件后把若干组的
--        bg 改成 none，让 Ghostty 的壁纸透上来 —— 本主题不与之冲突。
-- ═══════════════════════════════════════════════════════════════════════

if vim.g.colors_name then vim.cmd("highlight clear") end
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end

vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "p3-blue"

-- ── 调色板 ─────────────────────────────────────────────────────────────
local p = {
  -- 背景层（由深到浅）
  bg        = "#1F2124",  -- 主背景（与 Zed 一致的中性灰底）
  bg_alt    = "#191B1E",  -- 状态栏 / 标签栏
  bg_float  = "#26282C",  -- 浮窗
  bg_elev   = "#2E3136",  -- 抬升表面
  bg_hover  = "#35393F",
  bg_sel    = "#3E434A",  -- 选中
  bg_cur    = "#272A2E",  -- 当前行

  -- 边框
  border    = "#3E434A",
  border_dim= "#414549",
  linenr    = "#8D95A1",  -- 行号（4.50:1，与 SignColumn 同亮度）

  -- 文本层级
  fg        = "#C3D3E6",  -- 正文
  fg_bright = "#E1EBF6",
  fg_dim    = "#A9C1DE",
  fg_muted  = "#8D95A1",  -- 次要文字（对比度 4.5:1）
  fg_faint  = "#868C93",  -- 注释级（最坏底 4.01:1）
  -- 虚影文字（blink.cmp 的行内补全预览）。
  -- ⚠ 这个键曾经漏定义，导致下面的 `p.fg_ghost or p.border` 静默退化成
  --   边框色 #3E434A（对比度仅 1.37:1），虚影几乎不可见。
  --   虚影要「看得清但明显比正文淡」，故取 4.50:1（与 fg_muted 同档）。
  ghost     = "#8D95A1",

  -- 蓝色阶（主色调）
  blue      = "#6A96D8",  -- 关键字
  blue_lt   = "#7FA9E8",  -- 函数
  blue_br   = "#94B5E6",
  ice       = "#93CBF2",  -- 类型
  cyan      = "#5CB5DD",  -- 强调

  -- 功能色
  green     = "#7FD8C4",  -- 字符串
  teal      = "#32AB83",
  sand      = "#DFBE7C",  -- 数字
  amber     = "#CDA253",
  red       = "#D87982",
  rose      = "#E89EA9",
  violet    = "#B79AD4",
  peri      = "#A3C8EC",  -- 属性
  slate     = "#98A1AD",  -- 运算符
}

local set = vim.api.nvim_set_hl
local function apply(t)
  for g, v in pairs(t) do
    if type(v) == "string" then set(0, g, { link = v }) else set(0, g, v) end
  end
end

-- ── 编辑器基础界面 ─────────────────────────────────────────────────────
apply({
  Normal            = { fg = p.fg, bg = p.bg },
  NormalNC          = { fg = p.fg, bg = p.bg },
  NormalFloat       = { fg = p.fg, bg = p.bg_float },
  FloatBorder       = { fg = p.border, bg = p.bg_float },
  FloatTitle        = { fg = p.cyan, bg = p.bg_float, bold = true },
  FloatFooter       = { fg = p.fg_muted, bg = p.bg_float },

  Cursor            = { fg = p.bg, bg = p.cyan },
  lCursor           = "Cursor",
  CursorIM          = "Cursor",
  TermCursor        = "Cursor",
  CursorLine        = { bg = p.bg_cur },
  CursorColumn      = { bg = p.bg_cur },
  ColorColumn       = { bg = p.bg_alt },
  CursorLineNr      = { fg = p.ice, bold = true },
  LineNr            = { fg = p.linenr },
  LineNrAbove       = { fg = p.linenr },
  LineNrBelow       = { fg = p.linenr },
  SignColumn        = { fg = p.fg_muted, bg = p.bg },
  FoldColumn        = { fg = p.border, bg = p.bg },
  Folded            = { fg = p.fg_muted, bg = p.bg_elev },
  EndOfBuffer       = { fg = p.bg },

  Visual            = { bg = p.bg_sel },
  VisualNOS         = { bg = p.bg_sel },
  Search            = { fg = p.bg, bg = p.ice },
  IncSearch         = { fg = p.bg, bg = p.cyan, bold = true },
  CurSearch         = { fg = p.bg, bg = p.cyan, bold = true },
  Substitute        = { fg = p.bg, bg = p.rose },
  MatchParen        = { fg = p.cyan, bold = true, underline = true },

  Pmenu             = { fg = p.fg, bg = p.bg_float },
  PmenuSel          = { fg = p.bg, bg = p.blue, bold = true },
  PmenuKind         = { fg = p.ice, bg = p.bg_float },
  PmenuKindSel      = { fg = p.bg, bg = p.blue },
  PmenuExtra        = { fg = p.fg_muted, bg = p.bg_float },
  PmenuExtraSel     = { fg = p.bg, bg = p.blue },
  PmenuSbar         = { bg = p.bg_elev },
  PmenuThumb        = { bg = p.border },
  WildMenu          = { fg = p.bg, bg = p.cyan },

  StatusLine        = { fg = p.fg, bg = p.bg_elev },
  StatusLineNC      = { fg = p.fg_faint, bg = p.bg_alt },
  StatusLineTerm    = "StatusLine",
  StatusLineTermNC  = "StatusLineNC",
  TabLine           = { fg = p.fg_muted, bg = p.bg_alt },
  TabLineFill       = { bg = p.bg_alt },
  TabLineSel        = { fg = p.fg_bright, bg = p.bg_elev, bold = true },

  WinSeparator      = { fg = p.border_dim },
  VertSplit         = "WinSeparator",
  WinBar            = { fg = p.fg_muted, bg = p.bg },
  WinBarNC          = { fg = p.fg_faint, bg = p.bg },

  NonText           = { fg = p.border_dim },
  SpecialKey        = { fg = p.border },
  Whitespace        = { fg = p.border_dim },
  Conceal           = { fg = p.fg_muted },
  Directory         = { fg = p.blue_lt },
  Title             = { fg = p.ice, bold = true },

  ErrorMsg          = { fg = p.red, bold = true },
  WarningMsg        = { fg = p.amber },
  MoreMsg           = { fg = p.cyan },
  Question          = { fg = p.green },
  ModeMsg           = { fg = p.fg_dim, bold = true },
  MsgArea           = { fg = p.fg },
  MsgSeparator      = { fg = p.border, bg = p.bg_alt },
  ErrorText         = { fg = p.red },
  WarningText       = { fg = p.amber },
  QuickFixLine      = { bg = p.bg_sel },
  qfFileName        = { fg = p.blue_lt },
  qfLineNr          = { fg = p.fg_faint },

  ScrollbarHandle   = { bg = p.border },
  ScrollbarCursor   = { bg = p.blue },
  CursorLineFold    = { fg = p.border, bg = p.bg_cur },
  CursorLineSign    = { bg = p.bg_cur },
})

-- ── 传统语法组 ─────────────────────────────────────────────────────────
apply({
  Comment           = { fg = p.fg_faint, italic = true },
  Constant          = { fg = p.sand },
  String            = { fg = p.green },
  Character         = { fg = p.green },
  Number            = { fg = p.sand },
  Float             = { fg = p.sand },
  Boolean           = { fg = p.sand },
  Identifier        = { fg = p.fg },
  Function          = { fg = p.blue_lt },
  Statement         = { fg = p.blue },
  Conditional       = { fg = p.blue },
  Repeat            = { fg = p.blue },
  Label             = { fg = p.blue },
  Operator          = { fg = p.slate },
  Keyword           = { fg = p.blue, bold = true },
  Exception         = { fg = p.red },
  PreProc           = { fg = p.peri },
  Include           = { fg = p.blue },
  Define            = { fg = p.blue },
  Macro             = { fg = p.violet },
  PreCondit         = { fg = p.blue },
  Type              = { fg = p.ice },
  StorageClass      = { fg = p.ice },
  Structure         = { fg = p.ice },
  Typedef           = { fg = p.ice },
  Special           = { fg = p.cyan },
  SpecialChar       = { fg = p.violet },
  Tag               = { fg = p.blue },
  Delimiter         = { fg = p.fg_muted },
  SpecialComment    = { fg = p.fg_muted, italic = true },
  Debug             = { fg = p.rose },
  Underlined        = { underline = true },
  Ignore            = { fg = p.bg },
  Error             = { fg = p.red },
  Todo              = { fg = p.bg, bg = p.ice, bold = true },
})

-- ── Treesitter 捕获 ────────────────────────────────────────────────────
apply({
  ["@variable"]              = { fg = p.fg },
  ["@variable.builtin"]      = { fg = p.violet, italic = true },
  ["@variable.parameter"]    = { fg = p.peri },
  ["@variable.member"]       = { fg = p.peri },
  ["@constant"]              = { fg = p.sand },
  ["@constant.builtin"]      = { fg = p.sand, italic = true },
  ["@constant.macro"]        = { fg = p.violet },
  ["@module"]                = { fg = p.ice },
  ["@module.builtin"]        = { fg = p.ice, italic = true },
  ["@label"]                 = { fg = p.blue_lt },
  ["@string"]                = { fg = p.green },
  ["@string.documentation"]  = { fg = p.green, italic = true },
  ["@string.regexp"]         = { fg = p.violet },
  ["@string.escape"]         = { fg = p.sand },
  ["@string.special"]        = { fg = p.ice },
  ["@string.special.symbol"] = { fg = p.violet },
  ["@string.special.url"]    = { fg = p.cyan, underline = true },
  ["@string.special.path"]   = { fg = p.ice },
  ["@character"]             = { fg = p.green },
  ["@character.special"]     = { fg = p.violet },
  ["@boolean"]               = { fg = p.sand },
  ["@number"]                = { fg = p.sand },
  ["@number.float"]          = { fg = p.sand },
  ["@function"]              = { fg = p.blue_lt },
  ["@function.builtin"]      = { fg = p.blue_lt, italic = true },
  ["@function.call"]         = { fg = p.blue_lt },
  ["@function.macro"]        = { fg = p.violet },
  ["@function.method"]       = { fg = p.blue_lt },
  ["@function.method.call"]  = { fg = p.blue_lt },
  ["@constructor"]           = { fg = p.ice },
  ["@operator"]              = { fg = p.slate },
  ["@keyword"]               = { fg = p.blue, bold = true },
  ["@keyword.coroutine"]     = { fg = p.blue },
  ["@keyword.function"]      = { fg = p.blue, bold = true },
  ["@keyword.operator"]      = { fg = p.blue },
  ["@keyword.import"]        = { fg = p.blue },
  ["@keyword.type"]          = { fg = p.ice },
  ["@keyword.modifier"]      = { fg = p.blue },
  ["@keyword.repeat"]        = { fg = p.blue },
  ["@keyword.return"]        = { fg = p.blue, bold = true },
  ["@keyword.debug"]         = { fg = p.rose },
  ["@keyword.exception"]     = { fg = p.red },
  ["@keyword.conditional"]   = { fg = p.blue },
  ["@keyword.conditional.ternary"] = { fg = p.slate },
  ["@keyword.directive"]     = { fg = p.peri },
  ["@keyword.directive.define"] = { fg = p.peri },
  ["@punctuation.delimiter"] = { fg = p.fg_muted },
  ["@punctuation.bracket"]   = { fg = p.slate },
  ["@punctuation.special"]   = { fg = p.cyan },
  ["@comment"]               = { fg = p.fg_faint, italic = true },
  ["@comment.documentation"] = { fg = p.fg_faint, italic = true },
  ["@comment.error"]         = { fg = p.bg, bg = p.red, bold = true },
  ["@comment.warning"]       = { fg = p.bg, bg = p.amber, bold = true },
  ["@comment.todo"]          = { fg = p.bg, bg = p.ice, bold = true },
  ["@comment.note"]          = { fg = p.bg, bg = p.cyan, bold = true },
  ["@markup.strong"]         = { fg = p.fg_bright, bold = true },
  ["@markup.italic"]         = { italic = true },
  ["@markup.strikethrough"]  = { strikethrough = true },
  ["@markup.underline"]      = { underline = true },
  ["@markup.heading"]        = { fg = p.ice, bold = true },
  ["@markup.heading.1"]      = { fg = p.ice, bold = true },
  ["@markup.heading.2"]      = { fg = p.blue_lt, bold = true },
  ["@markup.heading.3"]      = { fg = p.blue, bold = true },
  ["@markup.heading.4"]      = { fg = p.cyan, bold = true },
  ["@markup.heading.5"]      = { fg = p.peri, bold = true },
  ["@markup.heading.6"]      = { fg = p.violet, bold = true },
  ["@markup.quote"]          = { fg = p.fg_muted, italic = true },
  ["@markup.math"]           = { fg = p.cyan },
  ["@markup.link"]           = { fg = p.cyan },
  ["@markup.link.label"]     = { fg = p.ice },
  ["@markup.link.url"]       = { fg = p.cyan, underline = true },
  ["@markup.raw"]            = { fg = p.green },
  ["@markup.raw.block"]      = { fg = p.green },
  ["@markup.list"]           = { fg = p.cyan },
  ["@markup.list.checked"]   = { fg = p.green },
  ["@markup.list.unchecked"] = { fg = p.fg_muted },
  ["@markup.environment"]    = { fg = p.violet },
  ["@markup.environment.name"] = { fg = p.ice },
  ["@diff.plus"]             = { fg = p.green },
  ["@diff.minus"]            = { fg = p.red },
  ["@diff.delta"]            = { fg = p.amber },
  ["@tag"]                   = { fg = p.blue },
  ["@tag.builtin"]           = { fg = p.blue, italic = true },
  ["@tag.attribute"]         = { fg = p.peri },
  ["@tag.delimiter"]         = { fg = p.slate },
  ["@type"]                  = { fg = p.ice },
  ["@type.builtin"]          = { fg = p.ice, italic = true },
  ["@type.definition"]       = { fg = p.ice },
  ["@type.qualifier"]        = { fg = p.blue },
  ["@attribute"]             = { fg = p.peri },
  ["@attribute.builtin"]     = { fg = p.peri, italic = true },
  ["@property"]              = { fg = p.peri },
  ["@field"]                 = { fg = p.peri },
  ["@none"]                  = {},
})

-- ── LSP / 诊断 ─────────────────────────────────────────────────────────
apply({
  DiagnosticError              = { fg = p.red },
  DiagnosticWarn               = { fg = p.amber },
  DiagnosticInfo               = { fg = p.blue_lt },
  DiagnosticHint               = { fg = p.violet },
  DiagnosticOk                 = { fg = p.green },
  DiagnosticVirtualTextError   = { fg = p.red, bg = "#391F24" },
  DiagnosticVirtualTextWarn    = { fg = p.amber, bg = "#383222" },
  DiagnosticVirtualTextInfo    = { fg = p.blue_lt, bg = "#1E2C3E" },
  DiagnosticVirtualTextHint    = { fg = p.violet, bg = "#2A2438" },
  DiagnosticVirtualTextOk      = { fg = p.green, bg = "#1B342E" },
  DiagnosticUnderlineError     = { undercurl = true, sp = p.red },
  DiagnosticUnderlineWarn      = { undercurl = true, sp = p.amber },
  DiagnosticUnderlineInfo      = { undercurl = true, sp = p.blue_lt },
  DiagnosticUnderlineHint      = { undercurl = true, sp = p.violet },
  DiagnosticUnderlineOk        = { undercurl = true, sp = p.green },
  DiagnosticFloatingError      = { fg = p.red },
  DiagnosticFloatingWarn       = { fg = p.amber },
  DiagnosticFloatingInfo       = { fg = p.blue_lt },
  DiagnosticFloatingHint       = { fg = p.violet },
  DiagnosticSignError          = { fg = p.red },
  DiagnosticSignWarn           = { fg = p.amber },
  DiagnosticSignInfo           = { fg = p.blue_lt },
  DiagnosticSignHint           = { fg = p.violet },
  DiagnosticUnnecessary        = { fg = p.border },

  LspReferenceText             = { bg = p.bg_sel },
  LspReferenceRead             = { bg = p.bg_sel },
  LspReferenceWrite            = { bg = p.bg_sel, underline = true },
  LspSignatureActiveParameter  = { fg = p.bg, bg = p.cyan, bold = true },
  LspCodeLens                  = { fg = p.fg_faint, italic = true },
  LspCodeLensSeparator         = { fg = p.border },
  LspInlayHint                 = { fg = p.fg_faint, bg = p.bg_alt, italic = true },
})

-- ── 差异 / Git ─────────────────────────────────────────────────────────
apply({
  DiffAdd     = { fg = p.green, bg = "#1B342E" },
  DiffChange  = { fg = p.amber, bg = "#383222" },
  DiffDelete  = { fg = p.red, bg = "#391F24" },
  DiffText    = { fg = p.fg_bright, bg = "#4A4030" },
  Added       = { fg = p.green },
  Removed     = { fg = p.red },
  Changed     = { fg = p.amber },
  diffAdded   = { fg = p.green },
  diffRemoved = { fg = p.red },
  diffChanged = { fg = p.amber },
  diffFile    = { fg = p.ice },
  diffLine    = { fg = p.fg_faint },
  diffNewFile = { fg = p.blue_lt },
  diffOldFile = { fg = p.fg_muted },
  GitSignsAdd    = { fg = p.green },
  GitSignsChange = { fg = p.amber },
  GitSignsDelete = { fg = p.red },
})

-- ── 常用插件 ───────────────────────────────────────────────────────────
apply({
  -- Telescope
  TelescopeNormal         = { fg = p.fg, bg = p.bg_float },
  TelescopeBorder         = { fg = p.border, bg = p.bg_float },
  TelescopeTitle          = { fg = p.cyan, bold = true },
  TelescopePromptNormal   = { fg = p.fg, bg = p.bg_elev },
  TelescopePromptBorder   = { fg = p.border, bg = p.bg_elev },
  TelescopePromptTitle    = { fg = p.bg, bg = p.cyan, bold = true },
  TelescopePromptPrefix   = { fg = p.cyan },
  TelescopePromptCounter  = { fg = p.fg_muted },
  TelescopeResultsNormal  = { fg = p.fg, bg = p.bg_float },
  TelescopeResultsBorder  = { fg = p.border, bg = p.bg_float },
  TelescopeResultsTitle   = { fg = p.fg_muted },
  TelescopePreviewNormal  = { fg = p.fg, bg = p.bg_float },
  TelescopePreviewBorder  = { fg = p.border, bg = p.bg_float },
  TelescopePreviewTitle   = { fg = p.green },
  TelescopeSelection      = { fg = p.fg_bright, bg = p.bg_sel, bold = true },
  TelescopeSelectionCaret = { fg = p.cyan },
  TelescopeMultiSelection = { fg = p.violet },
  TelescopeMatching       = { fg = p.cyan, bold = true },

  -- nvim-tree
  NvimTreeNormal          = { fg = p.fg, bg = p.bg_alt },
  NvimTreeNormalNC        = { fg = p.fg, bg = p.bg_alt },
  NvimTreeWinSeparator    = { fg = p.border_dim, bg = p.bg_alt },
  NvimTreeRootFolder      = { fg = p.ice, bold = true },
  NvimTreeFolderName      = { fg = p.blue_lt },
  NvimTreeFolderIcon      = { fg = p.blue },
  NvimTreeOpenedFolderName= { fg = p.blue_lt, bold = true },
  NvimTreeEmptyFolderName = { fg = p.fg_faint },
  NvimTreeFileName        = { fg = p.fg },
  NvimTreeOpenedFile      = { fg = p.cyan, bold = true },
  NvimTreeSpecialFile     = { fg = p.violet, underline = true },
  NvimTreeSymlink         = { fg = p.cyan },
  NvimTreeExecFile        = { fg = p.green, bold = true },
  NvimTreeImageFile       = { fg = p.ice },
  NvimTreeIndentMarker    = { fg = p.border_dim },
  NvimTreeCursorLine      = { bg = p.bg_sel },
  NvimTreeGitDirty        = { fg = p.amber },
  NvimTreeGitNew          = { fg = p.green },
  NvimTreeGitDeleted      = { fg = p.red },
  NvimTreeGitRenamed      = { fg = p.blue_lt },
  NvimTreeGitMerge        = { fg = p.sand },
  NvimTreeGitStaged       = { fg = p.green },

  -- bufferline（背景会被 init.lua 的 set_transparent 统一去掉，
  -- 这里保留 bg 作为「切换到其他主题体系时的兜底」；fg 生效）
  BufferLineFill                = { bg = p.bg_alt },
  BufferLineBackground          = { fg = p.fg_faint, bg = p.bg_alt },
  BufferLineBufferVisible       = { fg = p.fg_muted, bg = p.bg_alt },
  BufferLineBufferSelected      = { fg = p.fg_bright, bg = p.bg, bold = true },
  BufferLineSeparator           = { fg = p.border_dim, bg = p.bg_alt },
  BufferLineSeparatorVisible    = { fg = p.border_dim, bg = p.bg_alt },
  BufferLineSeparatorSelected   = { fg = p.border_dim, bg = p.bg },
  BufferLineIndicatorSelected   = { fg = p.cyan, bg = p.bg },
  BufferLineIndicatorVisible    = { fg = p.border_dim, bg = p.bg_alt },
  BufferLineCloseButton         = { fg = p.fg_faint, bg = p.bg_alt },
  BufferLineCloseButtonVisible  = { fg = p.fg_muted, bg = p.bg_alt },
  BufferLineCloseButtonSelected = { fg = p.red, bg = p.bg },
  BufferLineModified            = { fg = p.amber, bg = p.bg_alt },
  BufferLineModifiedVisible     = { fg = p.amber, bg = p.bg_alt },
  BufferLineModifiedSelected    = { fg = p.green, bg = p.bg },
  BufferLineDiagnostic          = { fg = p.fg_faint, bg = p.bg_alt },
  BufferLineDiagnosticVisible   = { fg = p.fg_muted, bg = p.bg_alt },
  BufferLineDiagnosticSelected  = { fg = p.fg_bright, bg = p.bg, bold = true },

  -- noice
  NoiceCmdline            = { fg = p.fg, bg = p.bg_float },
  NoiceCmdlineIcon        = { fg = p.cyan },
  NoiceCmdlinePopup       = { fg = p.fg, bg = p.bg_float },
  NoiceCmdlinePopupBorder = { fg = p.border, bg = p.bg_float },
  NoiceCmdlinePopupTitle  = { fg = p.cyan, bold = true },
  NoiceConfirm            = { fg = p.fg, bg = p.bg_float },
  NoiceConfirmBorder      = { fg = p.border, bg = p.bg_float },
  NoiceMini               = { fg = p.fg_muted, bg = p.bg_alt },
  NoiceLspProgressTitle   = { fg = p.fg_muted },
  NoiceLspProgressClient  = { fg = p.cyan },
  NoiceLspProgressSpinner = { fg = p.blue_lt },
  NoiceFormatProgressDone = { fg = p.bg, bg = p.cyan },
  NoiceFormatProgressTodo = { fg = p.fg_muted, bg = p.bg_elev },

  -- nvim-notify
  NotifyERRORBorder = { fg = p.red },
  NotifyWARNBorder  = { fg = p.amber },
  NotifyINFOBorder  = { fg = p.blue_lt },
  NotifyDEBUGBorder = { fg = p.fg_faint },
  NotifyTRACEBorder = { fg = p.violet },
  NotifyERRORIcon   = { fg = p.red },
  NotifyWARNIcon    = { fg = p.amber },
  NotifyINFOIcon    = { fg = p.blue_lt },
  NotifyDEBUGIcon   = { fg = p.fg_faint },
  NotifyTRACEIcon   = { fg = p.violet },
  NotifyERRORTitle  = { fg = p.red, bold = true },
  NotifyWARNTitle   = { fg = p.amber, bold = true },
  NotifyINFOTitle   = { fg = p.blue_lt, bold = true },
  NotifyDEBUGTitle  = { fg = p.fg_faint, bold = true },
  NotifyTRACETitle  = { fg = p.violet, bold = true },
  NotifyERRORBody   = { fg = p.fg },
  NotifyWARNBody    = { fg = p.fg },
  NotifyINFOBody    = { fg = p.fg },
  NotifyDEBUGBody   = { fg = p.fg },
  NotifyTRACEBody   = { fg = p.fg },

  -- indent-blankline
  IblIndent        = { fg = p.border_dim },
  IblScope         = { fg = p.blue },
  IblWhitespace    = { fg = p.border_dim },

  -- blink.cmp
  BlinkCmpMenu            = { fg = p.fg, bg = p.bg_float },
  BlinkCmpMenuBorder      = { fg = p.border, bg = p.bg_float },
  BlinkCmpMenuSelection   = { bg = p.bg_sel, bold = true },
  BlinkCmpScrollBarThumb  = { bg = p.border },
  BlinkCmpScrollBarGutter = { bg = p.bg_elev },
  BlinkCmpLabel           = { fg = p.fg },
  BlinkCmpLabelMatch      = { fg = p.cyan, bold = true },
  BlinkCmpLabelDeprecated = { fg = p.fg_faint, strikethrough = true },
  BlinkCmpLabelDetail     = { fg = p.fg_muted },
  BlinkCmpLabelDescription= { fg = p.fg_faint },
  BlinkCmpKind            = { fg = p.blue_lt },
  BlinkCmpSource          = { fg = p.fg_faint },
  BlinkCmpGhostText       = { fg = p.ghost, italic = true },
  BlinkCmpDoc             = { fg = p.fg, bg = p.bg_float },
  BlinkCmpDocBorder       = { fg = p.border, bg = p.bg_float },
  BlinkCmpDocSeparator    = { fg = p.border_dim, bg = p.bg_float },
  BlinkCmpSignatureHelp   = { fg = p.fg, bg = p.bg_float },
  BlinkCmpSignatureHelpBorder = { fg = p.border, bg = p.bg_float },
  BlinkCmpSignatureHelpActiveParameter = { fg = p.cyan, bold = true },

  -- oil.nvim
  OilDir          = { fg = p.blue_lt },
  OilDirIcon      = { fg = p.blue },
  OilFile         = { fg = p.fg },
  OilLink         = { fg = p.cyan },
  OilCreate       = { fg = p.green },
  OilDelete       = { fg = p.red },
  OilMove         = { fg = p.amber },
  OilCopy         = { fg = p.ice },
  OilHidden       = { fg = p.fg_faint },
  OilPermissionRead  = { fg = p.green },
  OilPermissionWrite = { fg = p.amber },
  OilPermissionExecute = { fg = p.blue_lt },
  OilTypeDir      = { fg = p.ice },
  OilTypeFile     = { fg = p.fg_muted },

  -- dashboard
  DashboardHeader   = { fg = p.ice, bold = true },
  DashboardCenter   = { fg = p.blue_lt },
  DashboardShortCut = { fg = p.cyan },
  DashboardFooter   = { fg = p.fg_faint, italic = true },
  DashboardKey      = { fg = p.cyan, bold = true },
  DashboardDesc     = { fg = p.fg_muted },
  DashboardIcon     = { fg = p.blue },
  DashboardMruTitle = { fg = p.ice, bold = true },

  -- lazy.nvim
  LazyNormal        = { fg = p.fg, bg = p.bg_float },
  LazyButton        = { fg = p.fg_muted, bg = p.bg_elev },
  LazyButtonActive  = { fg = p.bg, bg = p.cyan, bold = true },
  LazyComment       = { fg = p.fg_faint, italic = true },
  LazyCommit        = { fg = p.amber },
  LazyDimmed        = { fg = p.fg_faint },
  LazyH1            = { fg = p.bg, bg = p.blue, bold = true },
  LazyH2            = { fg = p.ice, bold = true },
  LazyProgressDone  = { fg = p.cyan, bold = true },
  LazyProgressTodo  = { fg = p.border },
  LazyProp          = { fg = p.fg_muted },
  LazyReasonPlugin  = { fg = p.blue_lt },
  LazySpecial       = { fg = p.cyan },
  LazyUrl           = { fg = p.cyan, underline = true },

  -- mason
  MasonNormal              = { fg = p.fg, bg = p.bg_float },
  MasonHeader              = { fg = p.bg, bg = p.cyan, bold = true },
  MasonHeaderSecondary     = { fg = p.bg, bg = p.blue, bold = true },
  MasonHighlight           = { fg = p.cyan },
  MasonHighlightBlock      = { fg = p.bg, bg = p.blue },
  MasonHighlightBlockBold  = { fg = p.bg, bg = p.cyan, bold = true },
  MasonHighlightSecondary  = { fg = p.ice },
  MasonMuted               = { fg = p.fg_faint },
  MasonMutedBlock          = { fg = p.fg_muted, bg = p.bg_elev },
  MasonError               = { fg = p.red },
  MasonWarning             = { fg = p.amber },

  -- treesitter-context
  TreesitterContext           = { bg = p.bg_alt },
  TreesitterContextLineNumber = { fg = p.fg_faint, bg = p.bg_alt },
  TreesitterContextBottom     = { underline = true, sp = p.border_dim },

  -- mini.nvim
  MiniIconsAzure  = { fg = p.blue_lt },
  MiniIconsBlue   = { fg = p.blue },
  MiniIconsCyan   = { fg = p.cyan },
  MiniIconsGreen  = { fg = p.green },
  MiniIconsGrey   = { fg = p.fg_muted },
  MiniIconsOrange = { fg = p.amber },
  MiniIconsPurple = { fg = p.violet },
  MiniIconsRed    = { fg = p.red },
  MiniIconsYellow = { fg = p.sand },
  MiniStatuslineModeNormal  = { fg = p.bg, bg = p.cyan, bold = true },
  MiniStatuslineModeInsert  = { fg = p.bg, bg = p.green, bold = true },
  MiniStatuslineModeVisual  = { fg = p.bg, bg = p.violet, bold = true },
  MiniStatuslineModeReplace = { fg = p.bg, bg = p.amber, bold = true },
  MiniStatuslineModeCommand = { fg = p.bg, bg = p.ice, bold = true },
  MiniStatuslineDevinfo     = { fg = p.fg_muted, bg = p.bg_elev },
  MiniStatuslineFileinfo    = { fg = p.fg_muted, bg = p.bg_elev },
  MiniStatuslineFilename    = { fg = p.fg_dim, bg = p.bg_elev },
  MiniStatuslineInactive    = { fg = p.fg_faint, bg = p.bg_alt },
  MiniJump                  = { fg = p.bg, bg = p.violet },
  MiniJump2dSpot            = { fg = p.cyan, bold = true },
  MiniHipatternsFixme       = { fg = p.bg, bg = p.red, bold = true },
  MiniHipatternsHack        = { fg = p.bg, bg = p.amber, bold = true },
  MiniHipatternsNote        = { fg = p.bg, bg = p.cyan, bold = true },
  MiniHipatternsTodo        = { fg = p.bg, bg = p.ice, bold = true },
  MiniFilesBorder           = { fg = p.border, bg = p.bg_float },
  MiniFilesTitle            = { fg = p.cyan, bold = true },
  MiniFilesNormal           = { fg = p.fg, bg = p.bg_float },
  MiniFilesCursorLine       = { bg = p.bg_sel },

  -- nvim-cmp（保险起见也定义）
  CmpDocumentation       = { fg = p.fg, bg = p.bg_float },
  CmpDocumentationBorder = { fg = p.border, bg = p.bg_float },
  CmpItemAbbr            = { fg = p.fg },
  CmpItemAbbrDeprecated  = { fg = p.fg_faint, strikethrough = true },
  CmpItemAbbrMatch       = { fg = p.cyan, bold = true },
  CmpItemAbbrMatchFuzzy  = { fg = p.cyan },
  CmpItemMenu            = { fg = p.fg_faint },
  CmpItemKind            = { fg = p.blue_lt },
})
