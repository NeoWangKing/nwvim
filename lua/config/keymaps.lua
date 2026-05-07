-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- ============================================================================
-- 通用辅助
-- ============================================================================

-- 用空格进入命令行模式
map("n", "<space>", ":", { noremap = true, silent = true, desc = "Enter Ex command" })

-- ============================================================================
-- 插入模式快速退出 (多种组合避免误触)
-- ============================================================================
local esc_opts = { noremap = true, silent = true }
map("i", "jk", "<Esc>", vim.tbl_extend("force", esc_opts, { desc = "Exit insert mode (jk)" }))

-- ============================================================================
-- 更好的软换行移动
-- ============================================================================
map("n", "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, { expr = true, silent = true, desc = "Down (wrap-aware)" })
map("n", "k", function()
  return vim.v.count == 0 and "gk" or "k"
end, { expr = true, silent = true, desc = "Up (wrap-aware)" })

-- ============================================================================
-- 搜索时保持居中
-- ============================================================================
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- ============================================================================
-- 复制/删除但不影响默认寄存器
-- ============================================================================
-- map("x", "<leader>p", '"_dp', { desc = "Paste without yanking" })
map({ "n", "x" }, "<leader>x", '"_d', { desc = "Delete without yanking" })

-- ============================================================================
-- 缓冲区导航
-- ============================================================================
map("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })

-- ============================================================================
-- 窗口操作
-- ============================================================================
map("n", "<leader><C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<leader><C-j>", "<C-w>j", { desc = "Move to bottom window" })
map("n", "<leader><C-k>", "<C-w>k", { desc = "Move to top window" })
map("n", "<leader><C-l>", "<C-w>l", { desc = "Move to right window" })

map("n", "<leader>sv", ":vsplit<CR>", { desc = "Split window vertically" })
map("n", "<leader>sh", ":split<CR>", { desc = "Split window horizontally" })
map("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- ============================================================================
-- 行/选区移动
-- ============================================================================
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- ============================================================================
-- 缩进（保持选区）
-- ============================================================================
map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

-- ============================================================================
-- 合并行（保持光标位置）
-- ============================================================================
map("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

-- ============================================================================
-- 实用功能
-- ============================================================================
map("n", "<leader>pwd", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  print("Copied file path: " .. path)
end, { desc = "Copy full file path to clipboard" })

-- ============================================================================
-- 开关语法检查
-- ============================================================================
map("n", "<leader>td", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

-- ============================================================================
-- 视图块选择（确保 Ctrl-v 始终可用）
-- ============================================================================
map({ "n", "v" }, "<C-v>", "<C-v>", { noremap = true, desc = "Visual block mode" })

-- ============================================================================
-- bufferline 相关快捷键（需配合 bufferline.nvim）
-- ============================================================================
map("n", "<leader><Tab>", ":BufferLineCycleNext<CR>", { desc = "Next buffer" })
map("n", "<S-Tab>", ":BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
map("n", "<leader>bc", ":BufferLinePickClose<CR>", { desc = "Pick buffer to close" })
map("n", "<leader>bch", ":BufferLineCloseLeft<CR>", { desc = "Close buffers to the left" })
map("n", "<leader>bcl", ":BufferLineCloseRight<CR>", { desc = "Close buffers to the right" })

-- 终端模式下切换缓冲区
map("t", "<leader><Tab>", [[<Cmd>BufferLineCycleNext<CR>]], { desc = "Next buffer (terminal)" })
map("t", "<S-Tab>", [[<Cmd>BufferLineCyclePrev<CR>]], { desc = "Previous buffer (terminal)" })

-- ============================================================================
-- LSP 快捷键（通过 LspAttach 自动添加）
-- ============================================================================
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(ev)
    local bufnr = ev.buf
    -- 直接为每个映射传递完整的 opts，不再使用 tbl_extend
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, silent = true, desc = "Go to definition" })
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, silent = true, desc = "Hover documentation" })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, silent = true, desc = "Rename symbol" })
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, silent = true, desc = "Code actions" })
    vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = bufnr, silent = true, desc = "Go to references" })
    vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { buffer = bufnr, silent = true, desc = "Previous diagnostic" })
    vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { buffer = bufnr, silent = true, desc = "Next diagnostic" })
  end,
})

-- ============================================================================
-- 切换自动换行快捷键
-- ============================================================================
map("n", "<leader>tw", function()
  local saved_cursor = vim.api.nvim_win_get_cursor(0)
  vim.wo.wrap = not vim.wo.wrap   -- 直接使用 vim.wo 更可靠
  vim.api.nvim_win_set_cursor(0, saved_cursor)
  print("Wrap " .. (vim.wo.wrap and "ON" or "OFF"))
end, { desc = "Toggle wrap (keep cursor)" })
