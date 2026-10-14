-- keymaps.lua - 全局键位 + LSP 键位（LspAttach 集中在一处）。
--
-- 约定：全局键位只写在这个文件里（插件自己缓冲区里的键位除外，例如 oil 的
-- lua/plugins/oil-nvim.lua keymaps 表）。统一写 <leader> 而不是 <space>，
-- 两者等价，但写 <leader> 才能一眼看出这是 leader 键位。
local map = vim.keymap.set

-- 重载 / 执行
map("n", "<leader>re", ":restart<CR>", { desc = "Restart Neovim" })
-- 不要把 <leader> 单独映射成 ":"：空格是 leader，映射后每次按空格都要等 timeoutlen，
-- 而且 which-key 看到该键已被映射会跳过注册。进命令行用 <leader>; 或直接按 :。
map("n", "<leader><leader>x", ":source %<CR>", { desc = "Source current file" })
map("n", "<leader>x", ":.lua<CR>", { desc = "Run current line as Lua" })
map("v", "<leader>x", ":lua<CR>", { desc = "Run selection as Lua" })
map("n", "<leader>;", ":", { desc = "Command line" })
map("i", "jk", "<Esc>", { desc = "Leave insert mode" })

-- 粘贴保持光标列：vim 原生 p/P 会把光标移到被粘贴内容的开头，改回原来的列
map("n", "p", function()
  local save_col = vim.fn.col(".")
  vim.cmd("normal! p")
  vim.fn.cursor(vim.fn.line("."), save_col)
end, { desc = "Paste and keep the cursor col" })

map("n", "P", function()
  local save_col = vim.fn.col(".")
  vim.cmd("normal! P")
  vim.fn.cursor(vim.fn.line("."), save_col)
end, { desc = "Paste forwards and keep the cursor col" })

-- 折行时按显示行移动
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

-- 文件树 / lazygit（两者都是懒加载，靠 :NvimTreeToggle / :LazyGit 命令触发）
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
map("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "LazyGit" })

-- 终端（逻辑在 config/terminal.lua）
map("n", "<leader>st", function()
  require("config.terminal").toggle()
end, { desc = "Toggle terminal window (adaptive split)" })

-- buffer
map("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bc", ":BufferLinePickClose<CR>", { desc = "Pick a buffer to close" })
map("n", "<leader>bch", ":BufferLineCloseLeft<CR>", { desc = "Close buffers to the left" })
map("n", "<leader>bcl", ":BufferLineCloseRight<CR>", { desc = "Close buffers to the right" })

-- split
map("n", "<leader>sv", ":vsplit<CR>", { desc = "Split window vertically" })
map("n", "<leader>sh", ":split<CR>", { desc = "Split window horizontally" })

-- Telescope（懒加载：:Telescope 命令触发加载；下面调 builtin / multigrep 的
-- 回调会在 require 时把插件拉起来，所以这里不需要 keys 触发）
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "查找文件" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "全项目搜索文本" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "切换 buffer" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "查找帮助文档" })

map("n", "<leader>en", function()
  require("telescope.builtin").find_files {
    cwd = vim.fn.stdpath("config"),
  }
end, { desc = "查找本配置目录的文件" })

map("n", "<leader>ep", function()
  require("telescope.builtin").find_files {
    cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy"),
  }
end, { desc = "查找插件目录的文件" })

map("n", "<leader>mg", function()
  require("config.telescope.multigrep").live()
end, { desc = "Multi Grep（两个空格分隔关键词与 glob）" })

-- LSP：诊断显示方式和键位统一在这里注册一份，不要再到 lspconfig 里重复定义。
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

    -- 跳转 / 悬浮文档。
    -- ⚠ 重命名、代码操作、引用**不在这里绑**：Neovim 0.11+ 内置了
    --   grn 重命名 / gra 代码操作 / grr 引用 / gri 实现 / grt 类型定义 /
    --   grx 运行 codelens / gO 文档符号（见 :h lsp-default-mappings），
    --   而且是全局无条件设置的（不依赖 LspAttach）。
    --   以前这里的 gr / <leader>rn / <leader>ca 与之重复，还会让按 gr 时等 timeoutlen，已删。
    --   内置**没有** gd 和 K，所以这两个仍由本配置提供。
    map("n", "gd", vim.lsp.buf.definition, opt("Go to definition"))
    map("n", "K", vim.lsp.buf.hover, opt("Hover documentation"))

    -- 诊断
    map("n", "<leader>ee", vim.diagnostic.open_float, opt("显示当前行的诊断信息"))
    map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, opt("Previous diagnostic"))
    map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, opt("Next diagnostic"))

    -- 格式化：只在服务器真的支持时才绑定
    if client and client.server_capabilities.documentFormattingProvider then
      map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, opt("Format buffer"))
    end
  end,
})

-- 开关
map("n", "<leader>td", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

map("n", "<leader>tw", function()
  local saved_cursor = vim.api.nvim_win_get_cursor(0)
  vim.wo.wrap = not vim.wo.wrap
  vim.api.nvim_win_set_cursor(0, saved_cursor)
  print("Wrap " .. (vim.wo.wrap and "ON" or "OFF"))
end, { desc = "Toggle wrap (keep cursor)" })

-- oil.nvim
map("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- 跳转到光标下的文件
map("n", "<leader>gf", function()
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

  -- 先直接打开（支持绝对/相对路径）
  if vim.fn.filereadable(file) == 1 then
    vim.cmd.edit({ file, bang = true })
  else
    -- 再在 'path' 里查找
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
