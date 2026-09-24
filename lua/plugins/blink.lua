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
            opts = {
              -- 目录里的所有 .txt 都会作为词典（见 dictionary/README.md）
              dictionary_directories = require('config.platform').dictionary_dirs(),

              -- 把 fzf 从「模糊匹配」改成「前缀匹配」。
              --
              -- 插件默认用 `fzf --filter=<前缀>`，而 fzf 的 --filter 默认是模糊
              -- 匹配。词典有 37 万词时这会严重稀释排序：实测查 malloc，
              -- 输入 "mall" 它排第 59 位、输入 "mallo" 排第 21 位，
              -- 前面全是被模糊命中的生僻英文词。
              --
              -- fzf 的查询语法支持 `^` 前缀锚点，加上它之后 "mallo" 只会命中
              -- 以 mallo 开头的词，排序问题就没了。
              -- （前缀只含 [A-Za-z0-9]，没有正则元字符，锚定安全。）
              get_command_args = function(prefix, command)
                if command == "fzf" then
                  return { "--filter=^" .. prefix, "--sync", "-i" }
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
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },

    -- 注意：原来这里还有 opts_extend = { "sources.default" }，
    -- 它的作用是把多个插件 spec 里的 sources.default 列表拼起来。
    -- 但 sources.default 现在是函数，拼接语义不再成立，故移除。
    -- 若日后确实需要扩展候选源，改上面 default 函数里返回的列表即可。
  }
}
