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
      -- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
      -- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "n" })
      -- Additionally, if it is a string that matches "actions.<name>",
      -- it will use the mapping at require("oil.actions").<name>
      -- Set to `false` to remove a keymap
      -- See :help oil-actions for a list of all available actions
      keymaps = {
        -- oil 的帮助窗口直接渲染下面这张 keymaps 表，所以自定义键位
        -- （带 desc 的）会自动出现在里面，不需要另外维护一份清单。
        --
        -- ⚠ 帮助只绑在 g? 上，不要另绑单键 `?`：
        --   oil 缓冲区里 `?` 仍要用于反向搜索，夺走它只省一次按键，不划算。
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

        -- ═══════════════════════════════════════════════════════════════
        --  dired 兼容层（实现在 lua/config/oil-dired.lua）
        --
        --  背景：oil 的「可编辑目录缓冲区」本身就是 Emacs 的 wdired ——
        --  改名 = 编辑那一行，删除 = 删掉那一行，:w 提交（所以 :w 就是
        --  dired 的 x）。下面补的是 dired 的另一半：标记 + 批量执行。
        --
        --  ⚠ 为什么全部挂在 <leader>（空格）下
        --
        --  dired 能把 m/u/t/T/M/Z/D/s/^ 这些单字母全用掉，是因为
        --  **dired 缓冲区不是文本编辑缓冲区**，文件操作不经过文本。
        --  而 oil 的缓冲区**就是**操作模型本身，编辑类按键是它的命脉。
        --  照搬 dired 单字母键位会直接破坏编辑器，实测后果：
        --    · u 被夺走 -> 改错文件名后无法撤销（只能 :undo）
        --    · Z 被夺走 -> ZZ（保存退出）失效，按 ZZ 变成触发两次 Z
        --    · t/T 被夺走 -> 常用的 till 动作失效
        --    · D 被夺走 -> 编辑文件名时 d$ 失效
        --    · s/^/M 被夺走 -> substitute / 行首 / 屏幕中间 全部失效
        --
        --  统一加 <leader> 前缀后冲突就不存在了，而且第二段还能原样沿用
        --  dired 的字母，所以还原度反而最高（<leader>M 就是 dired 的 M）。
        --  空格在 oil 缓冲区里原本完全空闲。
        --
        --  代价（仅在 oil 缓冲区内）：会盖住 4 个全局 <leader> 映射 ——
        --    <leader>d（delete without yank）、<leader>mg（multi grep）、
        --    <leader>td / <leader>tw（toggle diagnostics / wrap）
        --  都是在目录列表里不会用到的操作，可以接受。
        --
        --  操作目标优先级：有标记用标记；否则用可视选区；再否则只用光标行。
        --  按 ? 或 g? 可随时查看当前全部键位（帮助窗口会自动包含这些项）。
        -- ═══════════════════════════════════════════════════════════════

        -- ── 标记（第二段沿用 dired 原字母）──────────────────────────
        --  标记以「绝对路径」记录，所以 oil 刷新、改排序、增删行之后
        --  标记依然跟着文件走，不会错位。
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

        -- ── 批量操作 ────────────────────────────────────────────────
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
        -- Show files and directories that start with "."
        show_hidden = true,
        -- This function defines what is considered a "hidden" file
        is_hidden_file = function(name, bufnr)
          local m = name:match("^%.")
          return m ~= nil
        end,
        -- This function defines what will never be shown, even when `show_hidden` is set
        is_always_hidden = function(name, bufnr)
          return false
        end,
        -- Sort file names with numbers in a more intuitive order for humans.
        -- Can be "fast", true, or false. "fast" will turn it off for large directories.
        natural_order = "fast",
        -- Sort file and directory names case insensitive
        case_insensitive = false,
        sort = {
          -- sort order can be "asc" or "desc"
          -- see :help oil-columns to see which columns are sortable
          { "type", "asc" },
          { "name", "asc" },
        },
        -- Customize the highlight group for the file name
        highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
          return nil
        end,
      },
      -- Extra arguments to pass to SCP when moving/copying files over SSH
      extra_scp_args = {},
      -- Extra arguments to pass to aws s3 when creating/deleting/moving/copying files using aws s3
      extra_s3_args = {},
      -- EXPERIMENTAL support for performing file operations with git
      git = {
        -- Return true to automatically git add/mv/rm files
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
      -- Configuration for the floating window in oil.open_float
      float = {
        -- Padding around the floating window
        padding = 2,
        -- max_width and max_height can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        max_width = 0,
        max_height = 0,
        border = nil,
        win_options = {
          winblend = 0,
        },
        -- optionally override the oil buffers window title with custom function: fun(winid: integer): string
        get_win_title = nil,
        -- preview_split: Split direction: "auto", "left", "right", "above", "below".
        preview_split = "auto",
        -- This is the config that will be passed to nvim_open_win.
        -- Change values here to customize the layout
        override = function(conf)
          return conf
        end,
      },
      -- Configuration for the file preview window
      preview_win = {
        -- Whether the preview window is automatically updated when the cursor is moved
        update_on_cursor_moved = true,
        -- How to open the preview window "load"|"scratch"|"fast_scratch"
        preview_method = "fast_scratch",
        -- A function that returns true to disable preview on a file e.g. to avoid lag
        disable_preview = function(filename)
          return false
        end,
        -- Window-local options to use for preview window buffers
        win_options = {},
      },
      -- Configuration for the floating action confirmation window
      confirmation = {
        -- Width dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        -- min_width and max_width can be a single value or a list of mixed integer/float types.
        -- max_width = {100, 0.8} means "the lesser of 100 columns or 80% of total"
        max_width = 0.9,
        -- min_width = {40, 0.4} means "the greater of 40 columns or 40% of total"
        min_width = { 40, 0.4 },
        -- optionally define an integer/float for the exact width of the preview window
        width = nil,
        -- Height dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        -- min_height and max_height can be a single value or a list of mixed integer/float types.
        -- max_height = {80, 0.9} means "the lesser of 80 columns or 90% of total"
        max_height = 0.9,
        -- min_height = {5, 0.1} means "the greater of 5 columns or 10% of total"
        min_height = { 5, 0.1 },
        -- optionally define an integer/float for the exact height of the preview window
        height = nil,
        border = nil,
        win_options = {
          winblend = 0,
        },
      },
      -- Configuration for the floating progress window
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
      -- Configuration for the floating SSH window
      ssh = {
        border = nil,
      },
      -- Configuration for the floating keymaps help window
      keymaps_help = {
        border = nil,
      },
    },
    -- Optional dependencies
    dependencies = {
      { "nvim-mini/mini.icons", opts = {} },
      { "nvim-tree/nvim-web-devicons", opts = {} },
    },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  }
}
