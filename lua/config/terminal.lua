-- terminal.lua - <leader>st：可复用的自适应分屏终端（键位在 config/keymaps.lua）。
-- 从 keymaps.lua 抽出来单独放：这段逻辑有几十行，塞在键位表里会把全局映射淹掉。

local M = {}

-- 复用同一个终端 buffer；它是模块级变量，切窗口 / 换 buffer 都不会丢。
local term_buf = nil

-- 宽 > 高（宽屏）时从右侧竖分屏，否则从下方横分屏；新窗口都限制在 30% 以内。
-- 原来这段在两个分支里各抄了一遍，现在只留一份。
local function split_for_terminal()
  local width, height = vim.o.columns, vim.o.lines

  if width > 3 * height then
    vim.cmd("vsplit")
    vim.api.nvim_win_set_width(0, math.min(50, math.floor(width * 0.3)))
  else
    vim.cmd("below split")
    vim.api.nvim_win_set_height(0, math.min(10, math.floor(height * 0.3)))
  end
end

function M.toggle()
  local buf_alive = term_buf ~= nil and vim.api.nvim_buf_is_valid(term_buf)

  -- 终端已经有窗口：直接跳过去，不再开新的
  if buf_alive then
    local win = vim.fn.bufwinnr(term_buf)
    if win > 0 then
      vim.api.nvim_set_current_win(vim.fn.win_getid(win))
      return
    end
  end

  split_for_terminal()

  if buf_alive then
    vim.api.nvim_set_current_buf(term_buf) -- buffer 还在，只是窗口被关了
  else
    vim.cmd.term()
    term_buf = vim.api.nvim_get_current_buf()
  end
end

return M
