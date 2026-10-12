-- platform.lua - 跨平台适配层：命令名、调用方式、路径差异都收在这里。
-- macOS / Linux / Windows 三端共用，插件文件里不要再写 has("mac") 判断。

local M = {}

-- 平台识别。优先 uv.os_uname()，WSL/MSYS 下比 has() 可靠。
local sysname = (vim.uv or vim.loop).os_uname().sysname or ""

M.is_windows = sysname:match("Windows") ~= nil or vim.fn.has("win32") == 1
M.is_mac     = sysname == "Darwin"
M.is_linux   = sysname == "Linux" and not M.is_windows

-- WSL 里 sysname 也是 Linux，但「打开文件」需要走 Windows 侧
M.is_wsl = M.is_linux
  and (vim.env.WSL_DISTRO_NAME ~= nil or vim.env.WSL_INTEROP ~= nil)

M.pathsep = M.is_windows and "\\" or "/"

-- 打开文件/目录/URL：优先 vim.ui.open，失败时按平台退化到 open/xdg-open/start。
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

-- 按应用名打开只有 macOS 的 open -a 支持，其余平台退化为默认程序。
---@param app string
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

-- 剪贴板：macOS/Windows 系统自带；Linux 需要 xclip/xsel/wl-copy 之一，缺工具启用会报错或静默失效。
---@return boolean
function M.clipboard_available()
  if M.is_mac or M.is_windows then return true end
  for _, tool in ipairs({ "wl-copy", "xclip", "xsel" }) do
    if vim.fn.executable(tool) == 1 then return true end
  end
  return false
end

-- 可执行文件查找（跨平台）
---@param name string
---@return boolean
function M.has_exe(name)
  return vim.fn.executable(name) == 1
end

-- 异步执行命令并收集输出；`cmd > file 2>&1` 的重定向写法在 Windows 下不通用，所以走 jobstart 回调。
---@param cmd string            交给 shell 解析的命令串
---@param opts table|nil
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

-- 查看器按列表顺序取第一个已安装的轻量工具；图片和 PDF 分开维护，看图工具不能开 PDF。
-- 想改偏好：把工具挪到列表最前，或覆盖 VIEWERS.pdf.linux 这类字段。
M.VIEWERS = {
  pdf = {
    mac     = { { kind = "app", name = "Skim" }, { kind = "app", name = "Preview" } },
    linux   = {
      { kind = "exe", name = "evince" },   -- 平时用这个，放最前
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

-- lazy.nvim 装插件走 SSH 还是 HTTPS：先看 vim.g.git_protocol，再看能否通过 GitHub SSH 认证，最后试 443 端口。
-- 只看有没有私钥文件不可靠（钥匙可能不被 GitHub 认、22 端口可能被封），所以实测一次，结果缓存在 gitproto。
-- 重新探测就删 stdpath("state")/gitproto；强制协议在 init.lua 设 vim.g.git_protocol。

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
  -- ssh -T git@github.com 认证成功时退出码也是 1（GitHub 不提供 shell），只能看输出文本判断。
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

-- 探测当前环境适合用哪种协议
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

-- 给 lazy.nvim 用；返回 nil 表示保持默认 HTTPS。
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

-- 英文词典目录：blink-cmp-dictionary 会读取目录下所有 .txt，每行一个单词。
-- 不用系统词典：三端差异大，且插件多文件拼接不去重，和仓库词表重叠会产生大量重复候选。
-- 想改路径：在 init.lua 设 vim.g.dictionary_dir。
---@return string[]
function M.dictionary_dirs()
  local dir = vim.g.dictionary_dir or (vim.fn.stdpath("config") .. "/dictionary")
  return vim.fn.isdirectory(dir) == 1 and { dir } or {}
end

return M
