-- bufferline.lua - 顶部标签栏。
--
-- 只写和插件默认值不同的选项：diagnostics、hover.enabled、mode、themable、separator_style、
-- tab_size、max_name_length、always_show_bufferline、color_icons 这些本来就是默认值，
-- 删掉行为不变（`diagnostics = false` 和 `hover.enabled = false` 都是默认值 ——
-- 前者"诊断不实时刷新"、后者"关闭悬停弹窗"描述的都是默认行为，别再抄回来）。
return {
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup({
        options = {
          numbers = "ordinal", -- 标签前显示序号（默认 "none"）
          sort_by = "insert_at_end", -- 默认按 id 排，这里按打开顺序
          offsets = {
            {
              filetype = "NvimTree",
              text = "File Explorer",
              highlight = "Directory",
              text_align = "left",
              separator = true,
            },
          },
        },
        highlights = {
          buffer_selected = { bold = true, italic = false },
          -- 分隔线用 P3 淡钢蓝（等于主题调色板里的 border_dim）
          separator = { fg = "#414549" },
        },
      })
    end,
  },
}
