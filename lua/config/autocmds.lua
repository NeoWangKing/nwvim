-- lua/config/commands.lua
-- 用户自定义命令：OpenPDF, CompileLatex, Run

local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- ============================================================================
-- 辅助函数
-- ============================================================================

-- 解析命令参数中的选项和文件路径
-- 返回 { option = "...", filepath = "..." } 或 nil, 错误信息
local function parse_opts(args, option_map)
  local option = option_map.default
  local filepath = nil

  if #args >= 1 then
    if option_map.prefixes[args[1]] then
      option = args[1]
      filepath = args[2]
    else
      filepath = args[1]
    end
  end

  if not filepath or filepath == "" then
    return nil, "错误：请指定文件路径"
  end

  filepath = vim.fn.expand(filepath)
  if vim.fn.filereadable(filepath) == 0 then
    return nil, "错误：文件不存在 - " .. filepath
  end

  return { option = option, filepath = filepath }, nil
end

-- 检测是否在 WSL 环境中运行（保留以备将来跨平台使用）
local function is_wsl()
  local uname = vim.loop.os_uname()
  return uname and uname.release and uname.release:lower():find("microsoft") ~= nil
end

-- ============================================================================
-- 1. OpenPDF 命令：用系统默认应用打开 PDF 文件
-- ============================================================================
vim.api.nvim_create_user_command("OpenPDF", function(opts)
  local args = vim.split(opts.args or "", "%s+", { trimempty = true })

  local opt_map = {
    prefixes = { ["-okular"] = true, ["-evince"] = true },
    default = "preview",  -- macOS 默认使用 Preview.app
  }

  local parsed, err = parse_opts(args, opt_map)
  if not parsed then
    print(err)
    print("用法：:OpenPDF (-evince/-okular) [文件路径]")
    print("      默认使用 macOS 预览程序 (Preview.app)")
    return
  end

  -- 选择阅读器
  local viewer = "preview"
  if parsed.option == "-evince" then
    viewer = "evince"
  elseif parsed.option == "-okular" then
    viewer = "okular"
  end

  -- 调用预览程序
  if viewer == "preview" then
    vim.fn.jobstart({ "open", "-a", "Preview", parsed.filepath }, { detach = true })
    print("正在使用 macOS 预览程序 (Preview.app) 打开: " .. vim.fn.fnamemodify(parsed.filepath, ":t"))
  else
    if vim.fn.executable(viewer) == 0 then
      print("错误：未找到 PDF 阅读器 " .. viewer .. "，请安装或使用其他选项")
      return
    end
    vim.fn.jobstart({ viewer, parsed.filepath }, { detach = true })
    print("正在使用 " .. viewer .. " 打开: " .. vim.fn.fnamemodify(parsed.filepath, ":t"))
  end
end, {
  nargs = "*",
  complete = function(arg_lead, cmdline, cursor_pos)
    local args = vim.split(cmdline:sub(1, cursor_pos), "%s+")
    if #args == 2 then
      if arg_lead:match("^-") then
        return { "-okular", "-evince" }
      else
        return vim.fn.getcompletion(arg_lead, "file")
      end
    elseif #args == 3 and (args[2] == "-okular" or args[2] == "-evince") then
      return vim.fn.getcompletion(arg_lead, "file")
    end
    return {}
  end,
  desc = "打开 PDF 文件 (macOS 默认用 Preview.app, 也可用 -evince/-okular)",
})

-- ============================================================================
-- 2. CompileLatex 命令：编译 LaTeX 文档
-- ============================================================================
vim.api.nvim_create_user_command("CompileLatex", function(opts)
  local args = vim.split(opts.args or "", "%s+", { trimempty = true })

  local opt_map = {
    prefixes = { ["-pdf"] = true, ["-xe"] = true, ["-lua"] = true },
    default = "-pdf",
  }

  local parsed, err = parse_opts(args, opt_map)
  if not parsed then
    print(err)
    print("用法：:CompileLatex [文件路径]")
    print("      :CompileLatex -pdf [文件路径]")
    print("      :CompileLatex -xe [文件路径]")
    print("      :CompileLatex -lua [文件路径]")
    return
  end

  -- 编译器映射
  local compiler_map = { ["-pdf"] = "pdflatex", ["-xe"] = "xelatex", ["-lua"] = "lualatex" }
  local compiler = compiler_map[parsed.option] or "pdflatex"

  -- 检查编译器是否存在
  if vim.fn.executable(compiler) == 0 then
    print("错误：未找到编译器 " .. compiler .. "，请安装 TeX Live 或 MiKTeX")
    return
  end

  local dir = vim.fn.fnamemodify(parsed.filepath, ":h")
  local filename = vim.fn.fnamemodify(parsed.filepath, ":t")

  if not filename:match("%.tex$") then
    print("警告：文件不是 .tex 扩展名，仍将尝试编译...")
  end

  -- 构建编译命令
  local cmd
  if dir ~= "" and dir ~= "." then
    cmd = string.format('cd "%s" && %s -interaction=nonstopmode "%s"', dir, compiler, filename)
  else
    cmd = string.format('%s -interaction=nonstopmode "%s"', compiler, filename)
  end

  print("正在使用 " .. compiler .. " 编译: " .. filename)
  vim.fn.jobstart(cmd, {
    detach = true,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        print("✓ 编译成功: " .. filename:gsub("%.tex$", ".pdf"))
      else
        print("✗ 编译失败 (退出码: " .. exit_code .. ")，请检查 LaTeX 日志")
      end
    end,
  })
end, {
  nargs = "*",
  complete = function(arg_lead, cmdline, cursor_pos)
    local args = vim.split(cmdline:sub(1, cursor_pos), "%s+")
    if #args == 2 then
      if arg_lead:match("^-") then
        return { "-pdf", "-xe", "-lua" }
      else
        return vim.fn.getcompletion(arg_lead, "file")
      end
    elseif #args == 3 and (args[2] == "-pdf" or args[2] == "-xe" or args[2] == "-lua") then
      return vim.fn.getcompletion(arg_lead, "file")
    end
    return {}
  end,
  desc = "编译 LaTeX 文件 (默认 pdflatex，可用 -pdf/-xe/-lua 指定编译器)",
})

-- ============================================================================
-- 3. Run 命令：异步执行外部命令，错误信息放入 quickfix 窗口
-- ============================================================================
vim.api.nvim_create_user_command("Run", function(opts)
  local cmd = opts.args
  if not cmd or cmd == "" then
    print("用法：:Run <命令>  例如 :Run ./build.sh")
    return
  end

  -- 将输出重定向到临时文件
  local tmpfile = vim.fn.tempname()
  local full_cmd = cmd .. ' > ' .. tmpfile .. ' 2>&1'

  vim.fn.jobstart(full_cmd, {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        -- 设置错误格式（适配 GCC/Clang 常见输出）
        vim.o.errorformat = "%f:%l:%c: %m,%f:%l: %m"
        -- 将临时文件内容加载到 quickfix
        vim.cmd("cfile " .. tmpfile)
        local num_errs = vim.fn.getqflist({ size = 0 }).size
        if num_errs > 0 then
          vim.cmd("copen")
          print("编译完成，发现 " .. num_errs .. " 个输出，请手动选择跳转")
        else
          print("编译成功，无错误")
        end
      end)
    end,
  })
  print("正在执行: " .. cmd)
end, {
  nargs = '+',
  complete = 'file',
  desc = "异步执行命令，错误信息存入 quickfix 列表",
})

-- C, C++, Python, JSON: 4 spaces
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "c", "cpp", "python", "json" },
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.softtabstop = 4
    vim.bo.expandtab = true
  end,
})

-- Markdown: 3 spaces
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "markdown",
  callback = function()
    vim.bo.tabstop = 3
    vim.bo.shiftwidth = 3
    vim.bo.softtabstop = 3
    vim.bo.expandtab = true
  end,
})

-- 复制时高亮被复制的文本区域
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Hightlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ })
  end,
})

vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('term-open', { clear = true }),
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})
