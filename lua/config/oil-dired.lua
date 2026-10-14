-- oil-dired.lua - 给 oil.nvim 补上 Emacs dired 的标记 + 批量执行。
-- oil 本身已经是 wdired（改名 = 编辑行，:w 提交），这里只补 m / U / t / %m 标记和批量命令
-- （dired 的 u 没做：把 u 从 vim 的撤销手里抢走不划算，见 AGENT.md 陷阱 17）。
-- 做不到的：dired 的 i（子目录插入当前 buffer）、( / ) 多目录跳转、k 隐藏行，都是 oil 架构限制。
-- 文件操作（chmod / touch / gzip）一律走 config/platform.lua：那边的三个命令在
-- Windows 上没有，只有平台层知道该怎么替代。

local M = {}

local oil = require("oil")
local P = require("config.platform")

local mark_ns = vim.api.nvim_create_namespace("oil_dired_marks")
local HL_GROUP = "OilDiredMark"

-- 标记行高亮 link 到 Visual；想自定义就在主题里定义 OilDiredMark。
vim.api.nvim_set_hl(0, HL_GROUP, { link = "Visual", default = true })

-- 标记状态
-- 标记以绝对路径为键，刷新/排序/增删行后依然跟着文件。
-- 不能用 vim.b[bufnr]：每次访问返回新副本，嵌套写入会被静默丢弃，所以用模块级表。
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

-- 供外部/测试读取当前标记（返回副本）
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

-- 遍历 oil 缓冲区里所有真实条目（跳过首行的父目录 ".."）
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

-- 标记可视化
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

-- 标记操作（m / u / U / t / %m）

-- dired 的 m：标记 / 取消标记光标所在行
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

-- dired 的 U：清除全部标记
function M.unmark_all()
  local bufnr = vim.api.nvim_get_current_buf()
  if not is_oil_buffer(bufnr) then return end
  mark_store[bufnr] = {}
  M.render(bufnr)
  vim.notify("已清除全部标记", vim.log.levels.INFO)
end

-- dired 的 t：反转标记
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

-- dired 的 % m：按正则标记（Lua 正则）
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

    -- %m 是累加标记，不清已有；命中数和新增数要分开报，否则已标记过的文件会让计数对不上。
    local total = 0
    for _ in pairs(m) do total = total + 1 end
    local msg = string.format("匹配 %d 个，新增标记 %d 个，当前共标记 %d 个",
      matched, added, total)
    vim.notify(msg, vim.log.levels.INFO)
  end)
end

-- 取操作目标
-- 操作目标：标记 > 可视选区 > 光标行
---@return string[] paths
---@return string label
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
  -- 可视模式有三种：v 逐字符、V 逐行、<C-v> 块选择；逐行是大写 V，只匹配小写会漏掉。
  if mode == "v" or mode == "V" or mode == "\22" then
    s, e = vim.fn.line("v"), vim.fn.line(".")
    -- Lua 回调的可视模式映射结束后不会自动退出可视模式，这里主动退一次。
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

-- 执行层
local function refresh()
  vim.schedule(function()
    if is_oil_buffer() then pcall(vim.cmd, "edit!") end
  end)
end

-- 对每个目标各执行一条命令（命令串形式，用于需要管道的场景）
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

-- 取目标 → 交给 platform.lua 执行 → 统一报结果并刷新目录。
-- 没有目标时先提示，别让用户敲完权限串才发现没选东西。
local function warn_no_targets()
  vim.notify("没有可操作的目标（先用 <leader>m 标记，或在可视模式下选中若干行）", vim.log.levels.WARN)
  return false
end

--- 生成「执行完通知 + 刷新」的回调
---@param desc string
---@param label string
local function reporter(desc, label)
  return function(ok, err)
    vim.schedule(function()
      if ok then
        vim.notify(string.format("%s：已处理 %s", desc, label), vim.log.levels.INFO)
      else
        vim.notify(string.format("%s 失败：%s", desc, err or "未知错误"), vim.log.levels.ERROR)
      end
      refresh()
    end)
  end
end

-- dired 命令（! / M / T / Z / D）

-- dired 的 !：对目标执行自定义 shell 命令
-- 命令里写 {} 会替换成文件名；不写则自动追加
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

-- dired 的 M：chmod
function M.chmod()
  local paths, label = M.targets()
  if #paths == 0 then return warn_no_targets() end

  vim.ui.input({ prompt = string.format("对 %s 设置权限（644 / 755 / +x）: ", label) }, function(mode)
    if not mode or mode == "" then return end
    P.chmod(paths, mode, reporter("chmod " .. mode, label))
  end)
end

-- dired 的 T：touch
function M.touch()
  local paths, label = M.targets()
  if #paths == 0 then return warn_no_targets() end
  P.touch(paths, reporter("touch", label))
end

-- dired 的 Z：gzip 压缩（-k 保留原文件）
function M.compress()
  local paths, label = M.targets()
  if #paths == 0 then return warn_no_targets() end
  P.compress(paths, reporter("gzip -k", label))
end

-- 暂存删除：删行不落盘，:w 才提交。目标同样走标记 > 选区 > 光标行，只改缓冲区且可 u 撤销。
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

-- 初始化
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
