-- init.lua
require('vim._core.ui2').enable({})
-- 入口文件：只负责加载顺序，不包含具体配置
vim.env.PATH = vim.fn.expand("$HOME/.nvm/version/node/v20.20.2/bin") .. ":" .. vim.env.PATH

vim.g.start_time = vim.loop.hrtime()
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.autocmds")
require("config.keymaps")
require("config.commands")
require("config.lazy")
require("config.neovide")
