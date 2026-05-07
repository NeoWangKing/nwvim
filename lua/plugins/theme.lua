-- plugins/theme.lua

-- define your theme name
local active_theme = "gruberdarker"

-- define the config table of theme

local themes = {
    tokyonight = {
        "folke/tokyonight.nvim",
        config = function()
            require("tokyonight").setup({
                style = "night", -- 可选："storm", "night", "moon", "day"
                transparent = true,
                terminal_colors = true,
                lualine_bold = true,
                styles = {
                    comments = { italic = true },
                    keywords = { italic = true },
                    functions = { bold = true },
                    variables = {},
                    sidebars = "transparent",
                    floats = "transparent",
                },
            })
            vim.cmd("colorscheme tokyonight")
        end,
    },

    onedark = {
        "navarasu/onedark.nvim",
        priority = 1000,
        config = function()
            require("onedark").setup({
                style = "warmer",
                transparent = true,
                term_colors = true,
                ending_tildes = false,
                cmp_itemkind_reverse = false,

                code_style = {
                    comments = "italic",
                    keywords = "bold",
                    functions = "bold",
                    strings = "italic",
                    variables = "none",
                },

                lualine = {
                    transparent = false,
                },
            })
            require("onedark").load()
        end,
    },

    onedarkpro = {
        "olimorris/onedarkpro.nvim",
        priority = 1000,

        config = function()
            require("onedarkpro").setup({
                options = {
                    transparency = true,
                },

                styles = {
                    types = "NONE",
                    methods = "NONE",
                    numbers = "NONE",
                    strings = "NONE",
                    comments = "NONE",
                    keywords = "NONE",
                    constants = "NONE",
                    functions = "NONE",
                    operators = "NONE",
                    variables = "NONE",
                    parameters = "NONE",
                    conditionals = "italic",
                    virtual_text = "NONE",
                },
            })

            vim.cmd("colorscheme onedarkpro")
        end,
    },

    gruberdarker = {
      "blazkowolf/gruber-darker.nvim",
      lazy = false,
      priority = 1000,
      config = function()
        vim.cmd.colorscheme("gruber-darker")
        -- 移除 Normal 高亮组的背景色，实现透明效果
        -- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
        -- vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" }) -- 非当前窗口也透明
      end,
    },
}

return themes[active_theme]

