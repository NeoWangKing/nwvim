-- ═══════════════════════════════════════════════════════════════════════
--  blink.cmp — 补全
--
--  这里实现了两种不同的补全形态，按文件类型自动分流：
--
--  ┌─ 写作类文件（markdown / text / tex / gitcommit / mail / rst / …）
--  │   · 单词补全以「光标后的暗色虚影」出现（ghost text），不弹候选框
--  │   · 候选来自 dictionary（词典）+ buffer（当前文档已出现的词）+ path
--  │   · 按 Tab 接受虚影，Esc 或继续输入即忽略
--  │
--  └─ 代码文件
--      · 维持候选框补全（lsp / path / snippets / buffer）
--      · 词典源不参与，避免英文单词污染代码候选
--
--  实现要点（blink.cmp v1.10 源码依据）：
--    · 虚影由 list.show_emitter 驱动（completion/init.lua:95），
--      与菜单是否打开无关 —— 所以关掉菜单不会连虚影一起关掉。
--    · 菜单必须保持 menu.enabled = true。它控制的是整个菜单模块的装配；
--      设成 false 会让 ghost text 那段引用的 menu.context 变成 nil。
--      要「不自动弹窗」应该用 menu.auto_show，而不是 menu.enabled。
--    · sources.default 支持函数形式（blink.cmp.SourceList = string[] | fun(): string[]），
--      所以可以按文件类型动态决定候选来源。
-- ═══════════════════════════════════════════════════════════════════════

-- 视为「写作」的文件类型
local PROSE_FILETYPES = {
  markdown = true,
  text = true,
  tex = true,
  plaintex = true,
  gitcommit = true,
  mail = true,
  rst = true,
  asciidoc = true,
  org = true,
  norg = true,
  help = true,
}

local function is_prose()
  return PROSE_FILETYPES[vim.bo.filetype] == true
end

return {
  {
    'saghen/blink.cmp',
    dependencies = {
      -- 片段源
      'rafamadriz/friendly-snippets',
      -- 词典补全源。v3.0 起零外部依赖，只需要词典文件；
      -- 词典目录随仓库走（~/.config/nvim/dictionary/），三端一致。
      -- 详见 dictionary/README.md
      'Kaiser-Yang/blink-cmp-dictionary',
    },

    -- use a release tag to download pre-built binaries
    version = '1.*',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = { preset = 'super-tab' },

      appearance = {
        nerd_font_variant = 'mono',
      },

      completion = {
        -- 文档浮窗只在手动触发时显示
        documentation = { auto_show = false },

        -- 写作文件里不自动弹候选框；代码文件里照常弹。
        -- 注意用 auto_show 而不是 enabled —— 见文件头说明。
        menu = {
          auto_show = function()
            return not is_prose()
          end,
        },

        -- 虚影文字：只在写作文件里启用
        ghost_text = {
          enabled = function()
            return is_prose()
          end,
          show_with_selection = true,      -- 有选中项时显示
          show_without_selection = false,
          show_with_menu = false,          -- 万一菜单开着就不重复显示
          show_without_menu = true,        -- 关键：没有菜单时也要显示
        },
      },

      sources = {
        -- 函数形式：每次补全时按当前文件类型决定候选来源
        default = function()
          if is_prose() then
            local list = { 'buffer', 'path' }
            -- 词典目录存在时才挂上词典源，避免挂一个永远没候选的源
            if #require('config.platform').dictionary_dirs() > 0 then
              table.insert(list, 1, 'dictionary')
            end
            return list
          end
          return { 'lsp', 'path', 'snippets', 'buffer' }
        end,

        providers = {
          dictionary = {
            module = 'blink-cmp-dictionary',
            name = 'Dict',
            -- 至少输入 2 个字符才给候选：词典有 37 万词，
            -- 1 个字符会匹配出海量结果，虚影也会乱跳
            min_keyword_length = 2,

            -- 给候选项打上「词频排名」作为 sortText。
            --
            -- ⚠ 这一步是**整个词频方案能否生效的关键**，而且必须配合下面的
            --   separate_output / get_documentation 一起看。
            --
            --   插件内部是这样返回候选项的：
            --       items[match] = { ... }        -- 用字典存
            --       items = vim.tbl_values(items) -- 取出时变成哈希序
            --   也就是说 fzf 给出的**正确词频顺序在插件内部就被销毁了**，
            --   传到这里已经是乱序。所以光靠「按到达顺序编号」是错的
            --   （实测会把 importunate 这类生僻词排到前面）。
            --
            --   排名只能从 separate_output 那一侧带过来——见 opts 里的注释。
            --   这里把排名写成零填充的 sortText，配合 fuzzy.sorts 生效。
            transform_items = function(_, items)
              for _, item in ipairs(items) do
                local d = item.data and item.data.documentation
                local rank = type(d) == 'table' and d.dict_rank or nil
                if rank then
                  item.sortText = string.format('%05d', rank)
                end
              end
              return items
            end,

            opts = {
              -- 目录里的所有 .txt 都会作为词典（见 dictionary/README.md）
              dictionary_directories = require('config.platform').dictionary_dirs(),

              -- ── 把「词频排名」从有序的原始输出带到 blink 的 item 上 ──
              --
              -- 背景（实测确认）：插件内部用 `items[match] = {...}` 建字典，
              -- 再 `vim.tbl_values(items)` 取出，**顺序在这一步就被销毁**。
              -- fzf 返回的是正确的词频序（可用 vim.system 拦截验证），
              -- 但传进 blink 时已经变成哈希序，所以 transform_items 里
              -- 按到达顺序编号是错的。
              --
              -- separate_output 拿到的却是**有序**的原始输出，而且它的返回
              -- 类型声明就是 `any[]`，允许返回任意结构。于是这里把行号
              -- （= 该前缀下的词频排名）挂在条目上。
              --
              -- 接着要把它透传给 blink 的 item —— 插件唯一能透传的字段是
              -- data.documentation。返回 **table** 而不是 string 是有意的：
              -- 插件的文档解析逻辑看到「没有 get_command 的表」会把
              -- resolved_item.documentation 置为 nil，所以不会真的显示成文档。
              separate_output = function(output)
                local items, seen = {}, {}
                for line in output:gmatch("[^\r\n]+") do
                  if not seen[line] then
                    seen[line] = true
                    items[#items + 1] = { word = line, rank = #items + 1 }
                  end
                end
                return items
              end,
              get_label = function(item) return item.word end,
              get_insert_text = function(item) return item.word end,
              get_documentation = function(item) return { dict_rank = item.rank } end,

              -- 把 fzf 从「模糊匹配」改成「前缀匹配」，并强制它保持词库顺序。
              --
              -- ① 前缀锚定：插件默认用 `fzf --filter=<前缀>`，而 --filter 默认是
              --    模糊匹配。词典有 37 万词时这会严重稀释排序：实测查 malloc，
              --    输入 "mall" 它排第 59 位、输入 "mallo" 排第 21 位。
              --    fzf 查询语法支持 `^` 前缀锚点，加上后 "mallo" 只命中以
              --    mallo 开头的词。（前缀只含 [A-Za-z0-9]，锚定安全。）
              --
              -- ② --tiebreak=index：这一步是**必须**的。
              --    fzf 的 --filter 默认会按自己的评分重新排序、**完全无视输入
              --    顺序**（实测：输入 reales/realer/reality/really/real，输出
              --    是 real/reales/realer/really/reality），--no-sort 也无效。
              --    而词库已经按词频重排过（见 scripts/build-dictionary.py），
              --    目的正是让「第一个候选 = 最常用的词」。没有 index，
              --    词频重排会被 fzf 全部抹掉。
              --    ⚠ index 必须是最后一个 tiebreak 条件，
              --      写成 "--tiebreak=index,length" 会直接报错。
              get_command_args = function(prefix, command)
                if command == "fzf" then
                  return { "--filter=^" .. prefix, "--sync", "-i", "--tiebreak=index" }
                elseif command == "rg" then
                  return {
                    "--color=never", "--no-line-number", "--no-messages",
                    "--no-filename", "--ignore-case", "-e", "^" .. prefix,
                  }
                elseif command == "grep" then
                  return { "--color=never", "--ignore-case", "-e", "^" .. prefix }
                end
                return {}
              end,
            },
          },
        },
      },

      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      --
      -- sorts 把 sort_text 提到 score 之前：词典项带了 sortText（= 词频排名，
      -- 见上面 dictionary provider 的 transform_items），这样词典项之间严格
      -- 按词频排，blink 的模糊分不再重排它们（否则打字 physi 会给出
      -- physicianless 而非 physical）。
      --
      -- 不会误伤其它源：sort.sort_text 在任一方没有 sortText 时返回 nil，
      -- 会自动跳到下一个准则，所以 buffer / path 仍然按 score 排。
      -- LSP 的 sortText 本来就是 LSP 规范里给排序用的，提前到 score 之前
      -- 更符合规范；而且词典源只在散文里出现，与 LSP 不会同时在场。
      -- 列表里全是字符串，Rust 实现可直接排序，不会退回 Lua。
      fuzzy = {
        implementation = "prefer_rust_with_warning",
        sorts = { 'sort_text', 'score' },
      },
    },

    -- 注意：原来这里还有 opts_extend = { "sources.default" }，
    -- 它的作用是把多个插件 spec 里的 sources.default 列表拼起来。
    -- 但 sources.default 现在是函数，拼接语义不再成立，故移除。
    -- 若日后确实需要扩展候选源，改上面 default 函数里返回的列表即可。
  }
}
