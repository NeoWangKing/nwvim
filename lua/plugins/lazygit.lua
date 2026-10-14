
-- lazygit.lua - LazyGit 集成，<leader>gg 打开。
return {
  {
    "kdheepak/lazygit.nvim",
    -- 懒加载：<leader>gg 走 <cmd>LazyGit<CR>。
    -- 另外给 VeryLazy 是因为它还有 LazyGitLog / Filter / CurrentFile 等命令，
    -- 只列 LazyGit 的话那些命令在加载前会报「不是编辑器命令」。
    cmd = "LazyGit",
    event = "VeryLazy",
  },
}
