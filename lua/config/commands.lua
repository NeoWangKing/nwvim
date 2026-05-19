-- lua/config/commands.lua
-- 用户自定义命令：OpenPDF, pdflatex, xelatex, lualatex, Run

-- 解析命令参数中的选项和文件路径（用于 OpenPDF）
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

-- ---------- 打开 PDF（支持自动选择阅读器）----------
vim.api.nvim_create_user_command("OpenPDF", function(opts)
  local args = vim.split(opts.args or "", "%s+", { trimempty = true })

  -- 解析是否指定了阅读器选项
  local viewer = nil
  local filepath = nil
  if #args >= 1 then
    if args[1] == "-skim" then
      viewer = "Skim"
      filepath = args[2]
    elseif args[1] == "-preview" then
      viewer = "Preview"
      filepath = args[2]
    else
      filepath = args[1]
    end
  end

  if not(viewer) then
    viewer = "Skim"
  end

  -- 如果未提供文件，自动匹配当前 .tex 对应的 PDF
  if not filepath or filepath == "" then
    local texfile, err = get_current_tex_file()
    if not texfile then
      print(err)
      print("用法：:OpenPDF [-skim|-preview] [文件路径]")
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

  -- 调用阅读器
  if viewer == "Skim" then
      vim.fn.jobstart({ "open", "-a", "skim", filepath }, { detach = true })
  elseif viewer == "Preview" then
    vim.fn.jobstart({ "open", "-a", "Preview", filepath }, { detach = true })
  else
    if vim.fn.executable(viewer) == 0 then
      print("错误：未找到 PDF 阅读器 " .. viewer)
      return
    end
    vim.fn.jobstart({ viewer, filepath }, { detach = true })
  end

  print("使用 " .. viewer .. " 打开: " .. vim.fn.fnamemodify(filepath, ":t"))
end, {
  nargs = "?",
  complete = function(arg_lead, cmdline, cursor_pos)
    local args = vim.split(cmdline:sub(1, cursor_pos), "%s+")
    if #args == 2 then
      if arg_lead:match("^-") then
        return { "-skim", "-preview" }
      else
        return vim.fn.getcompletion(arg_lead, "file")
      end
    elseif #args == 3 and (args[2] == "-skim" or args[2] == "-preview") then
      return vim.fn.getcompletion(arg_lead, "file")
    end
    return {}
  end,
  desc = "打开 PDF 文件（默认 Skim，可选用 -preview 等）",
})

-- ---------- 编译 LaTeX（编译后自动刷新 Skim）----------
local function compile_tex(filepath, compiler)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  local filename = vim.fn.fnamemodify(filepath, ":t")

  local cmd
  if dir ~= "" and dir ~= "." then
    cmd = string.format('cd "%s" && %s -interaction=nonstopmode "%s"', dir, compiler, filename)
  else
    cmd = string.format('%s -interaction=nonstopmode "%s"', compiler, filename)
  end

  print("编译: " .. filename)
  vim.fn.jobstart(cmd, {
    detach = true,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        local pdf = filepath:gsub("%.tex$", ".pdf")
        print("✓ 编译成功: " .. pdf)
        -- Skim 会自动刷新，无需额外操作；
        -- 如果希望用 Preview 且刷新，可尝试 AppleScript，但体验不如 Skim
      else
        print("✗ 编译失败 (退出码: " .. exit_code .. ")，请检查日志")
      end
    end,
  })
end

-- 创建编译命令的工厂函数（nargs 改为 "?" 以支持可选参数）
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
      print("错误：未找到 " .. compiler)
      return
    end

    -- 标记自动编译
    vim.b.latex_auto_compile = true
    vim.b.latex_compiler = compiler

    compile_tex(filepath, compiler)
  end, {
    nargs = "?",
    complete = "file",
    desc = "使用 " .. compiler .. " 编译 LaTeX" ..
           "（首次使用后保存时自动编译）",
  })
end

create_latex_command("Pdflatex", "pdflatex")
create_latex_command("Xelatex", "xelatex")
create_latex_command("Lualatex", "lualatex")

-- 保存时自动编译（保持原有逻辑）
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

-- Run ：异步执行外部命令，错误信息放入 quickfix 窗口
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
