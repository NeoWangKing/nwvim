return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  opts = {
    enabled = true,
    scope = {
      enabled = true,
      show_start = false,
      show_end = false,
    },
    indent = {
      char = "│",
    },
    -- 在这些文件类型中不显示缩进线
    exclude = {
      filetypes = {
        "dashboard",
        "lazy",
        "help",
        "man",
        "checkhealth",
        "qf",
      },
    },
  },
}
