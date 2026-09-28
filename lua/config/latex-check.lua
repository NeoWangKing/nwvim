-- ═══════════════════════════════════════════════════════════════════════
--  lua/config/latex-check.lua — 检查 markdown 里 LaTeX 公式的语法错误
--
--  【为什么需要它】
--  render-markdown.nvim 的公式渲染（utftex）已经关掉了：实测在
--  $$...\begin{align}...$$ 这类多行环境里不可靠，x_M 的下标会被拆成两行，
--  渲染结果反而比原文难读。
--  但公式写错（少个 }、\left 没有 \right）是真实痛点，而且写的时候不容易
--  自己发现。所以这里只做「语法检查」，不做「排版渲染」。
--
--  【怎么做的】
--  不引入任何外部程序，纯粹用已经装好的 treesitter：
--    markdown → markdown_inline → latex（nvim-treesitter 的注入查询）
--  nvim-treesitter 的 markdown_inline/injections.scm 里有
--    ((latex_block) @injection.content (#set! injection.language "latex"))
--  所以 $...$ 和 $$...$$ 里的内容会被交给 latex parser 解析。
--  LaTeX 有语法错误时，parser 会产生 ERROR 节点或 missing 节点，把它们
--  转成 diagnostic 就行。
--
--  【能查出什么 / 查不出什么】
--  实测能查：
--    \frac{a}{b      → ERROR（少右括号）
--    x^2}            → ERROR（多右括号）
--    \left( a + b    → ERROR（缺 \right）
--    x_              → missing（下标缺内容）
--    \end{align      → missing（命令缺 }）
--  实测查不出（属于语义而非语法，parser 无法判断）：
--    \thisisnotacommand{x}       未知命令
--    \begin{align}...\end{equation}  环境名不匹配
--  这两类要靠真正编译或 texlab 才能发现，不在本模块职责内。
--
--  【注意】
--  注入是嵌套的（markdown → markdown_inline → latex），必须递归遍历
--  LanguageTree，直接看 parser:children() 只会看到 markdown_inline 一层。
-- ═══════════════════════════════════════════════════════════════════════

local M = {}

local ns = vim.api.nvim_create_namespace("latex_syntax_check")

-- 只对 markdown 生效
local FILETYPES = { markdown = true }

-- 单次检查的输入上限（按注释行数），超大文件不做检查以免卡顿
local MAX_LINES = 20000

-- 编辑后延迟多久检查（毫秒）。treesitter 解析本身很快，
-- 这点延迟主要是为了避免连续输入时每个字符都跑一遍。
local DEBOUNCE_MS = 300

--- 把任意文本整理成一行短摘要
---@param text string
local function brief(text)
  text = (text or ""):gsub("%s+", " ")
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  if #text > 40 then text = text:sub(1, 40) .. "…" end
  return text
end

--- 递归收集某个 LanguageTree 下所有 latex 注入的语法错误
---@param bufnr integer
--- 给一个诊断算出「该在哪里画下划线」。
--
-- 关键在于 missing 节点是**零宽**的（parser 只是标记「这里缺东西」），
-- 直接拿它的 range 会导致区间为空、下划线根本画不出来。
-- 所以要往上找父节点，取那个真正写坏了的构造。
--
-- 实测 \begin{aligned 缺 } 时的节点链：
--   }                    range=2:0-2:0   （零宽，不能用）
--   ↳ curly_group_text   range=1:6-2:0   text="{aligned"   ← 这个才对
--   ↳ begin              range=1:0-2:0   text="\begin{aligned"
--   ↳ math_environment   （整个环境，太大）
--
-- 注意父节点常常跨到下一行（上面 curly_group_text 就跨了 2 行），
-- 直接采用会把公式正文也划上下划线、看起来像「整段都错」。
-- 所以最后统一截断到起始行——缺失是一个「点」，划一行就够，
-- 也符合直觉：错的是那一行的那个构造。
---@param node table
---@param bufnr integer
---@return integer sr, integer sc, integer er, integer ec
local function underline_range(node, bufnr)
  local MAX_SPAN = 3  -- 父节点最多容忍跨几行，超过就完全不用它

  local sr, sc, er, ec = node:range()
  if not (er > sr or ec > sc) then
    -- 零宽区间（missing 节点），往上找第一个够小且非空的父节点
    local par, depth = node:parent(), 0
    while par and depth < 6 do
      local a, b, c, d = par:range()
      if (c > a or d > b) and (c - a) <= MAX_SPAN then
        sr, sc, er, ec = a, b, c, d
        break
      end
      par = par:parent()
      depth = depth + 1
    end
  end

  -- 截断到起始行
  if er > sr then
    local line = vim.api.nvim_buf_get_lines(bufnr, sr, sr + 1, false)[1] or ""
    er, ec = sr, #line
  end

  -- 兜底：万一算出来还是空的（例如空行），至少给 1 个字符宽
  if er == sr and ec <= sc then
    local line = vim.api.nvim_buf_get_lines(bufnr, sr, sr + 1, false)[1] or ""
    ec = math.min(#line, sc + 1)
  end

  return sr, sc, er, ec
end

---@param lt table LanguageTree
---@param diags table[]
local function collect(bufnr, lt, diags)
  for lang, child in pairs(lt:children()) do
    if lang == "latex" then
      pcall(function() child:parse(true) end)

      for _, tree in ipairs(child:trees()) do
        local root = tree:root()

        local function walk(node)
          local t = node:type()
          if t == "ERROR" or node:missing() then
            local sr, sc, er, ec = underline_range(node, bufnr)

            local msg, severity
            if t == "ERROR" then
              -- 用节点自身的文本，而不是整行原文——否则会把公式周围的
              -- 散文一起带进消息里，反而看不出问题在哪。
              local text = brief(vim.treesitter.get_node_text(node, bufnr))
              msg = "LaTeX 语法错误" .. (#text > 0 and ("：" .. text) or "")
              severity = vim.diagnostic.severity.ERROR
            else
              -- missing 节点：parser 为了恢复而补出来的记号，
              -- node:type() 就是它期待的那个记号（例如 "}"）。
              --
              -- 这里标成 WARN 而不是 ERROR，是有意的：
              -- 输入过程中「还没打完」是常态——光标停在 \begin{aligned
              -- 的那一刻确实缺 }，但那不是错误。用黄色提示、别用红色报错，
              -- 免得边写边被红色警报打断。真正写坏的结构会落到 ERROR（红色）。
              msg = "LaTeX 语法不完整：缺少 `" .. t .. "`"
              severity = vim.diagnostic.severity.WARN
            end

            diags[#diags + 1] = {
              lnum = sr,
              col = sc,
              end_lnum = er,
              end_col = ec,
              message = msg,
              severity = severity,
              source = "latex",
            }
          end

          for c in node:iter_children() do
            if c then walk(c) end
          end
        end

        walk(root)
      end
    end

    -- 继续往下找嵌套的注入
    collect(bufnr, child, diags)
  end
end

--- 检查所需 parser 是否齐全；缺了就提示一次。
--
-- 为什么需要：parser 装在数据目录（~/.local/share/nvim/site/parser/），
-- **不在配置仓库里**。换一台机器（例如从 macOS 挪到 Linux）clone 完配置后，
-- 如果没跑过 :TSInstall，本模块会静默什么都不做——看起来像"功能坏了"，
-- 实际只是缺 parser。这里让它变成一条明确的提示。
local warned = false
local function check_parsers()
  if warned then return true end

  -- 老版本 Neovim 没有 language.add。这种情况下无法可靠判断，
  -- 直接放行——宁可漏报，也不要因为 API 不存在而误报「缺 parser」。
  if type(vim.treesitter.language.add) ~= "function" then return true end

  local missing = {}
  for _, lang in ipairs({ "markdown", "markdown_inline", "latex" }) do
    if not pcall(vim.treesitter.language.add, lang) then
      missing[#missing + 1] = lang
    end
  end
  if #missing > 0 then
    warned = true
    vim.notify(
      "LaTeX 语法检查需要这些 treesitter parser，但当前缺失："
        .. table.concat(missing, ", ")
        .. "\n执行 :TSInstall " .. table.concat(missing, " ") .. " 即可。",
      vim.log.levels.WARN
    )
    return false
  end
  return true
end

--- 对指定缓冲区跑一次检查
---@param bufnr integer
function M.check(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if not FILETYPES[vim.bo[bufnr].filetype] then return end
  if vim.api.nvim_buf_line_count(bufnr) > MAX_LINES then return end

  -- ⚠ 必须放在 get_parser 之前：markdown parser 本身就缺的话，
  -- get_parser 会直接失败，那样就永远走不到提示那一步了
  -- （第一版就是写反了，实测缺 parser 时一声不吭）。
  if not check_parsers() then return end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "markdown")
  if not ok or not parser then return end

  local parse_ok = pcall(function() parser:parse(true) end)
  if not parse_ok then return end

  local diags = {}
  pcall(collect, bufnr, parser, diags)

  vim.diagnostic.set(ns, bufnr, diags)
end

--- 在缓冲区上挂自动检查
---@param bufnr integer
function M.attach(bufnr)
  local timer = vim.uv.new_timer()

  local function schedule()
    timer:stop()
    timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(function()
      if vim.api.nvim_buf_is_valid(bufnr) then M.check(bufnr) end
    end))
  end

  local group = vim.api.nvim_create_augroup("LatexCheck" .. bufnr, { clear = true })

  vim.api.nvim_buf_create_user_command(bufnr, "LatexCheck", function()
    M.check(bufnr)
  end, { desc = "立即检查 LaTeX 公式语法" })

  vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "BufWritePost" }, {
    group = group,
    buffer = bufnr,
    callback = schedule,
  })

  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group,
    buffer = bufnr,
    once = true,
    callback = function()
      timer:stop()
      timer:close()
      vim.diagnostic.reset(ns, bufnr)
    end,
  })

  -- 打开文件先检查一次，不用等编辑
  schedule()
end

-- markdown 缓冲区里自动挂上
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("LatexCheckSetup", { clear = true }),
  pattern = "markdown",
  callback = function(ev) M.attach(ev.buf) end,
})

-- 只让 LaTeX 语法错误显示行内提示 + 下划线。
--
-- 全局诊断配置（config/keymaps.lua）里关掉了 virtual_text，那是为了让 LSP
-- 诊断不打扰写作；但公式语法错误是「写完立刻要知道」的信息，藏在 signcolumn
-- 里容易漏掉。所以这里按 namespace 单独开启，不影响 LSP 的显示方式。
--
-- underline 显式写出来：按 namespace 配置时不一定继承全局默认值，
-- 而「哪里写错了」最主要靠下划线表达，不能依赖默认。
--
-- 呈现效果（和写 C 代码时的 LSP 诊断一致）：
--   ● 红色下划线 = ERROR，结构确实写坏了
--   ● 黄色下划线 = WARN，多半是还没打完（例如光标刚停在 \begin{aligned）
--   [d / ]d      = 跳到上/下一个，详见 config/keymaps.lua
--   <space>ee    = 弹出悬浮窗看完整信息
vim.diagnostic.config({
  underline = true,
  virtual_text = {
    prefix = "●",
    spacing = 1,
    source = false,
  },
  signs = true,
}, ns)

return M
