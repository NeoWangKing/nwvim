-- check-palette.lua - 检查 colors/p3-blue.lua 有没有引用未定义的调色板键。
-- 用法：nvim --headless -u NONE -c "luafile scripts/check-palette.lua" -c "qa!" 2>&1

local self = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(self, ":h:h")
local path = root .. "/colors/p3-blue.lua"

local ok, lines = pcall(vim.fn.readfile, path)
if not ok or type(lines) ~= "table" or #lines == 0 then
  io.stdout:write("无法读取 " .. path .. "\n")
  vim.cmd("cq")  -- 以非零状态退出，方便接进 CI / 钩子
end
local src = table.concat(lines, "\n")

-- 先剥掉注释，否则注释里提到的键名会被误算成引用
local code = src:gsub("%-%-%[%[.-%]%]%]", ""):gsub("%-%-[^\n]*", "")

local pal = code:match("\nlocal p = {(.-)\n}")
if not pal then
  io.stdout:write("解析失败：在 " .. path .. " 里找不到 `local p = {` 调色板区块\n")
  vim.cmd("cq")
end

local defined, used = {}, {}
for k in pal:gmatch("\n[ \t]*([a-z_]+)[ \t]*=") do defined[k] = true end

-- p.xxx 前面必须不是字母/数字/下划线，否则 @markup.heading 这类捕获名会误报
for k in code:gmatch("[^%w_]p%.([a-z_]+)") do used[k] = true end

local missing, unused = {}, {}
for k in pairs(used) do
  if not defined[k] then missing[#missing + 1] = k end
end
for k in pairs(defined) do
  if not used[k] then unused[#unused + 1] = k end
end
table.sort(missing)
table.sort(unused)

io.stdout:write(string.format("调色板：定义 %d 个键，引用 %d 个键\n",
  vim.tbl_count(defined), vim.tbl_count(used)))

if #missing == 0 then
  io.stdout:write("✓ 没有未定义的调色板键\n")
else
  io.stdout:write("✗ 未定义的键（会被 `or` 掩盖成静默降级）: "
    .. table.concat(missing, ", ") .. "\n")
end

-- 未引用的键只是提示，可能是为将来预留的
io.stdout:write("· 未被引用的键: " .. (#unused > 0 and table.concat(unused, ", ") or "无") .. "\n")

if #missing > 0 then
  vim.cmd("cq")
end
