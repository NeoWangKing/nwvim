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

-- Put lazy into the runtimepath for neovim!
vim.opt.rtp:prepend(lazypath)

-- ── 拉取协议：自动在 SSH / HTTPS 之间选 ─────────────────────────────────
-- 判定逻辑在 config/platform.lua 的 git_url_format()：
--   有 SSH 私钥 且 实测能通过 GitHub 认证  → 走 SSH（更快，且不受 HTTPS 代理影响）
--   22 端口不通但 ssh.github.com:443 通    → 走 SSH over 443
--   其余                                   → HTTPS（默认，无需任何密钥配置）
--
-- 探测结果缓存在 stdpath("state")/gitproto，只做一次。
-- 想强制指定：在 init.lua 里写 vim.g.git_protocol = "ssh" / "https" / "ssh443"
local url_format = require("config.platform").git_url_format()

local lazy_opts = {
  spec = {
    -- { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import/override with your plugins
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
