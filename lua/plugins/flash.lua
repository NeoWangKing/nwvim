return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type table   -- 通用类型，避免未定义警告
    opts = {},
    keys = {
      {
        "zk",
        mode = { "n", "x", "o" },
        function() require("flash").jump() end,
        desc = "Flash Jump",
      },
      {
        "Zk",
        mode = { "n", "x", "o" },
        function() require("flash").treesitter() end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function() require("flash").remote() end,
        desc = "Remote Flash",
      },
      {
        "R",
        mode = { "o", "x" },
        function() require("flash").treesitter_search() end,
        desc = "Treesitter Search",
      },
      {
        "<c-s>",
        mode = "c",
        function() require("flash").toggle() end,
        desc = "Toggle Flash Search",
      },
    },
  },
}
