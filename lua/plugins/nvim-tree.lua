-- nvim-tree.lua - 文件树。
--
-- 懒加载：按 <leader>e（键位在 config/keymaps.lua）或 :NvimTreeToggle 时才加载。
-- 关掉 netrw 的两个开关挪到了 init.lua —— 那里才是「能保证生效」的时机，
-- 而且文件树变懒之后，原来写在 config 里的那两行就不再保证会被执行了。
--
-- 只写和插件默认值不同的选项：默认值抄一遍只会让后来的人以为这里改过东西。
return {
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    -- 两个触发都给上：
    --   cmd        —— 立刻要用（<leader>e）和无界面脚本里也能起来
    --   VeryLazy   —— 它还有一堆命令（:NvimTreeFindFile / Refresh / Collapse …），
    --                 只列 cmd 的话那些命令在加载前会「不是编辑器命令」。
    --                 VeryLazy 在 UI 起来之后才触发，实测不占启动时间（setup 只要 ~1ms）
    cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeOpen", "NvimTreeClose" },
    event = "VeryLazy",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup({
        auto_reload_on_write = false, -- 有 filesystem watcher，不用保存时整树重载
        update_focused_file = {
          enable = false, -- 大工程里每次 BufEnter 定位文件会卡
        },
        renderer = {
          highlight_git = "name", -- 旧写法 highlight_git = true 会被 legacy 层翻译成 "name"
          root_folder_label = ": ~/projects",
          indent_markers = {
            enable = true,
          },
        },
        view = {
          preserve_window_proportions = true,
        },
        actions = {
          open_file = {
            resize_window = false,
          },
        },
        filters = {
          -- 点文件照常显示（dotfiles = true 是把它们全藏起来），只藏 .git
          custom = { "^.git$" },
        },
      })
    end,
  },
}
