-- scripts/check-palette.lua
--
-- 用途：检查 colors/p3-blue.lua 里有没有「引用了但没定义」的调色板键。
--
-- 为什么需要这个检查：
--   本仓库出现过两次真实事故——写 `p.fg_ghost or p.border` 时 fg_ghost 从未定义，
--   Lua 的 `or` 会静默取后面的值，于是虚影文字退化成边框色 #3E434A（对比度仅
--   1.37:1），肉眼几乎看不见，而且不报任何错。
--   这类 bug 只能靠静态扫描兜住。
--
-- 用法（在仓库任意位置）：
--   nvim --headless -u NONE -c "luafile scripts/check-palette.lua" -c "qa!" 2>&1
--
-- 退出表现：有未定义键时输出 ✗ 并列出键名；全部正常时输出 ✓。

local self = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(self, ":h:h")
local path = root .. "/colors/p3-blue.lua"

local ok, lines = pcall(vim.fn.readfile, path)
if not ok or type(lines) ~= "table" or #lines == 0 then
  io.stdout:write("无法读取 " .. path .. "\n")
  vim.cmd("cq")  -- 以非零状态退出，方便接进 CI / 钩子
end
local src = table.concat(lines, "\n")

-- 先剥掉块注释和行注释。
-- 否则注释里提到的键名（包括本文件顶部这段说明本身）会被误算成「引用」。
local code = src:gsub("%-%-%[%[.-%]%]%]", ""):gsub("%-%-[^\n]*", "")

local pal = code:match("\nlocal p = {(.-)\n}")
if not pal then
  io.stdout:write("解析失败：在 " .. path .. " 里找不到 `local p = {` 调色板区块\n")
  vim.cmd("cq")
end

local defined, used = {}, {}
for k in pal:gmatch("\n[ \t]*([a-z_]+)[ \t]*=") do defined[k] = true end

-- 关键细节：p.xxx 前面必须不是字母/数字/下划线。
-- 否则 treesitter 的捕获名 `@markup.heading` 会被匹配成 `p.heading` 而产生大量误报。
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

-- 未被引用的键只是提示，不一定是问题（可能是为将来预留的）
io.stdout:write("· 未被引用的键: " .. (#unused > 0 and table.concat(unused, ", ") or "无") .. "\n")

if #missing > 0 then
  vim.cmd("cq")
end
