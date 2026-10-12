-- autopairs.lua - 自动补全括号。
return {
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = true,
    -- opts 等价于 setup(opts)
    opts = {
      enabled = function(bufnr) return true end, -- 附加到 buffer 时是否启用
      disable_filetype = { "TelescopePrompt", "spectre_panel", "snacks_picker_input" },
      disable_in_macro = true, -- 宏录制/回放时关闭
      disable_in_visualblock = false, -- 可视块模式插入后关闭
      disable_in_replace_mode = true,
      ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
      enable_moveright = true,
      enable_afterquote = true, -- 引号后补括号
      enable_check_bracket_line = true, -- 同行检查括号
      enable_bracket_in_quote = true, -- 引号内也补括号
      enable_abbr = false, -- 触发缩写
      break_undo = true, -- 基本规则断开撤销序列
      check_ts = false,
      map_cr = true,
      map_bs = true, -- 映射 <BS> 删除成对
      map_c_h = false, -- 映射 <C-h> 删除成对
      map_c_w = false, -- 映射 <C-w> 删除成对
    },
  }
}
