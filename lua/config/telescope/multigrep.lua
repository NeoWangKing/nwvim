-- multigrep.lua - 自定义 Telescope picker：rg 关键词 + glob，两个空格分隔。
local M = {}

-- 键位在 config/keymaps.lua（<leader>mg）。telescope 是懒加载的，所以这里的
-- require 必须放在函数体内：调用时才触发加载，模块顶层 require 会在启动期就把它拉起来。
---@param opts table|nil
function M.live(opts)
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local make_entry = require('telescope.make_entry')
  local conf = require('telescope.config').values

  -- 注意：这里不能漏掉 local —— 写成 `opts = opts or {}` 会写进 _G
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()

  local finder = finders.new_async_job {
    command_generator = function(prompt)
      if not prompt or prompt == "" then
        return nil
      end
      local pieces = vim.split(prompt, "  ")
      local args = { "rg" }
      if pieces[1] then
        table.insert(args, "-e")
        table.insert(args, pieces[1])
      end
      
      if pieces[2] then
        table.insert(args, "-g")
        table.insert(args, pieces[2])
      end

      ---@diagnostic disable-next-line: deprecated
      return vim.iter({
        args,
        { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" },
      }):flatten():totable()
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  }

  pickers.new(opts, {
    debounce = 100,
    prompt_title = "Multi Grep",
    finder = finder,
    previewer = conf.grep_previewer(opts),
    sorter = require('telescope.sorters').empty(),
  }):find()
end

return M
