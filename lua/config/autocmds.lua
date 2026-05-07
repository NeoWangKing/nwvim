-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)

local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- ============================================================================
-- Format on save (only when efm is attached)
-- ============================================================================
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  pattern = {
    "*.lua", "*.py", "*.go", "*.js", "*.jsx", "*.ts", "*.tsx",
    "*.json", "*.css", "*.scss", "*.html", "*.sh", "*.bash", "*.zsh",
    "*.c", "*.cpp", "*.h", "*.hpp",
  },
  callback = function(args)
    -- skip non-file / non-modifiable buffers
    if vim.bo[args.buf].buftype ~= "" or not vim.bo[args.buf].modifiable then return end
    if vim.api.nvim_buf_get_name(args.buf) == "" then return end

    -- only format if efm is attached
    local has_efm = false
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
      if client.name == "efm" then
        has_efm = true
        break
      end
    end
    if not has_efm then return end

    pcall(vim.lsp.buf.format, {
      bufnr = args.buf,
      timeout_ms = 2000,
      filter = function(c) return c.name == "efm" end,
    })
  end,
})

-- ============================================================================
-- Smart Indent (merged groups)
-- ============================================================================
-- 4 spaces
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "c", "cpp", "python", "json" },
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.softtabstop = 4
    vim.bo.expandtab = true
  end,
})

-- 2 spaces for markdown
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "markdown",
  callback = function()
    vim.bo.tabstop = 3
    vim.bo.shiftwidth = 3
    vim.bo.softtabstop = 3
    vim.bo.expandtab = true
  end,
})

-- ============================================================================
-- Highlight yanked text
-- ============================================================================
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.hl.on_yank()
  end,
})

-- ============================================================================
-- Restore last cursor position
-- ============================================================================
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function()
    if vim.o.diff then return end
    local last_pos = vim.api.nvim_buf_get_mark(0, '"')
    local last_line = vim.api.nvim_buf_line_count(0)
    if last_pos[1] < 1 or last_pos[1] > last_line then return end
    pcall(vim.api.nvim_win_set_cursor, 0, last_pos)
  end,
})

-- ============================================================================
-- Soft wrap, linebreak and disable spell for markdown / text / gitcommit
-- (spell disabled to avoid false positives with Chinese characters)
-- ============================================================================
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = false
  end,
})

-- ============================================================================
-- Inject TeX syntax into Markdown (for vimtex math zone detection)
-- ============================================================================
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup,
  pattern = "*.md",
  command = "runtime! syntax/tex.vim",
})

-- ============================================================================
-- Smart LaTeX auto‑compile (macOS 适配)
-- ============================================================================
vim.g.tex_auto_compile = true
vim.g.tex_compiler = "/Library/TeX/texbin/pdflatex"  -- 显式指定编译器路径
vim.g.tex_compile_confirm = false

vim.api.nvim_create_autocmd("BufWritePost", {
  group = augroup,
  pattern = "*.tex",
  callback = function(args)
    if not vim.g.tex_auto_compile then return end
    if vim.bo[args.buf].buftype ~= "" then return end

    local filename = vim.fn.expand("%:t")
    local dir = vim.fn.expand("%:p:h")
    local compiler = vim.g.tex_compiler or "/Library/TeX/texbin/pdflatex"

    -- check compiler exists
    if vim.fn.executable(compiler) == 0 then
      print("Compiler not found: " .. compiler)
      return
    end

    local function do_compile()
      print("Compiling " .. filename .. " with " .. compiler .. " …")
      local cmd = string.format('cd "%s" && %s -interaction=nonstopmode "%s"', dir, compiler, filename)
      vim.fn.jobstart(cmd, {
        detach = true,
        on_exit = function(_, exit_code)
          if exit_code == 0 then
            print("✓ Compilation successful: " .. filename:gsub("%.tex$", ".pdf"))
          else
            print("✗ Compilation failed (exit code: " .. exit_code .. ")")
          end
        end,
      })
    end

    if vim.g.tex_compile_confirm then
      local choice = vim.fn.confirm("Compile " .. filename .. " ?", "&Yes\n&No", 1)
      if choice == 1 then do_compile() end
    else
      do_compile()
    end
  end,
})

-- Toggle LaTeX auto-compile
vim.keymap.set("n", "<leader>lt", function()
  vim.g.tex_auto_compile = not vim.g.tex_auto_compile
  print("LaTeX auto-compile: " .. (vim.g.tex_auto_compile and "ON" or "OFF"))
end, { desc = "Toggle LaTeX auto-compile" })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.fs",
  callback = function()
    local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
    -- 如果文件第一行是 #version 330 这类 GLSL 标志，就按 GLSL 处理
    if first_line and first_line:find("#version") then
      vim.bo.filetype = "glsl"
      return
    end

    -- 也可以检查前几行，这里为了保险只快速扫描前10行
    local lines = vim.api.nvim_buf_get_lines(0, 0, 10, false)
    for _, line in ipairs(lines) do
      if line:find("void main") or line:find("gl_FragCoord") then
        vim.bo.filetype = "glsl"
        return
      end
    end
    -- 没有匹配的，让 Neovim 按其他默认规则处理，通常是 F#
  end,
})

-- vim.api.nvim_create_autocmd('ModeChanged', {
--   pattern = '*',
--   callback = function()
--     if ((vim.v.event.old_mode == 's' and vim.v.event.new_mode == 'n') or vim.v.event.old_mode == 'i') 
--       and require('luasnip').session.current_nodes[vim.api.nvim_get_current_buf()] 
--       and not require('luasnip').session.jump_active then
--       require('luasnip').unlink_current()
--     end
--   end
-- })
