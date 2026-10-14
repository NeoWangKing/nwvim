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

-- 注：原来这里有个 run_capture（收集输出后回调），:Run 重做成流式输出窗口之后没人用了，
-- 已删除。要跑命令并拿输出看 lua/config/run.lua（它需要流式，不是一次性收集）。
-- ── 文件属性操作 ──────────────────────────────────────────────
-- chmod / touch / gzip 这三个命令在 Windows 上没有：以前直接调命令，
-- 在 Windows 上会静默失败（dired 层的 M / T / Z 三个键等于坏掉）。
-- 实现收在这里，上层（config/oil-dired.lua）只负责取目标、报结果。
--
-- 三个函数都用 on_done(ok, err) 回调收尾：有的实现要等子进程，
-- 调用方不关心同步还是异步。

--- 修改权限。mode 可以是八进制（"644" / "755"）或符号模式（"+x"，仅 POSIX）。
---@param paths string[]
---@param mode string
---@param on_done fun(ok: boolean, err?: string)
function M.chmod(paths, mode, on_done)
  local numeric = tonumber(mode, 8)
  if numeric then
    -- 八进制模式走 libuv：三端一致，也不用起子进程
    for _, p in ipairs(paths) do
      local ok, err = vim.uv.fs_chmod(p, numeric)
      if not ok then
        return on_done(false, tostring(err))
      end
    end
    return on_done(true)
  end

  if M.is_windows or vim.fn.executable("chmod") == 0 then
    return on_done(false, "本平台不支持符号权限（如 +x），请用 644 / 755 这类八进制写法")
  end
  vim.fn.jobstart(vim.list_extend({ "chmod", mode }, paths), {
    on_exit = function(_, code)
      on_done(code == 0, code ~= 0 and ("chmod 退出码 " .. code) or nil)
    end,
  })
end

--- 创建空文件或刷新时间戳（dired 的 T）。纯 libuv，三端一致。
---@param paths string[]
---@param on_done fun(ok: boolean, err?: string)
function M.touch(paths, on_done)
  local now = os.time()
  for _, p in ipairs(paths) do
    if not vim.uv.fs_stat(p) then
      local fd, err = vim.uv.fs_open(p, "a", 420) -- 0644
      if not fd then
        return on_done(false, tostring(err))
      end
      vim.uv.fs_close(fd)
    end
    vim.uv.fs_utime(p, now, now)
  end
  on_done(true)
end

--- gzip -k 逐个压缩（保留原文件，dired 的 Z）。
--- Windows 环境通常没有 gzip，这种情况直接报错，别静默什么都不做。
---@param paths string[]
---@param on_done fun(ok: boolean, err?: string)
function M.compress(paths, on_done)
  if vim.fn.executable("gzip") == 0 then
    return on_done(false, "本平台没有 gzip 命令（Windows 可装 7-Zip，或用 Git Bash 自带的 gzip）")
  end

  local left, failed = #paths, 0
  for _, p in ipairs(paths) do
    vim.fn.jobstart({ "gzip", "-k", p }, {
      on_exit = function(_, code)
        if code ~= 0 then failed = failed + 1 end
        left = left - 1
        if left == 0 then
          on_done(failed == 0, failed > 0 and (failed .. " 个文件压缩失败") or nil)
        end
      end,
    })
  end
end

--- 把目录插到 PATH 最前面（已经在 PATH 里就不重复插）。
--- 用途：让「启动早期就要按名字找可执行文件」的组件（如 LSP 服务器）拿到路径，
--- 而不必等某个插件加载完再补 PATH。PATH 的分隔符三端不同，收在这里判断。
---@param dir string
---@return boolean added
function M.prepend_path(dir)
  if vim.fn.isdirectory(dir) == 0 then return false end

  local pathsep = M.is_windows and ";" or ":"
  local target = vim.fs.normalize(dir)
  for _, p in ipairs(vim.split(vim.env.PATH or "", pathsep, { plain = true })) do
    if vim.fs.normalize(p) == target then return false end
  end

  vim.env.PATH = target .. pathsep .. (vim.env.PATH or "")
  return true
end

-- 「最小可运行命令」里随平台变的片段（:SayHello 的提示用，见 config/hello.lua）：
--   bin_prefix / exe_suffix —— 编译产物怎么拼：`./main` 还是 `.\main.exe`
--     Windows 上用 `.\` 前缀，是因为 PowerShell 不认裸文件名，而 cmd 也接受 `.\main.exe`，
--     这样两边的 shell 都能直接粘贴。
--   python —— Windows 上叫 python，其余平台是 python3
--   opener —— 凭文件名打开东西的命令名（和上面 VIEWERS 的用途不同：那个是挑具体程序）
M.CMD = {
  bin_prefix = M.is_windows and ".\\" or "./",
  exe_suffix = M.is_windows and ".exe" or "",
  python = M.is_windows and "python" or "python3",
  opener = M.is_mac and "open" or (M.is_windows and "start" or "xdg-open"),
}

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
