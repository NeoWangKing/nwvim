-- autocmds.lua - 自动命令：yank 高亮、按文件类型的缩进、终端行号、gnuplot 注释符。
-- 全部 autocmd 都挂进同一个带 clear = true 的 augroup：
-- 漏进组里的 autocmd 会在每次 :source init.lua 时再注册一遍。
local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = augroup,
  callback = function()
    vim.hl.on_yank()
  end,
})

-- 缩进宽度按文件类型覆盖（默认 2 空格见 options.lua）
local function set_indent(width)
  return function()
    vim.bo.tabstop = width
    vim.bo.shiftwidth = width
    vim.bo.softtabstop = width
    vim.bo.expandtab = true
  end
end

-- C / C++ / Python / JSON：4 空格
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "c", "cpp", "python", "json" },
  callback = set_indent(4),
})

-- Markdown：3 空格
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "markdown",
  callback = set_indent(3),
})

-- 终端缓冲区不显示行号。
-- 写成 vim.wo 是为了表明「只改这个窗口」：number 是窗口局部选项，
-- 实测 vim.opt 与 vim.wo 在这里落到同一处（都改当前窗口），
-- 但 vim.opt 容易被后来的人读成「改全局默认值」，改配置时不要改回去。
vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function()
    vim.wo.number = false
    vim.wo.relativenumber = false
  end,
})

-- gnuplot 的注释符（.gp 的文件类型识别在 ftdetect/gnuplot.lua）
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "gnuplot",
  callback = function()
    vim.bo.commentstring = "# %s"
  end,
})
