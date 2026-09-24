-- ═══════════════════════════════════════════════════════════════════════
--  lua/config/platform.lua — 跨平台适配层
--
--  这套配置要在 macOS / Linux / Windows 三端共用，凡是「命令名、调用方式、
--  路径规则」随平台变化的地方，都统一收敛到这里，避免散落在各处写
--  has("mac") 判断。
--
--  用法：
--    local P = require("config.platform")
--    P.is_mac / P.is_linux / P.is_windows
--    P.open_path(path)          -- 用系统默认程序打开文件/目录/URL
--    P.open_with_app(app, path) -- 用指定程序打开（仅 macOS 有意义，其余平台自动退化为默认程序）
--    P.clipboard_available()    -- 当前平台能否与系统剪贴板互通
--    P.pathsep                  -- 路径分隔符
-- ═══════════════════════════════════════════════════════════════════════

local M = {}

-- ── 平台识别 ───────────────────────────────────────────────────────────
-- 优先用 uv.os_uname()（比 vim.fn.has 更可靠，尤其在 WSL / MSYS 环境下）
local sysname = (vim.uv or vim.loop).os_uname().sysname or ""

M.is_windows = sysname:match("Windows") ~= nil or vim.fn.has("win32") == 1
M.is_mac     = sysname == "Darwin"
M.is_linux   = sysname == "Linux" and not M.is_windows

-- WSL 里 sysname 也是 Linux，但「打开文件」需要走 Windows 侧
M.is_wsl = M.is_linux
  and (vim.env.WSL_DISTRO_NAME ~= nil or vim.env.WSL_INTEROP ~= nil)

M.pathsep = M.is_windows and "\\" or "/"

-- ── 打开文件 / 目录 / URL ──────────────────────────────────────────────
-- vim.ui.open() 是 Neovim 0.10+ 内置的跨平台实现：
--   macOS → open        Linux → xdg-open        Windows → start
-- 返回一个 vim.SystemObj，失败返回 nil，所以失败时要自己兜底提示。
---@param path string
---@return boolean ok
function M.open_path(path)
  local ok, res = pcall(vim.ui.open, path)
  if ok and res ~= nil then return true end
  -- 退化方案：手动挑一个可用的打开器
  local cmd
  if M.is_mac then
    cmd = { "open", path }
  elseif M.is_windows then
    cmd = { "cmd.exe", "/c", "start", "", path }
  elseif M.is_wsl then
    -- WSL 下 xdg-open 常常没配好，用 Windows 的 explorer.exe 更可靠
    cmd = { "explorer.exe", vim.fn.fnamemodify(path, ":p"):gsub("/", "\\") }
  else
    cmd = { "xdg-open", path }
  end
  if vim.fn.executable(cmd[1]) == 0 then return false end
  return vim.fn.jobstart(cmd, { detach = true }) > 0
end

-- 用指定程序打开。只有 macOS 的 `open -a` 支持「按应用名打开」，
-- 其余平台没有等价能力，直接退化为系统默认程序。
---@param app string      应用名，如 "Skim" / "Preview"
---@param path string
---@return boolean ok
function M.open_with_app(app, path)
  if M.is_mac and vim.fn.executable("open") == 1 then
    return vim.fn.jobstart({ "open", "-a", app, path }, { detach = true }) > 0
  end
  return M.open_path(path)
end

-- macOS 上「按应用名打开」才有意义，用于决定是否提供 -skim / -preview 之类的选项
function M.supports_app_named_open()
  return M.is_mac and vim.fn.executable("open") == 1
end

-- ── 剪贴板 ─────────────────────────────────────────────────────────────
-- unnamedplus 的实际依赖：
--   macOS   → pbcopy / pbpaste   （系统自带，Neovim 原生支持）
--   Windows → clip.exe           （系统自带，Neovim 原生支持）
--   Linux   → 需要 xclip / xsel / wl-copy 三者之一，装了才有
-- 没有可用工具却启用 unnamedplus，yank 会报错或静默失效，所以必须先探测。
---@return boolean
function M.clipboard_available()
  if M.is_mac or M.is_windows then return true end
  for _, tool in ipairs({ "wl-copy", "xclip", "xsel" }) do
    if vim.fn.executable(tool) == 1 then return true end
  end
  return false
end

-- ── 可执行文件查找（跨平台，带 Windows 扩展名）────────────────────────
---@param name string
---@return boolean
function M.has_exe(name)
  return vim.fn.executable(name) == 1
end

-- ── 异步执行命令并收集输出（不依赖 shell 重定向，跨平台安全）──────────
-- 原来的写法是拼 `cmd > tmpfile 2>&1`，这在 PowerShell / cmd.exe 下语法并不通用。
-- 改为走 jobstart 的回调收集，然后把结果交给上层处理。
---@param cmd string            交给 shell 解析的命令串
---@param opts table|nil        { cwd = string, on_exit = fun(code, lines) }
---@return number job_id
function M.run_capture(cmd, opts)
  opts = opts or {}
  local lines = {}
  local function push(data)
    if not data then return end
    -- jobstart 的分块以 "\n" 分隔，末尾可能是空串
    for _, l in ipairs(data) do
      if l ~= "" then lines[#lines + 1] = l end
    end
  end
  return vim.fn.jobstart(cmd, {
    shell = true,                -- 允许命令里带管道、参数、引号
    cwd = opts.cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data) push(data) end,
    on_stderr = function(_, data) push(data) end,
    on_exit = function(_, code)
      if opts.on_exit then opts.on_exit(code, lines) end
    end,
  })
end

-- ── 查看器偏好 ─────────────────────────────────────────────────────────
-- 按优先级排列，取第一个「已安装」的。
--
-- 图片和 PDF 是两类不同的工具，不要混：
--   feh / nsxiv / sxiv / imv  只用于看图，不能开 PDF
--   zathura / mupdf / llpp    是 PDF 阅读器（部分也能看图）
-- 这里刻意优先轻量命令行查看器，而不是 xdg-open —— 后者会拉起桌面环境
-- 注册的重型程序（GNOME 上通常是 evince，KDE 上是 okular）。
--
-- 想改偏好：把想用的工具挪到数组最前面，或在本地直接覆盖，例如
--   require("config.platform").VIEWERS.pdf.linux = { { kind = "exe", name = "mupdf" } }
M.VIEWERS = {
  pdf = {
    mac     = { { kind = "app", name = "Skim" }, { kind = "app", name = "Preview" } },
    linux   = {
      { kind = "exe", name = "evince" },   -- 你在 Linux 上用的就是这个，放最前
      { kind = "exe", name = "zathura" },
      { kind = "exe", name = "mupdf" },
      { kind = "exe", name = "llpp" },
      { kind = "exe", name = "okular" },
      { kind = "exe", name = "xpdf" },
    },
    windows = {
      { kind = "exe", name = "SumatraPDF.exe" },
      { kind = "exe", name = "SumatraPDF" },
      { kind = "exe", name = "msedge.exe" },
    },
  },
  image = {
    mac     = { { kind = "app", name = "Preview" } },
    linux   = {
      { kind = "exe", name = "feh" },
      { kind = "exe", name = "nsxiv" },
      { kind = "exe", name = "sxiv" },
      { kind = "exe", name = "imv" },
      { kind = "exe", name = "qiv" },
      { kind = "exe", name = "eog" },
    },
    windows = {
      { kind = "exe", name = "nomacs.exe" },
      { kind = "exe", name = "mspaint.exe" },
    },
  },
}

-- 当前平台标识
function M.platform_key()
  if M.is_mac then return "mac" end
  if M.is_windows then return "windows" end
  return "linux"
end

-- 取当前平台第一个可用的查看器；都没有则返回 nil（上层退化为系统默认程序）
---@param kind "pdf"|"image"
---@return table|nil  { kind = "app"|"exe", name = string }
function M.pick_viewer(kind)
  local list = (M.VIEWERS[kind] or {})[M.platform_key()] or {}
  for _, v in ipairs(list) do
    if v.kind == "app" then
      -- macOS 的「按应用名打开」需要 app bundle 真实存在
      if M.is_mac and vim.fn.isdirectory("/Applications/" .. v.name .. ".app") == 1 then
        return v
      end
    elseif vim.fn.executable(v.name) == 1 then
      return v
    end
  end
  return nil
end

-- 用指定查看器打开文件；viewer 为 nil 时退化为系统默认程序
---@param viewer table|nil
---@param path string
---@return boolean ok
function M.open_with_viewer(viewer, path)
  if not viewer then return M.open_path(path) end
  if viewer.kind == "app" then
    return M.open_with_app(viewer.name, path)
  end
  if vim.fn.executable(viewer.name) == 0 then
    return M.open_path(path)
  end
  return vim.fn.jobstart({ viewer.name, path }, { detach = true }) > 0
end

-- ── Git 拉取协议（决定 lazy.nvim 装插件走 SSH 还是 HTTPS）──────────────
-- 判定顺序（优先级从高到低）：
--   1. vim.g.git_protocol 显式指定 "ssh" / "https" / "ssh443"
--   2. ~/.ssh 下有私钥，且实测能通过 GitHub 认证        → SSH（22 端口）
--   3. 22 不通、但 ssh.github.com:443 通                → SSH over 443
--   4. 其余                                             → HTTPS（不设 url_format）
--
-- 为什么不能只看「有没有密钥文件」：
--   a) 有私钥 ≠ GitHub 认这把钥匙（可能这把钥匙是给别的服务用的）；
--   b) 22 端口在国内常被封，那种情况下 SSH 克隆会直接失败，
--      结果是一个插件都装不上，而且报错很难看出是协议问题。
-- 所以这里实测一次，并把结论缓存起来，之后启动不再探测。
--
-- 缓存位置：stdpath("state")/gitproto
-- 想重新探测（例如换了网络、刚配好密钥）：删掉那个文件即可。
-- 想强制协议：在 init.lua 里写 vim.g.git_protocol = "ssh443"

-- GitHub 的 SSH 认证测试
local function ssh_github_ok(host, port)
  local args = {
    "ssh", "-T",
    "-o", "StrictHostKeyChecking=accept-new",
    "-o", "BatchMode=yes",     -- 禁止一切交互，免得卡在密码 / 指纹确认
    "-o", "ConnectTimeout=5",
  }
  if port then
    args[#args + 1] = "-p"
    args[#args + 1] = tostring(port)
  end
  args[#args + 1] = "git@" .. host

  local out = vim.fn.system(args) or ""
  -- ⚠ 关键：`ssh -T git@github.com` 认证成功时退出码也是 1
  --   （因为 GitHub 不提供 shell），所以只能看输出文本，
  --   不能用 vim.v.shell_error 判断，否则永远得到「失败」。
  return out:match("successfully authenticated") ~= nil
end

local function has_ssh_private_key()
  for _, name in ipairs({ "id_ed25519", "id_ecdsa", "id_rsa" }) do
    local p = vim.fn.expand("~/.ssh/" .. name)
    if vim.fn.filereadable(p) == 1 and vim.fn.getfsize(p) > 0 then
      return true
    end
  end
  return false
end

local GITPROTO_CACHE = vim.fn.stdpath("state") .. "/gitproto"

--- 探测当前环境适合用哪种协议
---@return "ssh"|"ssh443"|"https"
function M.detect_git_protocol()
  if not has_ssh_private_key() then return "https" end

  local cached = ""
  if vim.fn.filereadable(GITPROTO_CACHE) == 1 then
    cached = (vim.fn.readfile(GITPROTO_CACHE)[1] or "")
    if cached == "ssh" or cached == "ssh443" or cached == "https" then
      return cached
    end
  end

  local proto = "https"
  if ssh_github_ok("github.com") then
    proto = "ssh"
  elseif ssh_github_ok("ssh.github.com", 443) then
    proto = "ssh443"
  end
  pcall(vim.fn.writefile, { proto }, GITPROTO_CACHE)
  return proto
end

--- 给 lazy.nvim 用的 git.url_format
--- 返回 nil 表示保持默认（HTTPS），不要传空表进去
---@return string|nil
function M.git_url_format()
  local forced = vim.g.git_protocol
  if forced == "https" then return nil end
  if forced == "ssh" then return "git@github.com:%s.git" end
  if forced == "ssh443" then return "ssh://git@github.com:443/%s.git" end

  local proto = M.detect_git_protocol()
  if proto == "ssh" then return "git@github.com:%s.git" end
  if proto == "ssh443" then return "ssh://git@github.com:443/%s.git" end
  return nil
end

-- ── 英文词典（写文章时的单词补全）──────────────────────────────────────
-- 供 blink-cmp-dictionary 使用。词典格式很简单：每行一个小写单词。
--
-- 这里只认「随仓库走的词典目录」：~/.config/nvim/dictionary/
-- 该目录里的所有 .txt 都会被读取（详见 dictionary/README.md）。
--
-- 为什么不顺便用系统词典（/usr/share/dict/words 等）：
--   1) 三端情况差异大 —— macOS 自带，Linux 看发行版，Windows 根本没有；
--   2) 更关键的是插件把多个词典文件「拼接而不去重」，
--      系统词表和仓库里的 english-words.txt 内容高度重叠，
--      同时启用会在候选里出现大量重复项。
--   仓库里带一份，反而在三端行为完全一致。
--
-- 想改路径：在 init.lua 里设 vim.g.dictionary_dir = "/your/path"
---@return string[] 词典目录列表（不存在则为空表，上层据此决定是否启用词典源）
function M.dictionary_dirs()
  local dir = vim.g.dictionary_dir or (vim.fn.stdpath("config") .. "/dictionary")
  return vim.fn.isdirectory(dir) == 1 and { dir } or {}
end

return M
