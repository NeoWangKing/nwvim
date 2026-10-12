-- latex-check.lua - 用 treesitter 检查 markdown 里 LaTeX 公式的语法错误，不做渲染。
-- 只查语法错误（缺 }、缺 \right、缺下标内容等），未知命令、环境名不匹配这类语义错误查不出。
-- 注入链是 markdown -> markdown_inline -> latex，必须递归遍历 LanguageTree，children() 只给一层。

local M = {}

local ns = vim.api.nvim_create_namespace("latex_syntax_check")

-- 只对 markdown 生效
local FILETYPES = { markdown = true }

-- 超大文件跳过，避免卡顿
local MAX_LINES = 20000

-- 防抖延迟：避免连续输入时每个字符都跑一遍
local DEBOUNCE_MS = 300

-- 把文本整理成一行短摘要
---@param text string
local function brief(text)
  text = (text or ""):gsub("%s+", " ")
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  if #text > 40 then text = text:sub(1, 40) .. "…" end
  return text
end

-- 递归收集 LanguageTree 下所有 latex 注入的语法错误
---@param bufnr integer
-- 给诊断找下划线范围：missing 节点是零宽的，直接画不出来，要往上找父节点；
-- 父节点常跨多行，统一截断到起始行——缺失是一个点，划一行就够。
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
              -- 用节点自身文本而不是整行原文，避免把公式周围的散文带进消息。
              local text = brief(vim.treesitter.get_node_text(node, bufnr))
              msg = "LaTeX 语法错误" .. (#text > 0 and ("：" .. text) or "")
              severity = vim.diagnostic.severity.ERROR
            else
              -- missing 是 parser 为恢复补出来的记号，node:type() 就是缺的那个东西（如 "}"）。
              -- 标 WARN 而不是 ERROR：输入过程中"还没打完"是常态，别边写边被红色警报打断。
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

-- parser 装在数据目录、不在仓库里；换机器没跑 :TSInstall 时这里会静默不工作，所以缺了就提示一次。
local warned = false
local function check_parsers()
  if warned then return true end

  -- 老版本没有 language.add 时无法可靠判断，直接放行，宁可漏报。
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

-- 对指定缓冲区跑一次检查
---@param bufnr integer
function M.check(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if not FILETYPES[vim.bo[bufnr].filetype] then return end
  if vim.api.nvim_buf_line_count(bufnr) > MAX_LINES then return end

  -- 必须在 get_parser 之前查：markdown parser 缺失时 get_parser 直接失败，永远走不到提示。
  if not check_parsers() then return end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "markdown")
  if not ok or not parser then return end

  local parse_ok = pcall(function() parser:parse(true) end)
  if not parse_ok then return end

  local diags = {}
  pcall(collect, bufnr, parser, diags)

  vim.diagnostic.set(ns, bufnr, diags)
end

-- 在缓冲区上挂自动检查
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

-- 全局诊断关了 virtual_text 是为了 LSP 不打扰写作；公式错误需要立刻看到，所以按 namespace 单独开行内提示和下划线。
-- 下划线显式开启：按 namespace 配置不一定继承全局默认值，而错误位置主要靠下划线表达。
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
