-- lua/config/commands.lua
-- User commands: OpenPDF, CompileLatex, Run

-- ============================================================================
-- Helper: parse options and filepath from user args
-- Returns { option = ..., filepath = ... }
-- ============================================================================
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

-- ============================================================================
-- Helper: check if we are running inside WSL
-- ============================================================================
local function is_wsl()
  local uname = vim.loop.os_uname()
  return uname and uname.release and uname.release:lower():find("microsoft") ~= nil
end

-- ============================================================================
-- OpenPDF command (macOS optimization)
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

  local viewer = "preview"
  if parsed.option == "-evince" then
    viewer = "evince"
  elseif parsed.option == "-okular" then
    viewer = "okular"
  end

  -- 对于 Preview.app，使用 open 命令
  if viewer == "preview" then
    vim.fn.jobstart({ "open", "-a", "Preview", parsed.filepath }, { detach = true })
    print("正在使用 macOS 预览程序 (Preview.app) 打开: " .. vim.fn.fnamemodify(parsed.filepath, ":t"))
  else
    -- 使用其他阅读器，检查是否存在
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
-- CompileLatex command
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

  local compiler_map = { ["-pdf"] = "pdflatex", ["-xe"] = "xelatex", ["-lua"] = "lualatex" }
  local compiler = compiler_map[parsed.option] or "pdflatex"

  if vim.fn.executable(compiler) == 0 then
    print("错误：未找到编译器 " .. compiler .. "，请安装 TeX Live 或 MiKTeX")
    return
  end

  local dir = vim.fn.fnamemodify(parsed.filepath, ":h")
  local filename = vim.fn.fnamemodify(parsed.filepath, ":t")

  if not filename:match("%.tex$") then
    print("警告：文件不是 .tex 扩展名，仍将尝试编译...")
  end

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
-- Run command: 异步执行命令并将错误信息填充到 quickfix
-- ============================================================================
vim.api.nvim_create_user_command("Run", function(opts)
  local cmd = opts.args
  if not cmd or cmd == "" then
    print("用法：:Run <命令>  例如 :Run ./build.sh")
    return
  end

  -- 创建临时文件保存输出
  local tmpfile = vim.fn.tempname()
  local full_cmd = cmd .. ' > ' .. tmpfile .. ' 2>&1'

  vim.fn.jobstart(full_cmd, {
    on_exit = function(_, exit_code)
      vim.schedule(function()
        vim.o.errorformat = "%f:%l:%c: %m,%f:%l: %m"
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
