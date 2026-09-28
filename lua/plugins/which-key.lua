return {
  {
    'folke/which-key.nvim',
    -- 延迟到 UI 就绪后再加载。which-key 只是显示提示，不参与任何实际功能，
    -- 所以 VeryLazy 足够早（按第一个键之前一定已经就绪），又不会拖慢启动。
    event = 'VeryLazy',
    opts = {
      -- 默认 200ms 才弹面板，这里提前到 150ms。
      --
      -- 背景：本配置里 <space> 本身被映射成了 :（见 config/keymaps.lua 第 8 行），
      -- 而 <space>xx 又有一堆系列键位。所以按下空格后，Vim 必须等 timeoutlen
      -- （本机 500ms）才能判断你到底是「只想进命令行」还是「要按某个 <space>x」。
      -- which-key 正好把这段原本什么都看不到的等待变成有用的提示。
      delay = 150,

      -- 分组标签。
      --
      -- ⚠ 键位本身不在这里定义，而是在 config/keymaps.lua 和
      --   config/telescope/multigrep.lua 里。这里只负责给这些前缀起个
      --   「组名」，让 which-key 面板把同前缀的键位折叠成一行显示。
      --   增删键位时去改那些文件，不要改这里；但如果新开了一个前缀
      --   （比如以后加 <space>p），记得回来补一条组名。
      spec = {
        { '<leader>b', group = '+buffer' },
        { '<leader>s', group = '+split' },
        { '<leader>t', group = '+toggle' },
        { '<leader>e', group = '+explorer' },
        { '<leader>g', group = '+git/goto' },
        { '<leader>m', group = '+misc/markdown' },
        { '<leader>c', group = '+code (LSP)' },
        { '<leader>r', group = '+rename/restart' },
        { '<leader>f', group = '+format' },
        { '<leader>x', group = '+lua' },
      },
    },
  },
}
