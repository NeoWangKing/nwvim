-- oil-nvim.lua - 目录编辑文件管理器（oil 本身就是 wdired），并在上面补 dired 的标记与批量操作。
--
-- 只写与 oil 默认值不同的选项。把默认值逐条抄一遍有两个坏处：后来的人会以为这里改过东西，
-- 而且插件升级改了默认值之后，配置会把旧行为钉死。全部选项见 :h oil.SetupOpts。
return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      -- 目录缓冲区交给 oil 接管。这行是默认值，写出来是因为它和 init.lua 里关掉 netrw
      -- 是一套配套决策，不是随手抄的。
      default_file_explorer = true,

      -- 图标 + 权限 / 大小 / 修改时间；列值用标准高亮组上色
      columns = {
        "icon",
        { "permissions", highlight = "String" },
        { "size", highlight = "Number" },
        { "mtime", highlight = "Comment" },
      },

      -- 简单编辑（改名这类）不弹确认框；删除仍会确认，那是 oil 的安全设计
      skip_confirm_for_simple_edits = true,
      -- 外部改动（git checkout、别的终端里删文件）自动重载目录
      watch_for_changes = true,

      view_options = {
        show_hidden = true,
        -- 文件名按文件类型上色（目录/链接仍用 oil 自己的高亮组）
        highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
          if is_hidden then return "OilHidden" end
          if entry.type == "directory" then return "OilDir" end
          if is_link_orphan then return "OilOrphanLink" end
          if is_link_target then return "OilLinkTarget" end
          local ok, devicons = pcall(require, "nvim-web-devicons")
          if not ok then return nil end
          local _, hl = devicons.get_icon(entry.name, nil, { default = true })
          return hl
        end,
      },

      -- dired 兼容层（实现在 lua/config/oil-dired.lua）：oil 的 wdired 已覆盖改名删除，
      -- 这里补标记和批量执行。全部挂 <leader> 是因为 oil 缓冲区就是编辑缓冲区，
      -- 照搬 dired 单字母会破坏编辑键位；盖掉的 <leader>d/mg/td/tw 在目录里用不到。
      --
      -- 标记按绝对路径记录，刷新、改排序、增删行后不会错位。
      -- keymaps 其余条目沿用 oil 默认值，不再抄写；帮助窗口（g?）会渲染这张表。
      keymaps = {
        ["<leader>m"] = {
          callback = function() require("config.oil-dired").toggle_mark() end,
          desc = "dired: 标记/取消标记当前项（dired 的 m）",
          mode = "n",
        },
        ["<leader>U"] = {
          callback = function() require("config.oil-dired").unmark_all() end,
          desc = "dired: 清除全部标记（dired 的 U）",
          mode = "n",
        },
        ["<leader>t"] = {
          callback = function() require("config.oil-dired").invert_marks() end,
          desc = "dired: 反转标记（dired 的 t）",
          mode = "n",
        },
        ["<leader>%m"] = {
          callback = function() require("config.oil-dired").mark_by_pattern() end,
          desc = "dired: 按正则标记，Lua 正则（dired 的 % m）",
          mode = { "n", "v" },
        },

        -- 批量操作
        ["<leader>d"] = {
          callback = function() require("config.oil-dired").delete_marked() end,
          desc = "dired: 暂存删除，:w 提交（dired 的 d）",
          mode = "n",
        },
        ["<leader>M"] = {
          callback = function() require("config.oil-dired").chmod() end,
          desc = "dired: chmod（dired 的 M）",
          mode = { "n", "v" },
        },
        ["<leader>T"] = {
          callback = function() require("config.oil-dired").touch() end,
          desc = "dired: touch（dired 的 T）",
          mode = { "n", "v" },
        },
        ["<leader>Z"] = {
          callback = function() require("config.oil-dired").compress() end,
          desc = "dired: gzip -k 压缩（dired 的 Z）",
          mode = { "n", "v" },
        },
        ["<leader>!"] = {
          callback = function() require("config.oil-dired").shell_command() end,
          desc = "dired: 对目标执行 shell 命令，{} = 文件名（dired 的 !）",
          mode = { "n", "v" },
        },
      },
    },
    dependencies = {
      { "nvim-mini/mini.icons", opts = {} },
      { "nvim-tree/nvim-web-devicons", opts = {} },
    },
    -- 懒加载容易出问题（它是目录缓冲区的接管者），保持常驻
    lazy = false,
  },
}
