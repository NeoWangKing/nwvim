-- telescope.lua - 模糊查找：文件/文本/buffer/帮助。
--
-- 懒加载：键位统一在 config/keymaps.lua（用 <cmd>Telescope ...<CR> 的形式），
-- cmd 触发会自动把它拉起来。启动期不再为 telescope + plenary + fzf-native 买单
-- （fzf-native 是编译好的 .so，load_extension 那一下并不便宜）。
return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    cmd = "Telescope",
    config = function()
      require("telescope").setup({
        pickers = {
          find_files = {
            theme = "ivy",
          },
        },
        extensions = {
          fzf = {},
        },
      })

      require("telescope").load_extension("fzf")
    end,
  },
}
