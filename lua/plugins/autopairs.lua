-- lua/plugins/autopairs.lua
return {
  'windwp/nvim-autopairs',
  event = "InsertEnter",
  config = true,
  ---@type nvim-autopairs.Config
  opts = {
    -- 默认所有括号和引号均已启用配对，这里无需额外声明
    -- 开启智能跳转：如果光标右边已是右括号，则直接跳过而非再插入一个
    enable_movermap = true,
    -- 开启退格删除结对：按退格键时，自动把配对的括号一起删掉
    enable_check_bracket_line = true,
    -- 回车换行时，自动格式化中间的行（例如在花括号中间回车）
    check_ts = true,  -- 借助 Treesitter 判断是否在代码块中
  },
}
