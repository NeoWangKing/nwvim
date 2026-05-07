return {
  "folke/snacks.nvim",
  enabled = false,
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 3000,
      style = "compact",
      icons = {
        error = " ",
        warn = " ",
        info = " ",
        debug = " ",
        trace = "󰔡 ",
      },
    },
    dashboard = {
      enabled = true,
      sections = {
        { section = "header" },
        { icon = " ", title = "keymaps", section = "keys", indent = 2, padding = 1 },
        { icon = " ", title = "recent files", section = "recent_files", indent = 2, padding = 1 },
        { icon = " ", title = "projects", section = "projects", indent = 2, padding = 1 },
        {
          icon = " ",
          title = "git status",
          section = "terminal",
          enabled = function()
            return vim.fn.isdirectory(".git") == 1
              or vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null"):match("true") ~= nil
          end,
          cmd = "git status --short --branch --renames",
          height = 5,
          padding = 1,
          ttl = 5 * 60,
          indent = 3,
        },
        { section = "startup" },
      },
    },
    quickfile = { enabled = true },
    picker = { enabled = true },
    zen = { enabled = true },
    statuscolumn = { enabled = false },
    input = {
      enabled = true,
      win = { style = "input", border = "rounded" },
    },
    image = {
      enabled = true,
      env = { name = "wezterm" },
      formats = { "png", "jpg", "jpeg", "gif", "bmp", "webp" },
    },
    lazygit = { enabled = true },
    explorer = { enabled = false },
    animate = { enabled = false },
    dim = { enabled = false },
    gh = { enabled = false },
    gitbrowse = { enabled = false },
    layout = { enabled = false },
    profiler = { enabled = false },
    scope = { enabled = false },
    scroll = { enabled = false },
    terminal = { enabled = false },
    toggle = { enabled = false },
    win = { enabled = false },
    words = { enabled = false },
  },
  config = function(_, opts)
    require("snacks").setup(opts)

    local function toggle_indent(bufnr)
      local ft = vim.bo[bufnr].filetype
      if ft:find("markdown") then
        require("snacks").indent.disable()
      else
        require("snacks").indent.enable()
      end
    end

    -- 当前缓冲区立即执行
    toggle_indent(vim.api.nvim_get_current_buf())

    -- 切换缓冲区时自动切换状态
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      group = vim.api.nvim_create_augroup("SnacksIndentToggle", { clear = true }),
      callback = function(args)
        toggle_indent(args.buf)
      end,
    })
  end,
  keys = {
    { "<leader>ff", function() require("snacks").picker.files() end, desc = "Find Files" },
    { "<leader>fg", function() require("snacks").picker.grep() end, desc = "Grep" },
    { "<leader>fb", function() require("snacks").picker.buffers() end, desc = "Buffers" },
    { "<leader>fh", function() require("snacks").picker.help() end, desc = "Help" },
    { "<leader>e",  function() require("snacks").explorer.open() end, desc = "Explorer" },
    { "<leader>z",  function() require("snacks").zen() end, desc = "Toggle Zen Mode" },
    { "<leader>Z",  function() require("snacks").zen.zoom() end, desc = "Toggle Zoom" },
    { "<F2>",       function() require("snacks").rename.rename_file() end, desc = "Rename File" },
    { "<leader>gg", function() require("snacks").lazygit() end, desc = "Lazygit" },
  },
}
