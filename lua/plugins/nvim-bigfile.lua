return {
  "ouuan/nvim-bigfile",
  opts = {
    size_limit = 1.5 * 1024 * 1024, -- 1.5MB，单位是字节
    -- 可以针对特定文件类型设置大小限制，比如 ft_size_limits = { markdown = 1024 * 1024 }
  },
}
