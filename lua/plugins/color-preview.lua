-- color-preview.lua - 在缓冲区里直接显示 #hex / rgb / hsl 的颜色。
return {
  'brenoprata10/nvim-highlight-colors',
  event = 'VeryLazy',
  opts = {
    render = 'background',
    enable_hex = true,
    enable_short_hex = true,
    enable_rgb = true,
    enable_hsl = true,
    enable_named_colors = false,
    enable_tailwind = false,
  },
}
