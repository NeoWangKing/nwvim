local map = vim.keymap.set

map("n", "<space>re", ":restart<CR>")
map("n", "<space><space>x", ":source %<CR>")
map("n", "<space>x", ":.lua<CR>")
map("v", "<space>x", ":lua<CR>")

map("n", "<space>", ":")
map("i", "jk", "<Esc>")

vim.keymap.set('n', 'p', function()
  local save_col = vim.fn.col('.')
  vim.cmd('normal! p')
  vim.fn.cursor(vim.fn.line('.'), save_col)
end, { desc = "Paste and keep the cursor col" })

vim.keymap.set('n', 'P', function()
  local save_col = vim.fn.col('.')
  vim.cmd('normal! P')
  vim.fn.cursor(vim.fn.line('.'), save_col)
end, { desc = "Paste forwards and keep the cursor col" })

-- better movement
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

map({ "n", "x" }, "<space>d", '"_d', { desc = "Delete without yanking" })

map("n", "<A-Up>", ":resize +2<CR>", { desc = "Increase window height" })
map("n", "<A-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
map("n", "<A-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<A-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

map("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

-- nvim-tree
map("n", "<space>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })

-- lazygit
map("n", "<space>gg", "<cmd>LazyGit<CR>", { desc = "LazyGit" })

-- buffer
map("n", "<space>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<space>bp", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<space>bc", ":BufferLinePickClose<CR>", { desc = "Pick a buffer to close" })
map("n", "<space>bch", ":BufferLineCloseLeft<CR>", { desc = "Close buffers to the left" })
map("n", "<space>bcl", ":BufferLineCloseRight<CR>", { desc = "Close buffers to the right" })

-- split
map("n", "<space>sv", ":vsplit<CR>", { desc = "Split window vertically" })
map("n", "<space>sh", ":split<CR>", { desc = "Split window horizontally" })

local job_id = 0
map("n", "<space>st", function()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0, 10)
  job_id = vim.bo.channel
end, { desc = "Split window for terminal downwards"})
map("t", "jk", "<C-\\><C-n>", { desc = "Return to normal mode" })

map("n", "<space>ls", function()
  vim.fn.chansend(job_id, { "ls -la\r\n" })
end)

-- LSP
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(ev)
    local bufnr = ev.buf
    map("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, silent = true, desc = "Go to definition" })
    map("n", "K", vim.lsp.buf.hover, { buffer = bufnr, silent = true, desc = "Hover documentation" })
    map("n", "<space>rn", vim.lsp.buf.rename, { buffer = bufnr, silent = true, desc = "Rename symbol" })
    map("n", "<space>ca", vim.lsp.buf.code_action, { buffer = bufnr, silent = true, desc = "Code actions" })
    map("n", "gr", vim.lsp.buf.references, { buffer = bufnr, silent = true, desc = "Go to references" })
    map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { buffer = bufnr, silent = true, desc = "Previous diagnostic" })
    map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { buffer = bufnr, silent = true, desc = "Next diagnostic" })
  end,
})

-- toggle
map("n", "<space>td", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

map("n", "<space>tw", function()
  local saved_cursor = vim.api.nvim_win_get_cursor(0)
  vim.wo.wrap = not vim.wo.wrap
  vim.api.nvim_win_set_cursor(0, saved_cursor)
  print("Wrap " .. (vim.wo.wrap and "ON" or "OFF"))
end, { desc = "Toggle wrap (keep cursor)" })
