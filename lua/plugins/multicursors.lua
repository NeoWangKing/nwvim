return {
  "smoka7/multicursors.nvim",
  enabled = false,
  event = "VeryLazy",
  dependencies = {
    "nvimtools/hydra.nvim",
  },
  opts = {
    -- 视觉效果设置
    highlight = {
      -- 光标所在匹配项的高亮组
      cursor = "Cursor",
      -- 其他匹配项的高亮组
      match = "Visual",
    },
    -- 多光标模式下的提示字符
    hint = true, -- 在状态栏显示当前模式为 "MULTI"
  },
  cmd = { 'MCstart', 'MCvisual', 'MCclear', 'MCpattern', 'MCvisualPattern', 'MCunderCursor' },
  keys = {
    -- 启动多光标选择：将光标下的单词或选中文本加入选择
    {
      mode = { "n", "v" },
      "<leader>m",
      "<cmd>MCstart<cr>",
      desc = "Start multicursor for word under cursor or visual selection",
    },
    -- 在当前文件中匹配光标下的单词（类似 Ctrl+D 逐个添加）
    {
      mode = "n",
      "<C-d>",
      "<cmd>MCunderCursor<cr>",
      desc = "Add cursor at next occurrence of word under cursor",
    },
    -- 在可视模式下，将选中的文本直接作为匹配模式
    {
      mode = "v",
      "<leader>mm",
      "<cmd>MCvisual<cr>",
      desc = "Add cursor for each line in visual selection",
    },
    -- 根据模式跳转到下一个匹配项并选中
    {
      mode = "n",
      "<leader>mn",
      "<cmd>MCpattern<cr>",
      desc = "Add cursor at next match of current pattern",
    },
    -- 清除所有多光标
    {
      mode = "n",
      "<leader>mc",
      "<cmd>MCclear<cr>",
      desc = "Clear all multicursors",
    },
  },

--   -- 长时间不活动时自动退出多光标模式
--   config = function(_, opts)
--     require("multicursors").setup(opts)
--     vim.api.nvim_create_autocmd("CursorMoved", {
--       pattern = "*",
--       callback = function()
--         if vim.g.multicursors_active then
--           vim.g.multicursors_last_activity = vim.uv.now()
--         end
--       end,
--     })
--     vim.api.nvim_create_autocmd("CursorHold", {
--       pattern = "*",
--       callback = function()
--         if vim.g.multicursors_active and vim.g.multicursors_last_activity then
--           local elapsed = vim.uv.now() - vim.g.multicursors_last_activity
--           if elapsed > 5000 then  -- 5秒无操作自动退出
--             vim.cmd("MCclear")
--           end
--         end
--       end,
--     })
--   end,
}
