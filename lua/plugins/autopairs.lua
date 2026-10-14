-- autopairs.lua - 自动补全括号。
-- 不需要任何选项：原先那一大串（disable_filetype / ignored_next_char / map_cr / …）
-- 逐条抄的是 nvim-autopairs 内置 default，逐项比对完全一致，删掉行为不变。
-- 要改哪一项再往 opts 里加（:h nvim-autopairs 列了全部选项）。
return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
}
