-- commands.lua - 用户自定义命令：OpenPDF / OpenImage / Pdflatex / Xelatex / Lualatex / Run / SayHello。
-- 打开方式走 config/platform.lua；执行命令用 jobstart 的 cwd 和回调，不拼 POSIX shell 语法，Windows 下同样可用。

local P = require("config.platform")

-- 取当前 buffer 的 .tex 文件路径；不是 .tex 或无文件名时返回错误。
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

-- OpenPDF：按平台挑第一个已安装的轻量阅读器，避开 xdg-open 拉起的重型默认程序。
-- -skim / -preview 只在 macOS 有意义（open -a 才支持按应用名打开）。
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

-- OpenImage：按平台挑轻量看图工具；feh 这类看图工具不能开 PDF，所以列表和 PDF 分开维护。
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

-- 编译 LaTeX
local function compile_tex(filepath, compiler)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  local filename = vim.fn.fnamemodify(filepath, ":t")
  local pdf = filepath:gsub("%.tex$", ".pdf")

  print("编译: " .. filename)

  -- 用 jobstart 的 cwd 代替 `cd "dir" && ...`，Windows 下同样成立。
  -- 不能加 detach = true：detach 的进程退出时不触发 on_exit，编译结果提示会永远不出现。
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

-- Run：异步执行命令，输出实时写进独立的 scratch 窗口（见 config/run.lua）；
-- 输出里有编译器风格的行会另外解析进 quickfix。
vim.api.nvim_create_user_command("Run", function(opts)
  require("config.run").run(opts.args)
end, {
  -- 用 '*' 而不是 '+'：没有参数时走到 run.lua 里的用法提示，
  -- 比 nvim 直接抛 E471: Argument required 友好（老代码是 '+'，那段提示其实是死代码）
  nargs = '*',
  complete = 'file',
  desc = "异步执行命令，输出实时显示在独立的输出窗口里",
})

-- SayHello：空文件里写一份对应语言的 Hello, world! 模板。
-- 模板与判断逻辑在 lua/config/hello.lua，这里只做命令注册。
-- 注意 Neovim 的用户命令必须以大写字母开头，所以它不叫 :sayhello。
-- 可选参数是 filetype 名（:SayHello python），给「认不出类型」的缓冲区用。
vim.api.nvim_create_user_command("SayHello", function(opts)
  require("config.hello").say_hello(opts.args)
end, {
  nargs = "?",
  complete = function(arg_lead)
    return vim.tbl_filter(function(lang)
      return lang:find(arg_lead, 1, true) == 1
    end, require("config.hello").supported())
  end,
  desc = "在空文件里写入对应语言的 Hello, world! 模板",
})
