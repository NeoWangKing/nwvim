-- lua/config/commands.lua
-- 用户自定义命令：OpenPDF, Pdflatex, Xelatex, Lualatex, Run
--
-- 【跨平台说明】
-- · 打开 PDF：走 config/platform.lua。macOS 支持「按应用名打开」（Skim / Preview），
--   Linux / Windows 没有等价能力，自动退化为系统默认程序（xdg-open / start）。
-- · 执行命令：不再拼接 `cd "dir" && ...` 和 `> file 2>&1`，这类 POSIX shell 语法
--   在 Windows 的 cmd.exe / PowerShell 下并不通用。改用 jobstart 的 cwd 选项
--   与 stdout/stderr 回调，三端行为一致。

local P = require("config.platform")

-- 获取当前 buffer 的 .tex 文件路径（如果可用）
-- 返回完整路径，如果不符合要求则返回 nil, 错误信息
local function get_current_tex_file()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then
    return nil, "错误：当前 buffer 没有关联文件"
  end
  if not bufname:match("%.tex$") then
    return nil, "错误：当前文件不是 .tex 文件（" .. vim.fn.fnamemodify(bufname, ":t") .. "）"
  end
  return bufname, nil
end

-- ---------- 打开 PDF ----------
-- 默认阅读器由 config/platform.lua 的 pick_viewer("pdf") 按平台自动挑选：
--   macOS   → Skim（装了就用，支持自动刷新）→ Preview
--   Linux   → zathura → mupdf → llpp → evince → okular → xpdf
--   Windows → SumatraPDF → Edge
-- 一个都没找到时，退化为系统默认程序（open / xdg-open / start）。
--
-- 之所以不直接用 xdg-open：它会拉起桌面环境注册的默认程序，
-- GNOME 上通常是 evince、KDE 上是 okular，都是重型 GUI，启动慢。
-- 这里优先轻量查看器，正是为了避开这一点。
--
-- 显式指定阅读器的选项只在 macOS 上有意义（`open -a` 才支持按应用名打开）：
local VIEWERS = {}
if P.supports_app_named_open() then
  VIEWERS = {
    ["-skim"]    = { kind = "app", value = "Skim",    label = "Skim" },
    ["-preview"] = { kind = "app", value = "Preview", label = "Preview" },
  }
end

-- 每次调用时重新探测，这样新装了查看器不用重启 nvim
local function default_pdf_viewer()
  local v = P.pick_viewer("pdf")
  if v then return { kind = v.kind, value = v.name, label = v.name } end
  return { kind = "default", label = "系统默认程序" }
end

local function viewer_usage()
  local opts = {}
  for k, _ in pairs(VIEWERS) do opts[#opts + 1] = k end
  table.sort(opts)
  local s = #opts > 0 and ("[" .. table.concat(opts, "|") .. "] ") or ""
  return "用法：:OpenPDF " .. s .. "[文件路径]"
end

vim.api.nvim_create_user_command("OpenPDF", function(opts)
  local args = vim.split(opts.args or "", "%s+", { trimempty = true })

  local viewer = nil
  local filepath = nil
  if #args >= 1 then
    if VIEWERS[args[1]] then
      viewer = VIEWERS[args[1]]
      filepath = args[2]
    else
      filepath = args[1]
    end
  end

  if not viewer then viewer = default_pdf_viewer() end

  -- 如果未提供文件，自动匹配当前 .tex 对应的 PDF
  if not filepath or filepath == "" then
    local texfile, err = get_current_tex_file()
    if not texfile then
      print(err)
      print(viewer_usage())
      return
    end
    filepath = texfile:gsub("%.tex$", ".pdf")
  else
    filepath = vim.fn.expand(filepath)
  end

  if vim.fn.filereadable(filepath) == 0 then
    print("错误：PDF 文件不存在 - " .. filepath)
    return
  end

  local ok
  if viewer.kind == "app" then
    ok = P.open_with_app(viewer.value, filepath)
  elseif viewer.kind == "exe" then
    ok = P.open_with_viewer({ kind = "exe", name = viewer.value }, filepath)
  else
    ok = P.open_path(filepath)
  end

  if ok then
    print("使用 " .. viewer.label .. " 打开: " .. vim.fn.fnamemodify(filepath, ":t"))
  else
    print("错误：打开失败（未找到可用的打开程序）")
  end
end, {
  nargs = "?",
  complete = function(arg_lead, cmdline, cursor_pos)
    local args = vim.split(cmdline:sub(1, cursor_pos), "%s+")
    if #args == 2 then
      if arg_lead:match("^-") then
        local out = {}
        for k, _ in pairs(VIEWERS) do out[#out + 1] = k end
        table.sort(out)
        return out
      else
        return vim.fn.getcompletion(arg_lead, "file")
      end
    elseif #args == 3 and VIEWERS[args[2]] then
      return vim.fn.getcompletion(arg_lead, "file")
    end
    return {}
  end,
  desc = "打开 PDF 文件（按平台自动选择轻量阅读器）",
})

-- ---------- 打开图片 ----------
-- 与 PDF 同理，按平台挑轻量看图工具：
--   macOS   → Preview
--   Linux   → feh → nsxiv → sxiv → imv → qiv → eog
--   Windows → nomacs → 画图
-- 注意 feh 只能看图、不能开 PDF，所以这里的列表和上面的 pdf 是分开维护的。
local IMAGE_EXTS = {
  png = true, jpg = true, jpeg = true, gif = true, bmp = true, webp = true,
  tif = true, tiff = true, svg = true, ico = true, avif = true, heic = true,
  ppm = true, pgm = true, pbm = true,
}

vim.api.nvim_create_user_command("OpenImage", function(opts)
  local filepath = opts.args
  if not filepath or filepath == "" then
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname == "" then
      print("用法：:OpenImage <文件路径>（或先在图片 buffer 里执行）")
      return
    end
    filepath = bufname
  end
  filepath = vim.fn.expand(filepath)

  if vim.fn.filereadable(filepath) == 0 then
    print("错误：文件不存在 - " .. filepath)
    return
  end

  local ext = vim.fn.fnamemodify(filepath, ":e"):lower()
  if not IMAGE_EXTS[ext] then
    print("提示：." .. ext .. " 不在常见图片扩展名内，仍尝试打开")
  end

  local v = P.pick_viewer("image")
  if P.open_with_viewer(v, filepath) then
    print("使用 " .. (v and v.name or "系统默认程序") .. " 打开: " .. vim.fn.fnamemodify(filepath, ":t"))
  else
    print("错误：打开失败（未找到可用的看图程序）")
  end
end, {
  nargs = "?",
  complete = "file",
  desc = "用平台上的轻量看图程序打开图片（Linux: feh/nsxiv，macOS: Preview）",
})

-- ---------- 编译 LaTeX ----------
local function compile_tex(filepath, compiler)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  local filename = vim.fn.fnamemodify(filepath, ":t")
  local pdf = filepath:gsub("%.tex$", ".pdf")

  print("编译: " .. filename)

  -- 用 jobstart 的 cwd 代替 `cd "dir" && ...`，Windows 下同样成立。
  --
  -- ⚠ 这里不能加 detach = true：一旦 detach，on_exit 就永远不会被调用
  --   （Neovim 文档明确说明 detach 的进程退出时不触发回调）。
  --   原写法正是踩了这个坑，导致「编译成功 / 失败」的提示从来没出现过。
  local lines = {}
  local function push(data)
    if not data then return end
    for _, l in ipairs(data) do
      if l ~= "" then lines[#lines + 1] = l end
    end
  end

  vim.fn.jobstart({ compiler, "-interaction=nonstopmode", filename }, {
    cwd = (dir ~= "" and dir ~= ".") and dir or nil,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data) push(data) end,
    on_stderr = function(_, data) push(data) end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          print("✓ 编译成功: " .. vim.fn.fnamemodify(pdf, ":t"))
        else
          local log = filepath:gsub("%.tex$", ".log")
          print(string.format("✗ 编译失败（退出码 %d），日志: %s",
            exit_code, vim.fn.fnamemodify(log, ":t")))
          -- 打印末尾几行，多数情况下错误信息就在最后
          local tail = {}
          for i = math.max(1, #lines - 5), #lines do tail[#tail + 1] = lines[i] end
          if #tail > 0 then print(table.concat(tail, "\n")) end
        end
      end)
    end,
  })
end

-- 创建编译命令的工厂函数
local function create_latex_command(name, compiler)
  vim.api.nvim_create_user_command(name, function(opts)
    local filepath = opts.args
    if not filepath or filepath == "" then
      local texfile, err = get_current_tex_file()
      if not texfile then
        print(err)
        print("用法：:" .. name .. " [文件路径]")
        return
      end
      filepath = texfile
    else
      filepath = vim.fn.expand(filepath)
    end

    if vim.fn.filereadable(filepath) == 0 then
      print("错误：文件不存在 - " .. filepath)
      return
    end
    if vim.fn.executable(compiler) == 0 then
      print("错误：未找到 " .. compiler .. "。安装方式：\n" ..
        "  macOS   brew install --cask mactex\n" ..
        "  Linux   apt install texlive-full  /  dnf install texlive-scheme-full\n" ..
        "  Windows 安装 MiKTeX 或 TeX Live")
      return
    end

    vim.b.latex_auto_compile = true
    vim.b.latex_compiler = compiler

    compile_tex(filepath, compiler)
  end, {
    nargs = "?",
    complete = "file",
    desc = "使用 " .. compiler .. " 编译 LaTeX（首次使用后保存时自动编译）",
  })
end

create_latex_command("Pdflatex", "pdflatex")
create_latex_command("Xelatex", "xelatex")
create_latex_command("Lualatex", "lualatex")

-- 保存时自动编译
local latex_augroup = vim.api.nvim_create_augroup("LatexAutoCompile", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = latex_augroup,
  pattern = "*.tex",
  callback = function(args)
    local buf = args.buf
    if vim.b[buf].latex_auto_compile then
      local compiler = vim.b[buf].latex_compiler or "pdflatex"
      if vim.fn.executable(compiler) == 1 then
        compile_tex(vim.api.nvim_buf_get_name(buf), compiler)
      end
    end
  end,
})

-- ---------- Run：异步执行外部命令，输出放入 quickfix ----------
-- 原来用 `cmd > tmpfile 2>&1` 依赖 shell 重定向，在 PowerShell / cmd.exe 下
-- 语法并不一致；改为用 jobstart 回调收集输出，再写文件交给 quickfix。
vim.api.nvim_create_user_command("Run", function(opts)
  local cmd = opts.args
  if not cmd or cmd == "" then
    print("用法：:Run <命令>  例如 :Run ./build.sh")
    return
  end

  local tmpfile = vim.fn.tempname()
  print("正在执行: " .. cmd)

  P.run_capture(cmd, {
    on_exit = function(exit_code, lines)
      vim.schedule(function()
        vim.fn.writefile(lines, tmpfile)
        -- 兼容 GCC / Clang / MSVC 的常见输出格式
        vim.o.errorformat = "%f:%l:%c: %m,%f:%l: %m,%f(%l): error %m,%f(%l): warning %m"
        vim.cmd("cfile " .. vim.fn.fnameescape(tmpfile))
        local num = vim.fn.getqflist({ size = 0 }).size
        if num > 0 then
          vim.cmd("copen")
          print(string.format("执行结束（退出码 %d），quickfix 中有 %d 条输出", exit_code, num))
        else
          print(string.format("执行成功（退出码 %d），无输出", exit_code))
        end
      end)
    end,
  })
end, {
  nargs = '+',
  complete = 'file',
  desc = "异步执行命令，输出存入 quickfix 列表",
})
