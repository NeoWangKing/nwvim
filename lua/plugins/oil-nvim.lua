-- oil-nvim.lua - 目录编辑文件管理器，补 dired 的标记和批量操作。
return {
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      default_file_explorer = true,
      columns = {
        -- "icon",
        "permissions",
        "size",
        "mtime",
      },
      buf_options = {
        buflisted = false,
        bufhidden = "hide",
      },
      skip_confirm_for_simple_edits = true,
      prompt_save_on_select_new_entry = true,
      constrain_cursor = "editable",
      watch_for_changes = true,
      keymaps = {
        -- oil 的帮助窗口直接渲染这张 keymaps 表，带 desc 的键位会自动出现
        -- 帮助只绑 g?，不要绑单键 ?，避免抢掉反向搜索
        ["g?"] = { "actions.show_help", mode = "n" },
        ["<CR>"] = "actions.select",
        ["<C-s>"] = { "actions.select", opts = { vertical = true } },
        ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
        ["<C-t>"] = { "actions.select", opts = { tab = true } },
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = { "actions.close", mode = "n" },
        ["<C-l>"] = "actions.refresh",
        ["-"] = { "actions.parent", mode = "n" },
        ["_"] = { "actions.open_cwd", mode = "n" },
        ["`"] = { "actions.cd", mode = "n" },
        ["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
        ["gs"] = { "actions.change_sort", mode = "n" },
        ["gx"] = "actions.open_external",
        ["g."] = { "actions.toggle_hidden", mode = "n" },
        ["g\\"] = { "actions.toggle_trash", mode = "n" },

        -- dired 兼容层（lua/config/oil-dired.lua）：oil 的 wdired 已覆盖改名删除，
        -- 这里补标记和批量执行。全部挂 <leader> 是因为 oil 缓冲区就是编辑缓冲区，
        -- 照搬 dired 单字母会破坏编辑键位；盖掉的 <leader>d/mg/td/tw 在目录里用不到。

        -- 标记按绝对路径记录，刷新、改排序、增删行后不会错位
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
      view_options = {
        -- 显示隐藏文件
        show_hidden = true,
        -- 什么算隐藏文件
        is_hidden_file = function(name, bufnr)
          local m = name:match("^%.")
          return m ~= nil
        end,
        -- 即使 show_hidden 也不显示的文件
        is_always_hidden = function(name, bufnr)
          return false
        end,
        -- 文件名自然数排序，大目录自动关闭
        natural_order = "fast",
        case_insensitive = false,
        sort = {
          -- 可排序列见 :help oil-columns
          { "type", "asc" },
          { "name", "asc" },
        },
        -- 自定义文件名高亮组
        highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
          return nil
        end,
      },
      -- SSH 传输时额外传给 scp 的参数
      extra_scp_args = {},
      -- S3 文件操作时额外传给 aws 的参数
      extra_s3_args = {},
      -- git 文件操作支持（实验性）
      git = {
        -- 返回 true 时自动 git add/mv/rm
        add = function(path)
          return false
        end,
        mv = function(src_path, dest_path)
          return false
        end,
        rm = function(path)
          return false
        end,
      },
      -- oil.open_float 浮窗配置
      float = {
        -- 浮窗内边距
        padding = 2,
        -- 宽高可给整数或 0~1 的比例
        max_width = 0,
        max_height = 0,
        border = nil,
        win_options = {
          winblend = 0,
        },
        -- 自定义浮窗标题
        get_win_title = nil,
        -- 预览分屏方向
        preview_split = "auto",
        -- 传给 nvim_open_win 的配置，改这里自定义布局
        override = function(conf)
          return conf
        end,
      },
      -- 文件预览窗口配置
      preview_win = {
        -- 光标移动时自动刷新预览
        update_on_cursor_moved = true,
        -- 预览打开方式
        preview_method = "fast_scratch",
        -- 返回 true 时禁用该文件的预览（比如大文件）
        disable_preview = function(filename)
          return false
        end,
        -- Window-local options to use for preview window buffers
        win_options = {},
      },
      -- 操作确认浮窗配置
      confirmation = {
        max_width = 0.9,
        min_width = { 40, 0.4 },
        width = nil,
        max_height = 0.9,
        min_height = { 5, 0.1 },
        height = nil,
        border = nil,
        win_options = {
          winblend = 0,
        },
      },
      -- 进度浮窗配置
      progress = {
        max_width = 0.9,
        min_width = { 40, 0.4 },
        width = nil,
        max_height = { 10, 0.9 },
        min_height = { 5, 0.1 },
        height = nil,
        border = nil,
        minimized_border = "none",
        win_options = {
          winblend = 0,
        },
      },
      -- SSH 浮窗配置
      ssh = {
        border = nil,
      },
      -- 键位帮助浮窗配置
      keymaps_help = {
        border = nil,
      },
    },
    dependencies = {
      { "nvim-mini/mini.icons", opts = {} },
      { "nvim-tree/nvim-web-devicons", opts = {} },
    },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- 懒加载容易出问题，保持常驻
    lazy = false,
  }
}
