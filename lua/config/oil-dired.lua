-- ═══════════════════════════════════════════════════════════════════════
--  lua/config/oil-dired.lua — 给 oil.nvim 补一层 Emacs dired 的行为
--
--  【为什么 oil 只差一半】
--  dired 有两块核心：
--    A. 可编辑的目录缓冲区（wdired）——「改名=编辑行、删除=删行、:w 提交」
--    B. 标记 + 批量执行 ——「m 标记、d 标记删除、x 执行、%m 按正则标记」
--
--  A 这块 oil 天生就是（它就是 wdired 的现代实现），而且比 dired 更安全：
--  :w 之前随时可以反悔。所以本模块不碰 A，只补 B。
--
--  【oil 架构决定的硬限制，做不到的部分】
--   · dired 的 `i`（把子目录列表插进同一个 buffer）—— oil 是一个 buffer 对应
--     一个目录，没有插入子目录的机制
--   · dired 的 `(` / `)`（在缓冲区里的多个目录间跳转）—— 同上
--   · dired 的 `k`（把某行从列表里隐藏掉）—— 需要改写 view_options，且是全局的
-- ═══════════════════════════════════════════════════════════════════════

local M = {}

local oil = require("oil")

local mark_ns = vim.api.nvim_create_namespace("oil_dired_marks")
local HL_GROUP = "OilDiredMark"

-- 让标记行有可见的背景。用 link 到 Visual，语义相近且不用改主题；
-- 想自定义就在主题里定义 OilDiredMark。
vim.api.nvim_set_hl(0, HL_GROUP, { link = "Visual", default = true })

-- ── 标记状态 ───────────────────────────────────────────────────────────
-- 以「绝对路径」为键，而不是行号 —— 这样 oil 刷新缓冲区、改变排序、
-- 或增删行之后，标记依然跟着文件走。
--
-- 注意：这里用模块级的 Lua 表，而不是 vim.b[bufnr]。
-- 因为 vim.b[bufnr] 每次访问返回的都是一个新副本（rawequal 为 false），
-- 所以 marks[path] = true 这种嵌套写入会被静默丢弃 —— 实测确认过。
local mark_store = {}

---@param bufnr? integer
---@return table<string, boolean>
local function marks(bufnr)
  if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
  if not mark_store[bufnr] then
    mark_store[bufnr] = {}
  end
  return mark_store[bufnr]
end

--- 供外部/测试读取当前标记（返回副本，避免外部误改内部状态）
---@param bufnr? integer
---@return string[]
function M.get_marks(bufnr)
  local out = {}
  for path in pairs(marks(bufnr)) do out[#out + 1] = path end
  table.sort(out)
  return out
end

local function is_oil_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return vim.bo[bufnr].filetype == "oil"
end

--- 遍历 oil 缓冲区里所有真实条目（跳过首行的父目录 ".."）
---@param bufnr integer
---@param fn fun(lnum: integer, path: string, name: string)
local function each_entry(bufnr, fn)
  local dir = oil.get_current_dir(bufnr)
  if not dir then return end
  for lnum = 1, vim.api.nvim_buf_line_count(bufnr) do
    local entry = oil.get_entry_on_line(bufnr, lnum)
    if entry and entry.name ~= ".." then
      fn(lnum, dir .. entry.name, entry.name)
    end
  end
end

-- ── 标记的可视化 ───────────────────────────────────────────────────────
function M.render(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not is_oil_buffer(bufnr) then return end
  vim.api.nvim_buf_clear_namespace(bufnr, mark_ns, 0, -1)

  local m = marks(bufnr)
  each_entry(bufnr, function(lnum, path)
    if m[path] then
      pcall(vim.api.nvim_buf_set_extmark, bufnr, mark_ns, lnum - 1, 0, {
        line_hl_group = HL_GROUP,
        priority = 200,
      })
    end
  end)
end

-- ── 标记操作（对应 dired 的 m / u / U / t / %m）────────────────────────

--- dired 的 m：标记 / 取消标记光标所在行
function M.toggle_mark()
  local bufnr = vim.api.nvim_get_current_buf()
  if not is_oil_buffer(bufnr) then return end
  local dir = oil.get_current_dir(bufnr)
  local entry = oil.get_entry_on_line(bufnr, vim.fn.line("."))
  if not entry or entry.name == ".." or not dir then return end

  local path = dir .. entry.name
  local m = marks(bufnr)
  if m[path] then
    m[path] = nil
  else
    m[path] = true
  end
  M.render(bufnr)
end

--- dired 的 u：取消光标所在行的标记
function M.unmark()
  local bufnr = vim.api.nvim_get_current_buf()
  if not is_oil_buffer(bufnr) then return end
  local dir = oil.get_current_dir(bufnr)
  local entry = oil.get_entry_on_line(bufnr, vim.fn.line("."))
  if not entry or entry.name == ".." or not dir then return end
  marks(bufnr)[dir .. entry.name] = nil
  M.render(bufnr)
end

--- dired 的 U：清除全部标记
function M.unmark_all()
  local bufnr = vim.api.nvim_get_current_buf()
  if not is_oil_buffer(bufnr) then return end
  mark_store[bufnr] = {}
  M.render(bufnr)
  vim.notify("已清除全部标记", vim.log.levels.INFO)
end

--- dired 的 t：反转标记
function M.invert_marks()
  local bufnr = vim.api.nvim_get_current_buf()
  if not is_oil_buffer(bufnr) then return end
  local m = marks(bufnr)
  local next_m = {}
  each_entry(bufnr, function(_, path)
    if not m[path] then next_m[path] = true end
  end)
  mark_store[bufnr] = next_m
  M.render(bufnr)
end

--- dired 的 % m：按正则标记（Lua 正则）
function M.mark_by_pattern()
  local bufnr = vim.api.nvim_get_current_buf()
  if not is_oil_buffer(bufnr) then return end

  vim.ui.input({ prompt = "标记匹配的文件名（Lua 正则，如 %.lua$ ）: " }, function(pat)
    if not pat or pat == "" then return end
    local ok, err = pcall(string.find, "", pat)
    if not ok then
      vim.notify("正则无效: " .. tostring(err), vim.log.levels.ERROR)
      return
    end

    local m = marks(bufnr)
    local matched, added = 0, 0
    each_entry(bufnr, function(_, path, name)
      if name:find(pat) then
        matched = matched + 1
        if not m[path] then added = added + 1 end
        m[path] = true
      end
    end)
    M.render(bufnr)

    -- %m 是「累加」标记，不会清掉已有标记（与 dired 的 % m 一致）。
    -- 所以要把「命中数」和「实际新增数」分开报，否则已标记过的文件会让
    -- 计数看起来对不上。
    local total = 0
    for _ in pairs(m) do total = total + 1 end
    local msg = string.format("匹配 %d 个，新增标记 %d 个，当前共标记 %d 个",
      matched, added, total)
    vim.notify(msg, vim.log.levels.INFO)
  end)
end

-- ── 取操作目标 ─────────────────────────────────────────────────────────
--- 优先用标记；没有标记时退回「可视选区」或「光标所在行」
---@return string[] paths
---@return string label  用来在提示里说明操作范围
function M.targets()
  local bufnr = vim.api.nvim_get_current_buf()
  if not is_oil_buffer(bufnr) then return {}, "非 oil 缓冲区" end

  local m = marks(bufnr)
  local marked = {}
  each_entry(bufnr, function(_, path)
    if m[path] then marked[#marked + 1] = path end
  end)
  if #marked > 0 then
    return marked, string.format("%d 个已标记", #marked)
  end

  -- 没有标记：可视模式取选区，否则取光标行
  local dir = oil.get_current_dir(bufnr)
  if not dir then return {}, "" end

  local s, e
  local mode = vim.fn.mode(1)
  -- 可视模式有三种，mode() 的返回值大小写不同：
  --   "v" 逐字符、"V" 逐行、"\22"（<C-v>）块选择。
  -- 注意逐行是**大写 V**，只匹配小写 v 会漏掉最常见的 V 选择。
  if mode == "v" or mode == "V" or mode == "\22" then
    s, e = vim.fn.line("v"), vim.fn.line(".")
    -- Lua 回调形式的可视模式映射结束后**不会**自动退出可视模式，
    -- 所以这里主动退出，否则用户下一次按键会落在一个仍然有效的选区上。
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  else
    s, e = vim.fn.line("."), vim.fn.line(".")
  end
  if s > e then s, e = e, s end

  local out = {}
  for l = s, e do
    local entry = oil.get_entry_on_line(bufnr, l)
    if entry and entry.name ~= ".." then out[#out + 1] = dir .. entry.name end
  end
  return out, string.format("%d 个选中", #out)
end

-- ── 执行层 ─────────────────────────────────────────────────────────────
local function refresh()
  vim.schedule(function()
    if is_oil_buffer() then pcall(vim.cmd, "edit!") end
  end)
end

--- 对每个目标各执行一条命令（命令串形式，用于需要管道的场景）
local function run_each(argv_of, desc)
  local paths, label = M.targets()
  if #paths == 0 then
    vim.notify("没有可操作的目标（先 m 标记，或选中若干行）", vim.log.levels.WARN)
    return
  end
  local left = #paths
  for _, p in ipairs(paths) do
    vim.fn.jobstart(argv_of(p), {
      on_exit = function(_, code)
        left = left - 1
        if code ~= 0 then
          vim.schedule(function()
            vim.notify(string.format("%s 失败: %s", desc, vim.fn.fnamemodify(p, ":t")), vim.log.levels.ERROR)
          end)
        end
        if left == 0 then refresh() end
      end,
    })
  end
  vim.notify(string.format("%s：对 %s 执行中…", desc, label), vim.log.levels.INFO)
end

--- 对全部目标一次性执行（chmod / touch 这类可接多文件参数的命令）
local function run_bulk(cmd, desc)
  local paths, label = M.targets()
  if #paths == 0 then
    vim.notify("没有可操作的目标（先 m 标记，或选中若干行）", vim.log.levels.WARN)
    return
  end
  vim.fn.jobstart(vim.list_extend({ cmd }, paths), {
    on_exit = function(_, code)
      vim.schedule(function()
        if code ~= 0 then
          vim.notify(string.format("%s 失败（退出码 %d）", desc, code), vim.log.levels.ERROR)
        else
          vim.notify(string.format("%s：已处理 %s", desc, label), vim.log.levels.INFO)
        end
        refresh()
      end)
    end,
  })
end

-- ── dired 的命令（! / M / T / Z / D）───────────────────────────────────

--- dired 的 !：对目标执行自定义 shell 命令
--- 命令里写 {} 会替换成文件名；不写则自动追加
function M.shell_command()
  local paths, label = M.targets()
  if #paths == 0 then
    vim.notify("没有可操作的目标", vim.log.levels.WARN)
    return
  end
  vim.ui.input({ prompt = string.format("对 %s 执行（{} = 文件名）: ", label) }, function(cmd)
    if not cmd or cmd == "" then return end
    run_each(function(p)
      local f = vim.fn.shellescape(p)
      if cmd:find("{}", 1, true) then
        return (cmd:gsub("{}", f))
      end
      return cmd .. " " .. f
    end, "shell 命令")
  end)
end

--- dired 的 M：chmod
function M.chmod()
  vim.ui.input({ prompt = "权限（如 644 / 755 / +x）: " }, function(mode)
    if not mode or mode == "" then return end
    local paths, _ = M.targets()
    if #paths == 0 then
      vim.notify("没有可操作的目标", vim.log.levels.WARN)
      return
    end
    vim.fn.jobstart(vim.list_extend({ "chmod", mode }, paths), {
      on_exit = function(_, code)
        vim.schedule(function()
          if code ~= 0 then
            vim.notify("chmod 失败", vim.log.levels.ERROR)
          else
            vim.notify(string.format("chmod %s：%d 个文件", mode, #paths), vim.log.levels.INFO)
          end
          refresh()
        end)
      end,
    })
  end)
end

--- dired 的 T：touch
function M.touch() run_bulk("touch", "touch") end

--- dired 的 Z：gzip 压缩（-k 保留原文件）
function M.compress()
  run_each(function(p) return "gzip -k " .. vim.fn.shellescape(p) end, "gzip")
end

--- 暂存删除：把目标行从列表里删掉（不落盘，:w 才提交）
--- 目标同样走「标记 > 可视选区 > 光标行」三级优先，与其它操作保持一致
--- （dired 的 d 在未标记行上也是对当前行生效）。
--- 因为只改缓冲区、且可以 u 撤销，所以在光标行上直接删是安全的。
function M.delete_marked()
  local bufnr = vim.api.nvim_get_current_buf()
  if not is_oil_buffer(bufnr) then return end

  local paths, label = M.targets()
  if #paths == 0 then
    vim.notify("没有可删除的目标（先 m 标记，或把光标移到某一行）", vim.log.levels.WARN)
    return
  end

  local want = {}
  for _, p in ipairs(paths) do want[p] = true end

  local lines_to_delete = {}
  each_entry(bufnr, function(lnum, path)
    if want[path] then lines_to_delete[#lines_to_delete + 1] = lnum end
  end)
  if #lines_to_delete == 0 then
    vim.notify("没找到对应的行", vim.log.levels.WARN)
    return
  end

  -- 从后往前删，避免行号错位
  table.sort(lines_to_delete, function(a, b) return a > b end)
  for _, lnum in ipairs(lines_to_delete) do
    pcall(vim.api.nvim_buf_set_lines, bufnr, lnum - 1, lnum, false, {})
  end

  mark_store[bufnr] = {}
  M.render(bufnr)
  if not vim.bo[bufnr].modified then
    vim.bo[bufnr].modified = true
  end
  vim.notify(
    string.format(
      "已暂存删除 %d 项（%s）—— 按 :w 提交（oil 会弹确认框，按 y 确认）；u 可撤销",
      #lines_to_delete, label
    ),
    vim.log.levels.INFO
  )
end

-- ── 初始化 ─────────────────────────────────────────────────────────────
local aug = vim.api.nvim_create_augroup("OilDired", { clear = true })

-- 进入 oil 缓冲区时重新绘制标记（oil 会重写缓冲区内容，extmark 需要重建）
vim.api.nvim_create_autocmd("FileType", {
  group = aug,
  pattern = "oil",
  callback = function(ev)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then M.render(ev.buf) end
    end)
  end,
})

-- 缓冲区销毁时清掉它的标记，避免 bufnr 被复用后出现幽灵标记
vim.api.nvim_create_autocmd("BufWipeout", {
  group = aug,
  callback = function(ev) mark_store[ev.buf] = nil end,
})

return M
