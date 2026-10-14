-- gnuplot.lua - .gp 识别为 gnuplot（注释符在 config/autocmds.lua 里设置）。
vim.filetype.add {
  extension = {
    gp = "gnuplot",
  },
}
