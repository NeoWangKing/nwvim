-- blink.lua - 补全配置：写作文件走虚影词典补全，代码文件走候选框。
-- 只关 menu.auto_show，不能关 menu.enabled，否则虚影会跟着崩。

-- 写作文件类型
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
      -- 词典源，词典目录随仓库走（dictionary/），三端一致
      'Kaiser-Yang/blink-cmp-dictionary',
    },

    -- 用 release tag 拿预编译二进制
    version = '1.*',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'super-tab',
        ['<C-k>'] = false, -- 让给 tmux / nvim 分屏导航
        ['<A-k>'] = { 'show_signature', 'hide_signature', 'fallback' }, -- 签名帮助改到 Alt+k
      },

      appearance = {
        nerd_font_variant = 'mono',
      },

      completion = {
        -- 文档浮窗只在手动触发时显示
        documentation = { auto_show = false },

        -- 写作文件不自动弹候选框，代码文件照常弹；用 auto_show 而不是 enabled
        menu = {
          auto_show = function()
            return not is_prose()
          end,
        },

        -- 虚影只在写作文件启用
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
        -- 按文件类型动态决定候选来源
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
            -- 词典有 37 万词，至少两个字符再出候选
            min_keyword_length = 2,

            -- 把词频排名写进 sortText。插件内部用哈希表存 items，
            -- fzf 的原始顺序在进来前就丢了，排名只能从 separate_output 带过来。
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
              -- dictionary 目录下所有 .txt 都会作为词典
              dictionary_directories = require('config.platform').dictionary_dirs(),

              -- fzf 的原始输出是有序的，在这里把行号（词频排名）挂在条目上；
              -- 排名借 data.documentation 透传，返回 table 而不是字符串，
              -- 插件就不会真的把它显示成文档。
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

              -- fzf 用 ^ 锚定成前缀匹配，--tiebreak=index 保留词库顺序；
              -- index 必须是最后一个 tiebreak 条件。
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

      -- sort_text 提前到 score 之前：词典按词频排，没有 sortText 的源仍按 score 排
      fuzzy = {
        implementation = "prefer_rust_with_warning",
        sorts = { 'sort_text', 'score' },
      },
    },

    -- sources.default 现在是函数，opts_extend 的拼接语义不成立，已移除
  }
}
