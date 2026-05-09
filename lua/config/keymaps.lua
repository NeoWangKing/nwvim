-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map("n", "<leader>re", ":restart<CR>", { desc = "Restart NeoVim" })
map("n", "<leader><leader>x", ":source<CR>", { desc = "Source" })

map("n", "<space>", ":", { noremap = true, silent = true, desc = "Enter Ex command" })

local esc_opts = { noremap = true, silent = true }
map("i", "jk", "<Esc>", vim.tbl_extend("force", esc_opts, { desc = "Exit insert mode (jk)" }))

map("n", "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, { expr = true, silent = true, desc = "Down (wrap-aware)" })
map("n", "k", function()
  return vim.v.count == 0 and "gk" or "k"
end, { expr = true, silent = true, desc = "Up (wrap-aware)" })

map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

map({ "n", "x" }, "<leader>d", '"_d', { desc = "Delete without yanking" })

map("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

map("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

map("n", "<leader>pwd", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  print("Copied file path: " .. path)
end, { desc = "Copy full file path to clipboard" })

map("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
-- bufferline（bufferline.nvim）
map("n", "bn", ":BufferLineCycleNext<CR>", { desc = "Next buffer(bufferline)" })
map("n", "bp", ":BufferLineCyclePrev<CR>", { desc = "Previous buffer(bufferline)" })
map("n", "<leader>bc", ":BufferLinePickClose<CR>", { desc = "Pick a buffer to close" })
map("n", "<leader>bch", ":BufferLineCloseLeft<CR>", { desc = "Close buffers to the left" })
map("n", "<leader>bcl", ":BufferLineCloseRight<CR>", { desc = "Close buffers to the right" })

map("n", "<leader>sv", ":vsplit<CR>", { desc = "Split window vertically" })
map("n", "<leader>sh", ":split<CR>", { desc = "Split window horizontally" })
local job_id = 0
map("n", "<leader>st", function()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0, 10)

  job_id = vim.bo.channel
end, { desc = "Split window for terminal downwards"})
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Return to normal mode" })

map("n", "<leader>ls", function()
  vim.fn.chansend(job_id, { "ls -la\r\n" })
end)

-- LSP
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(ev)
    local bufnr = ev.buf
    map("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, silent = true, desc = "Go to definition" })
    map("n", "K", vim.lsp.buf.hover, { buffer = bufnr, silent = true, desc = "Hover documentation" })
    map("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, silent = true, desc = "Rename symbol" })
    map("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, silent = true, desc = "Code actions" })
    map("n", "gr", vim.lsp.buf.references, { buffer = bufnr, silent = true, desc = "Go to references" })
    map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { buffer = bufnr, silent = true, desc = "Previous diagnostic" })
    map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { buffer = bufnr, silent = true, desc = "Next diagnostic" })
  end,
})

map("n", "<leader>td", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

map("n", "<leader>tw", function()
  local saved_cursor = vim.api.nvim_win_get_cursor(0)
  vim.wo.wrap = not vim.wo.wrap
  vim.api.nvim_win_set_cursor(0, saved_cursor)
  print("Wrap " .. (vim.wo.wrap and "ON" or "OFF"))
end, { desc = "Toggle wrap (keep cursor)" })
