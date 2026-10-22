-- run.lua - :Run 的实现：异步跑一条命令，输出**实时**追加到一个独立的 scratch 窗口里，
-- 并且能像 Emacs 的 *compilation* 那样从报错行直接跳到出错位置。
--
-- 为什么不用 :!
--   :! 会阻塞界面，输出进消息区（超过 cmdheight 要按 ENTER），noice 还会把它收进命令行弹窗，
--   长输出既翻不了也留不住。这里开一个底部窗口流式追加，结束后补一行状态。
--
-- 命令注册在 lua/config/commands.lua。
--
-- 三个必须踩对的点：
--   1) jobstart 的回调跑在 fast event context 里，**不能直接调 nvim API**，
--      所以「写缓冲区」一律经 vim.schedule（这个仓库的老代码在 on_exit 里也是这么做的）。
--   2) stdout/stderr 的分块末尾可能是半行，要按流各自缓存，不能直接当整行写进去；
--      flush 放在 on_exit，否则最后一行永远缺着。
--   3) 位置信息**自己按行认**，不交给 'errorformat'。原因见 split_location 上的注释：
--      setqflist 解析相对路径用的是 nvim 的工作目录，而这里是在「文件所在目录」跑的。

local M = {}

local BUF_NAME = "[Run]"
local NS = vim.api.nvim_create_namespace("run_output")

-- 输出窗口的高亮组。全部用 link + default = true：
-- 这样默认跟着主题的诊断色走，主题里想单独调也不会被这里覆盖。
local function define_highlights()
  local hl = vim.api.nvim_set_hl
  hl(0, "RunOutputFile", { link = "Directory", default = true })          -- 文件名
  hl(0, "RunOutputLocation", { link = "Title", default = true })          -- :行:列（加粗）
  hl(0, "RunOutputError", { link = "DiagnosticError", default = true })
  hl(0, "RunOutputWarning", { link = "DiagnosticWarn", default = true })
  hl(0, "RunOutputInfo", { link = "DiagnosticInfo", default = true })
  -- "$ "、"--> "、上下文行的行号与竖线。
  -- 别 link 到 Comment：本仓库主题里 Comment 是**斜体**（italic = true），
  -- 会让 gcc 那些 `|` 竖线和行号一起变斜（实测发现的）。LineNr 是同色系但不斜的组。
  hl(0, "RunOutputPrompt", { link = "LineNr", default = true })
end

define_highlights()

local state = {
  buf = nil,     -- 输出缓冲区
  win = nil,     -- 输出窗口（用户可能已经关掉）
  src_win = nil, -- 发起 :Run 时所在的窗口（跳转优先回到它）
  src_buf = nil, -- 发起 :Run 时所在的缓冲区（焦点在输出窗口里再跑一次时要靠它找回目录）
  job = nil,     -- 正在跑的进程；nil = 空闲
  run = 0,       -- 每次运行自增，用来丢弃「已被新一次运行取代」的收尾
  dir = nil,     -- 本次运行的工作目录（解析报错路径用）
}

-- ── 认「文件:行:列: 消息」这类位置信息 ──────────────────────────

---认出一行开头的「位置前缀」，并给出**字节范围**（高亮要用）。
---支持的写法（前面允许缩进，也允许 rustc 的 `--> ` 箭头）：
---    foo.c:12:3: error: ...      GCC / Clang / Go / tsc
---    foo.c:12: message           只有行号
---    foo.c(12): error C1234: ... MSVC
---    --> src/main.rs:3:9          rustc / cargo
---    foo.py:12:3 - error: ...     pyright
---@param text string
---@return { file: string, line: integer?, col: integer?, msg: string,
---          file_s: integer, file_e: integer, loc_s: integer, loc_e: integer, msg_s: integer }?
local function split_location(text)
  -- 先跳过缩进和 "-->" 箭头：它们不是文件名的一部分
  -- （一开始把箭头算进了文件名，高亮范围整个偏了，实测踩过）
  local offset = #(text:match("^[ \t]*") or "")
  local rest = text:sub(offset + 1)
  local arrow = rest:match("^%-%-%>%s*")
  if arrow then
    offset = offset + #arrow
    rest = rest:sub(#arrow + 1)
  end

  local file, ln, col, e
  e, file, ln, col = select(2, rest:find("^(.-):(%d+):(%d+)"))
  if not file then
    e, file, ln = select(2, rest:find("^(.-):(%d+)"))
  end
  if not file then
    e, file, ln = select(2, rest:find("^(.-)%((%d+)%)"))
  end
  if not file or file == "" then return nil end

  -- 防误判：真文件名至少得带个点（扩展名）或斜杠，否则 "12:00:30" 这种时间戳也会被当成位置
  if not (file:match("[./\\]")) then return nil end

  -- 位置后面的收尾（": " / " - " / 空格）也算位置的一部分，高亮要盖住它
  local tail_e = select(2, rest:find("^[:%-%s]+", e + 1)) or e
  local msg_s = tail_e + 1
  while msg_s <= #rest and rest:sub(msg_s, msg_s):match("%s") do msg_s = msg_s + 1 end

  local file_s = offset + 1
  return {
    file = file,
    line = tonumber(ln),
    col = col and tonumber(col) or nil,
    msg = rest:sub(msg_s),
    file_s = file_s,
    file_e = file_s + #file - 1,
    loc_s = file_s,
    loc_e = offset + tail_e,
    msg_s = offset + msg_s,
  }
end

---有位置的行，消息该用什么颜色：warning/note 之外一律当报错（Go 的 "undefined: x" 也是报错）
---@param msg string
---@return string
local function severity_group(msg)
  local m = msg:lower()
  if m:find("warning", 1, true) then return "RunOutputWarning" end
  if m:find("note", 1, true) or m:find("hint", 1, true) then return "RunOutputInfo" end
  return "RunOutputError"
end

---把输出里的相对路径按本次运行的目录拼成绝对路径。
---（不用 quickfix 的 cwd 键：实测它对**解析**无效，只有跳转时才有意义。）
---@param path string
---@param base string?
---@return string
local function resolve_path(path, base)
  if path:match("^[/\\]") or path:match("^%a:[/\\]") then
    return vim.fs.normalize(path)
  end

  base = base or vim.fn.getcwd()
  local candidates = { base }

  -- cargo/rustc 的路径通常相对 workspace 根，而不是当前 cwd：
  -- 在 breamer/src 里跑 cargo，输出是 src/main.rs，要回到 breamer/ 去拼。
  local root = vim.fs.root(base, { "Cargo.toml", "go.mod", "package.json", ".git" })
  if root and root ~= base then
    candidates[#candidates + 1] = root
  end

  for _, dir in ipairs(candidates) do
    local candidate = vim.fs.normalize(vim.fs.joinpath(dir, path))
    if vim.fn.filereadable(candidate) == 1 then
      return candidate
    end
  end

  return vim.fs.normalize(vim.fs.joinpath(base, path))
end

---认出一行里的报错位置，并且**确认文件真的存在**才认。
---存在性检查有两个作用：① 命令行文本本身可能长得像位置（比如 `:Run printf 'a.c:1:1: x'`，
---输出缓冲区的头行就是这种），② 光看 `%f:%l:%c` 也会把行首时间戳之类的东西算进来。
---这是 quickfix 和 <CR> 跳转共用的唯一出处。
---@param text string
---@param base string?
---@return { file: string, line: integer?, col: integer?, msg: string }?
local function location_of(text, base)
  local loc = split_location(text)
  if not loc then return nil end
  loc.file = resolve_path(loc.file, base)
  if vim.fn.filereadable(loc.file) == 0 then return nil end
  return loc
end

---把一次运行的输出整理成 quickfix 条目（只有认得出位置的行走进来）
---@param lines string[]
---@param base string?
---@return table[]
local function to_qf_items(lines, base)
  local items = {}
  for _, text in ipairs(lines) do
    local loc = location_of(text, base)
    if loc then
      items[#items + 1] = {
        filename = loc.file,
        lnum = loc.line or 0,
        col = loc.col or 0,
        text = loc.msg,
        valid = 1,
      }
    end
  end
  return items
end

-- ── 缓冲区 / 窗口 ───────────────────────────────────────────────

local function close_win()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

---跳到一个报错位置；优先跳回发起 :Run 的那个窗口，输出窗口保持可见
---@param file string
---@param line integer?
---@param col integer?
local function jump_to(file, line, col)
  if vim.fn.filereadable(file) == 0 then
    vim.notify("跳不过去，文件不存在：" .. file, vim.log.levels.WARN)
    return
  end

  local target = state.src_win
  if not (target and vim.api.nvim_win_is_valid(target)) or target == state.win then
    target = nil
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= state.win then
        target = w
        break
      end
    end
  end
  if target then vim.api.nvim_set_current_win(target) end

  -- 用 bufadd/bufload 而不是 :edit：不会因为当前缓冲区有未保存改动而报 E37
  local buf = vim.fn.bufadd(file)
  vim.fn.bufload(buf)
  vim.api.nvim_win_set_buf(target or 0, buf)
  if line and line > 0 then
    pcall(vim.api.nvim_win_set_cursor, 0, { line, math.max((col or 1) - 1, 0) })
    vim.cmd("normal! zz")
  end
end

local function get_buf()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    return state.buf
  end

  local b = vim.api.nvim_create_buf(false, true) -- scratch：不列进 bufferline
  pcall(vim.api.nvim_buf_set_name, b, BUF_NAME) -- 万一重名（E95）也不影响使用
  vim.bo[b].buftype = "nofile"
  vim.bo[b].swapfile = false
  vim.bo[b].bufhidden = "hide" -- 关掉窗口后内容还在，下次 :Run 接着用同一个 buffer
  vim.bo[b].modifiable = false -- 焦点会自动落在这里，做成只读免得误改（写的时候临时打开）

  vim.keymap.set("n", "q", close_win, { buffer = b, desc = "关闭输出窗口" })
  vim.keymap.set("n", "<CR>", function()
    local loc = location_of(vim.api.nvim_get_current_line(), state.dir)
    if not loc then
      vim.notify("这一行不是「文件:行[:列]: 消息」形式，没有可跳的位置", vim.log.levels.INFO)
      return
    end
    jump_to(loc.file, loc.line, loc.col)
  end, { buffer = b, desc = "跳到本行报错的位置" })

  state.buf = b
  return b
end

---开一个底部窗口显示输出；已经开着就复用，并把**焦点移过去**（这样能直接看到流式输出）
local function open_win()
  local b = get_buf()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_set_buf(state.win, b)
    vim.api.nvim_set_current_win(state.win)
    return
  end

  local src = vim.api.nvim_get_current_win()
  local height = math.min(15, math.max(5, math.floor(vim.o.lines * 0.3)))

  vim.cmd("botright split")
  local w = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(w, b)
  vim.api.nvim_win_set_height(w, height)
  vim.wo[w].winfixheight = true -- 别被其它分屏的 :resize 挤没
  vim.wo[w].number = false
  vim.wo[w].relativenumber = false
  vim.wo[w].scrolloff = 0

  state.win = w
  state.src_win = src
  vim.api.nvim_set_current_win(w) -- 焦点给输出窗口
end

-- ── 追加输出 ───────────────────────────────────────────────────

-- 记住最近一条带位置的行是 error 还是 warning：
-- 编译器后面那些 `      |     ^` / `~~~~` 的标记行本身没有关键字，得跟着上一条的颜色走。
local last_severity = nil

---给一行加高亮（`lnum` 是 1 基行号）
---@param bufnr integer
---@param lnum integer
---@param text string
local function highlight_line(bufnr, lnum, text)
  local function hl(group, s, e)
    if e and e >= s then
      vim.api.nvim_buf_add_highlight(bufnr, NS, group, lnum - 1, s - 1, e)
    end
  end

  -- 命令头行：`$` 用暗色，像 shell 提示符
  if text:match("^%$ ") then
    return hl("RunOutputPrompt", 1, 1)
  end

  -- 状态行：退出码非 0 就用报错色
  if text:match("^── ") then
    return hl(text:find("退出码 0", 1, true) and "RunOutputInfo" or "RunOutputError", 1, #text)
  end

  local loc = split_location(text)
  if loc then
    local sev = severity_group(loc.msg)
    last_severity = sev
    hl("RunOutputFile", loc.file_s, loc.file_e) -- 文件名
    hl("RunOutputLocation", loc.file_e + 1, loc.loc_e) -- :行:列
    hl(sev, loc.msg_s, #text) -- 消息按严重程度
    -- rustc 的 "--> " 箭头
    local arrow_s, arrow_e = text:find("%-%->", 1, false)
    if arrow_s and arrow_s < loc.loc_s then hl("RunOutputPrompt", arrow_s, arrow_e) end
    return
  end

  -- 编译器的上下文标记行：`      |   ^`、`      |   ~~~~`
  local marker = text:match("^%s*|%s*([%^~]+)%s*$")
  if marker then
    local s = text:find("[%^~]+")
    if s then hl(last_severity or "RunOutputError", s, s + #marker - 1) end
    return
  end

  -- 编译器的源码上下文行（`    4 |     printf(...)` / `  |`）：
  -- 只把行号和竖线调暗，源码本身保持原样，免得整块太花
  local bar_e = select(2, text:find("^%s*%d*%s*|"))
  if bar_e then
    hl("RunOutputPrompt", 1, bar_e)
    return
  end

  -- 没有位置、但整行以 error / warning 开头的（rustc 的 "error[E0308]: ..."、
  -- "error: aborting due to ..."），整行按严重程度着色
  local kw = text:match("^%s*(%a+)[%[:%s]")
  if kw then
    kw = kw:lower()
    if kw == "error" or kw == "warning" then
      local sev = kw == "error" and "RunOutputError" or "RunOutputWarning"
      last_severity = sev
      hl(sev, 1, #text)
    end
  end
end

---追加若干行；若光标原本就停在最后一行，就跟着往下滚（像 tail -f）
---@param lines string[]
local function append(lines)
  local b = state.buf
  if not b or not vim.api.nvim_buf_is_valid(b) or #lines == 0 then return end

  local w = state.win
  local visible = w and vim.api.nvim_win_is_valid(w)
  local follow = false
  if visible then
    follow = vim.api.nvim_win_get_cursor(w)[1] >= vim.api.nvim_buf_line_count(b)
  end

  local first_new = vim.api.nvim_buf_line_count(b) + 1
  vim.bo[b].modifiable = true -- 就绪写这一下（见 get_buf 里的说明）
  vim.api.nvim_buf_set_lines(b, -1, -1, false, lines)
  vim.bo[b].modifiable = false

  for i, text in ipairs(lines) do
    highlight_line(b, first_new + i - 1, text)
  end

  if visible and follow then
    pcall(vim.api.nvim_win_set_cursor, w, { vim.api.nvim_buf_line_count(b), 0 })
  end
end

---按流处理分块：末尾半行先攒着，等下一块或 flush。
---回调 on_lines 拿到的永远是「完整的行」，并且只在主循环里被调用（可以安全地动 API）。
---@param on_lines fun(lines: string[])
local function new_stream(on_lines)
  local tail = ""
  return {
    ---@param data string[]|nil
    push = function(data)
      if not data or #data == 0 then return end
      local lines = vim.deepcopy(data)
      lines[1] = tail .. (lines[1] or "")
      tail = lines[#lines]
      lines[#lines] = nil
      if #lines > 0 then
        vim.schedule(function() on_lines(lines) end)
      end
    end,
    flush = function()
      if tail ~= "" then
        local line = tail
        tail = ""
        vim.schedule(function() on_lines({ line }) end)
      end
    end,
  }
end

-- ── 执行 ───────────────────────────────────────────────────────

---某个缓冲区所在目录；没有文件名或目录不存在时返回 nil
---@param buf integer?
---@return string?
local function dir_of(buf)
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then return nil end
  -- 只认真正的文件缓冲区：输出缓冲区自己叫 "[Run]"，名字非空但不是文件，
  -- 不排除的话会把它当成「当前文件」而算出 nvim 的工作目录（实测踩过）。
  if vim.bo[buf].buftype ~= "" then return nil end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then return nil end
  local dir = vim.fn.fnamemodify(name, ":p:h")
  return vim.fn.isdirectory(dir) == 1 and dir or nil
end

---本次该在哪个目录跑命令；Emacs 的 M-! 也是在文件目录里跑。
---@return string?
local function workdir()
  -- 当前缓冲区有文件名 → 就用它的目录
  local dir = dir_of(vim.api.nvim_get_current_buf())
  if dir then return dir end

  -- 焦点还停在输出窗口里（连着跑第二次很常见）→ 沿用上一次的源文件目录；
  -- 否则会掉回 nvim 的工作目录，输出里的相对路径就会被解析到错的地方。
  return dir_of(state.src_buf)
end

---@param cmd string
function M.run(cmd)
  if not cmd or cmd == "" then
    vim.notify("用法：:Run <命令>   例如 :Run go run main.go", vim.log.levels.WARN)
    return
  end

  -- 一次只留一个运行：上一个还在跑就先停掉，免得两次输出交叉
  if state.job then
    pcall(vim.fn.jobstop, state.job)
    state.job = nil
  end

  state.run = state.run + 1
  local run_id = state.run
  -- 记下源缓冲区：焦点被移到输出窗口后，下一次 :Run 还要靠它找到工作目录
  local cur = vim.api.nvim_get_current_buf()
  if cur ~= state.buf then state.src_buf = cur end
  state.dir = workdir()
  local b = get_buf()
  open_win()

  local all = {} -- 攒完整输出，结束后解析报错位置
  local function emit(lines)
    vim.list_extend(all, lines)
    append(lines)
  end
  local out_stream = new_stream(emit)
  local err_stream = new_stream(emit)

  local header = "$ " .. cmd
  if state.dir and state.dir ~= vim.fn.getcwd() then
    header = header .. "    (cwd: " .. state.dir .. ")"
  end
  vim.bo[b].modifiable = true
  vim.api.nvim_buf_clear_namespace(b, NS, 0, -1) -- 上一轮的高亮跟着内容一起清掉
  vim.api.nvim_buf_set_lines(b, 0, -1, false, { header, "" }) -- 空行把命令和输出隔开
  vim.bo[b].modifiable = false
  last_severity = nil

  local started = vim.uv.hrtime()
  local ok, job = pcall(vim.fn.jobstart, cmd, {
    shell = true, -- 允许管道、重定向、&& 这些写法
    cwd = state.dir,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data) out_stream.push(data) end,
    on_stderr = function(_, data) err_stream.push(data) end,
    on_exit = function(_, code)
      out_stream.flush()
      err_stream.flush()
      vim.schedule(function()
        if state.run ~= run_id then return end -- 已被新一次运行取代，收尾别插队

        -- 报错位置进 quickfix（自己解析，路径按本次运行目录拼成绝对路径）
        local items = to_qf_items(all, state.dir)
        vim.fn.setqflist({}, " ", { title = cmd, items = items })

        local tail = ""
        if #items > 0 then
          tail = string.format("，%d 处可跳转（本窗口 <CR> 跳本行，]q/[q 逐条）", #items)
        end
        local status = { "" }
        if #all == 0 then status = {} end -- 命令没打印东西时别堆两行空白
        status[#status + 1] = string.format("── 退出码 %d，用时 %.2fs%s ──",
          code, (vim.uv.hrtime() - started) / 1e9, tail)
        append(status)

        if #items > 0 then
          vim.notify(string.format("运行结束（退出码 %d）：%d 处可跳转 —— 输出窗口里按 <CR> 跳本行，]q/[q 逐条",
            code, #items), vim.log.levels.INFO)
        end
        state.job = nil
      end)
    end,
  })

  if not ok or job <= 0 then
    state.job = nil
    append({ "!! 无法启动：" .. tostring(job) })
    return
  end
  state.job = job
end

return M
