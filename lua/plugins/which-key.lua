-- which-key.lua - <leader> 键位提示面板。
return {
  {
    'folke/which-key.nvim',
    -- VeryLazy 足够早，也不拖启动
    event = 'VeryLazy',
    opts = {
      -- 150ms 就弹面板（默认 200ms），把按 <leader> 后的等待变成提示
      delay = 150,

      -- 键位在 keymaps.lua 等处定义，这里只给前缀分组；新开前缀时回来补组名
      spec = {
        { '<leader>b', group = '+buffer' },
        { '<leader>s', group = '+split/terminal' },
        { '<leader>t', group = '+toggle' },
        { '<leader>e', group = '+explorer' },
        { '<leader>g', group = '+git/goto' },
        { '<leader>m', group = '+misc/markdown' },
        -- 没有 <leader>c 组：重命名 / 代码操作已改用内置的 grn / gra（见 config/keymaps.lua）
        { '<leader>r', group = '+restart' },
        -- <leader>f 既是 LSP 格式化也是 telescope 的 ff/fg/fb/fh 前缀，两者都要写进来
        { '<leader>f', group = '+find/format' },
        { '<leader>x', group = '+lua' },
      },
    },
  },
}
