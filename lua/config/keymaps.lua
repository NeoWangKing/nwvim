local map = vim.keymap.set

map("n", "<space>re", ":restart<CR>")
-- 注意：这里**不要**再把 <space> 单独映射成 ":"。
--
-- 空格是 leader，下面有一堆 <space>xx 系列键位。如果同时把 <space> 本身
-- 映射成一个完整命令，Vim 每次按空格都得等 timeoutlen(500ms) 才能判断
-- 你到底是「要执行那个命令」还是「要按某个 <space>x」；而且 which-key 的
-- 自动触发器会先检查该键是否已被映射（见 which-key/triggers.lua 的
-- is_mapped），发现已映射就**跳过注册**，于是按空格永远弹不出提示面板。
--
-- 需要进命令行：按 <leader>;（见下），或直接按 : 。
map("n", "<space><space>x", ":source %<CR>")
map("n", "<space>x", ":.lua<CR>")
map("v", "<space>x", ":lua<CR>")

map("n", "<leader>;", ":")
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

local term_buf = nil

map("n", "<space>st", function()
  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    local win = vim.fn.bufwinnr(term_buf)
    if win > 0 then
      -- 已有窗口，直接跳转
      vim.api.nvim_set_current_win(vim.fn.win_getid(win))
      return
    end
  end

  -- 判断当前窗口宽高比
  local width = vim.o.columns
  local height = vim.o.lines
  local horizontal = width > (3 * height)  -- 宽 > 高，从右侧打开

  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    -- buffer 存在，但没有窗口，打开新的分屏窗口
    if horizontal then
      vim.cmd("vsplit")
      -- 可以设置列宽，例如取当前窗口的 30%
      local col_width = math.min(50, math.floor(width * 0.3))
      vim.api.nvim_win_set_width(0, col_width)
    else
      vim.cmd("below split")
      local row_height = math.min(10, math.floor(height * 0.3))
      vim.api.nvim_win_set_height(0, row_height)
    end
    vim.api.nvim_set_current_buf(term_buf)
  else
    -- 创建新的终端 buffer
    if horizontal then
      vim.cmd("vsplit")
      vim.cmd.term()
      local col_width = math.min(50, math.floor(width * 0.3))
      vim.api.nvim_win_set_width(0, col_width)
    else
      vim.cmd("below split")
      vim.cmd.term()
      local row_height = math.min(10, math.floor(height * 0.3))
      vim.api.nvim_win_set_height(0, row_height)
    end
    term_buf = vim.api.nvim_get_current_buf()
  end
end, { desc = "Toggle terminal window (adaptive split)" })

-- LSP
--
-- 诊断的全局显示方式在这里统一配置。
-- （原先这段配置写在 plugins/lspconfig.lua 的 LspAttach 回调里，会在每次
--  LSP 附加时重复执行；而 gd / K / gr / 重命名 / 代码操作这几个键位在
--  keymaps.lua 和 lspconfig.lua 里各定义了一份。现已合并到此处。）
vim.diagnostic.config({
  virtual_text = false, -- 关闭行内虚拟文本，界面更清爽；用 <space>ee 查看详情
  float = {
    border = "rounded",
    source = "always",
    prefix = "",
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(ev)
    local bufnr = ev.buf
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    local function opt(desc)
      return { buffer = bufnr, silent = true, desc = desc }
    end

    -- 跳转 / 补全
    map("n", "gd", vim.lsp.buf.definition, opt("Go to definition"))
    map("n", "K", vim.lsp.buf.hover, opt("Hover documentation"))
    map("n", "gr", vim.lsp.buf.references, opt("Go to references"))
    map("n", "<space>rn", vim.lsp.buf.rename, opt("Rename symbol"))
    map("n", "<space>ca", vim.lsp.buf.code_action, opt("Code actions"))

    -- 诊断
    map("n", "<space>ee", vim.diagnostic.open_float, opt("显示当前行的诊断信息"))
    map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, opt("Previous diagnostic"))
    map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, opt("Next diagnostic"))

    -- 格式化：只在服务器真的支持时才绑定
    if client and client.server_capabilities.documentFormattingProvider then
      map("n", "<space>f", function() vim.lsp.buf.format({ async = true }) end, opt("Format buffer"))
    end
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

-- oil.nvim
map("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- go to file
map("n", "<space>gf", function()
  local cfile = vim.fn.expand("<cfile>")
  if cfile == "" then
    vim.notify("光标下没有文件名", vim.log.levels.WARN)
    return
  end

  -- 去掉可能存在的行号/列号后缀 (例如 file:10:5)
  local file, line, col = cfile:match("^([^:]+):?(%d*):?(%d*)$")
  if file == "" or file == nil then file = cfile end
  line = tonumber(line) or 1
  col = tonumber(col) or 1

  -- 1. 先尝试直接打开（支持绝对/相对路径）
  if vim.fn.filereadable(file) == 1 then
    vim.cmd.edit({ file, bang = true })
  else
    -- 2. 在 'path' 选项中查找
    local found = vim.fn.findfile(file)
    if found ~= "" then
      vim.cmd.edit(found)
    else
      vim.notify("找不到文件: " .. file, vim.log.levels.WARN)
      return
    end
  end

  -- 跳转到指定行/列
  if line > 1 or col > 1 then
    vim.api.nvim_win_set_cursor(0, { line, col - 1 })
  end
end, { desc = "Go to file under cursor (enhanced)" })
