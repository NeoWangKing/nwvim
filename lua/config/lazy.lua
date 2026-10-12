local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

-- 把 lazy 加进 runtimepath
vim.opt.rtp:prepend(lazypath)

-- 插件拉取协议（SSH/HTTPS）由 config/platform.lua 探测并缓存；要强制就在 init.lua 设 vim.g.git_protocol。
local url_format = require("config.platform").git_url_format()

local lazy_opts = {
  spec = {
    -- { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- 插件 spec 都在 lua/plugins/
    { import = "plugins" },
  },
  rocks = {
    enabled = false,
    hererocks = false,
  },
}
if url_format then
  lazy_opts.git = { url_format = url_format }
end

require("lazy").setup(lazy_opts)
