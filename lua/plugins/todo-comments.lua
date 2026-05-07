-- lua/plugins/todo.lua

return {
  {
    "folke/todo-comments.nvim",
    enabled = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      -- 在符号列显示图标
      signs = true,
      -- 高亮整行注释（仅关键词着色，设为 false 则只高亮关键词）
      highlight = {
        pattern = [[.*<(KEYWORDS)\s*:?\s*\zs.*]],  -- 只高亮关键词后的内容，避免空范
        comments_only = true,
        max_line_len = 300,
      },
      -- 自定义关键词
      keywords = {
        FIX  = { icon = " ", color = "error" },
        -- FIX: 
        TODO = { icon = " ", color = "info" },
        -- TODO: 
        HACK = { icon = " ", color = "warning" },
        -- HACK:
        WARN = { icon = " ", color = "warning" },
        -- WARN:
        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE" } },
        -- PERF:
        NOTE = { icon = " ", color = "hint" },
        -- NOTE:
        TEST = { icon = "⏲ ", color = "info" },
        -- TEST:

        -- 可选：更多常用标记
        QUESTION = { icon = " ", color = "info" },
        -- QUESTION:
        CLEANUP = { icon = " ", color = "info" },
        -- CLEANUP:
      },
      -- 搜索时区分大小写
      search = {
        pattern = [[\b(KEYWORDS)\b]],         -- 正则匹配完整单词
      },
    },
  },
}
