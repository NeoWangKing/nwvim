-- lua/plugins/smear-cursor.lua

return {
  "sphamba/smear-cursor.nvim",
  enabled = false,
  event = "VeryLazy",
  opts = {
    -- 基础行为
    smear_between_buffers = true,             -- 跨缓冲区/窗口拖尾
    smear_between_neighbor_lines = true,      -- 相邻行移动拖尾
    scroll_buffer_space = true,               -- 滚动时在缓冲区空间拖尾（更自然）
    smear_insert_mode = false,                -- 插入模式关闭拖尾（避免竖线干扰）

    -- 外观
    legacy_computing_symbols_support = true,  -- 使用 Nerd Font 的平滑方块
    hide_target_hack = true,                  -- 隐藏真实光标，避免双光标

    -- 动画手感（适中拖尾长度）
    stiffness = 0.7,                          -- 刚度稍大，拖尾不会过长
    trailing_stiffness = 0.4,
    damping = 0.8,
    time_interval = 7,

    -- 距离阈值（避免微小移动触发拖尾）
    min_horizontal_distance_smear = 4,
    min_vertical_distance_smear = 4,
    distance_stop_animating = 0.5,

    -- 插入模式特殊设置
    vertical_bar_cursor_insert_mode = true,   -- 插入模式用竖线光标
    distance_stop_animating_vertical_bar = 0.5,

    -- 其他
    disable_command_mode = false,             -- 命令行模式也保留拖尾
  },
}
