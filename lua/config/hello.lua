-- hello.lua - :SayHello 的实现：往「空文件」里写一份最简的 Hello, world! 模板，
-- 并把对应的「最小可运行命令」一起提示出来。
--
-- 语言由当前 buffer 的 filetype 决定（filetype 认不出时按文件名再猜一次），
-- 只在「认得的语言 + 缓冲区里除了空白什么都没有」时才动手，其余情况明确说明为什么没写。
-- 命令注册在 lua/config/commands.lua。
--
-- 模板写成 Lua 长字符串（[[...]]），好处是它在源码里和在文件里的样子完全一致：
-- 不用转义 \n，也不用把每行拆成数组元素。因此**模板正文必须顶格写** ——
-- 缩进会被当成文件内容。内容缩进按各语言惯例（C 系 4 空格，JS 系 2 空格……）。
--
-- 每个模板都只求「刚好能编译/运行、打印一行 Hello, world!」，用来确认工具链正常。
local P = require("config.platform")

local M = {}

-- 每个语言的「最小可运行命令」：只写最朴素的那一条，不用 cargo / gradle / 项目脚手架。
-- 占位符（由 M.render_command 替换）：
--   {file}   文件路径（相对当前目录，跨目录时也是对的）
--   {stem}   去掉扩展名的文件名，用作编译产物名
--   {bin}    编译产物怎么运行：./main 或 .\main.exe（平台差异在 platform.CMD 里）
--   {py}     python 命令名（Windows 上是 python）
--   {opener} 打开文件的命令名（html 用）
M.commands = {
  -- C 系 / 系统语言
  c = "gcc {file} -o {stem} && {bin}",
  cpp = "g++ {file} -o {stem} && {bin}",
  rust = "rustc {file} -o {stem} && {bin}",
  go = "go run {file}",
  java = "java {file}",
  cs = "dotnet run {file}",
  kotlin = "kotlinc {file} -include-runtime -d {stem}.jar && java -jar {stem}.jar",
  swift = "swift {file}",
  dart = "dart run {file}",
  scala = "scala {file}",
  haskell = "runghc {file}",

  -- 脚本语言
  python = "{py} {file}",
  lua = "lua {file}",
  vim = "nvim -u NONE -S {file}",
  bash = "bash {file}",
  sh = "sh {file}",
  zsh = "zsh {file}",
  perl = "perl {file}",
  php = "php {file}",
  ruby = "ruby {file}",
  r = "Rscript {file}",
  julia = "julia {file}",
  elixir = "elixir {file}",
  gnuplot = "gnuplot {file}",

  -- JS / TS（Node 22.18+ 起可以直跑 .ts）
  javascript = "node {file}",
  javascriptreact = "node {file}",
  typescript = "node {file}",
  typescriptreact = "node {file}",

  -- 排版
  html = "{opener} {file}",
  plaintex = "pdflatex {file}", -- 中文文档要换 xelatex
}

M.templates = {
  -- ── C 系 ────────────────────────────────────────────────────────────
  c = [[
#include <stdio.h>

int main() {
    printf("Hello, world!\n");
    return 0;
}
]],

  cpp = [[
#include <iostream>

int main() {
    std::cout << "Hello, world!" << std::endl;
    return 0;
}
]],

  -- ── 脚本语言 ────────────────────────────────────────────────────────
  python = [[
print("Hello, world!")
]],

  lua = [[
print("Hello, world!")
]],

  vim = [[
echo "Hello, world!"
]],

  bash = [[
#!/usr/bin/env bash

echo "Hello, world!"
]],

  sh = [[
#!/bin/sh

echo "Hello, world!"
]],

  zsh = [[
#!/usr/bin/env zsh

echo "Hello, world!"
]],

  perl = [[
#!/usr/bin/env perl

print "Hello, world!\n";
]],

  php = [[
<?php

echo "Hello, world!\n";
]],

  ruby = [[
puts "Hello, world!"
]],

  r = [[
cat("Hello, world!\n")
]],

  julia = [[
println("Hello, world!")
]],

  elixir = [[
IO.puts("Hello, world!")
]],

  gnuplot = [[
print "Hello, world!"
]],

  -- ── JS / TS ────────────────────────────────────────────────────────
  javascript = [[
console.log("Hello, world!");
]],

  javascriptreact = [[
console.log("Hello, world!");
]],

  typescript = [[
console.log("Hello, world!");
]],

  typescriptreact = [[
console.log("Hello, world!");
]],

  -- ── 编译型 / JVM ────────────────────────────────────────────────────
  java = [[
// 故意不写 public：这样文件叫 main.java 也能编译
class Main {
    public static void main(String[] args) {
        System.out.println("Hello, world!");
    }
}
]],

  go = [[
package main

import "fmt"

func main() {
    fmt.Println("Hello, world!")
}
]],

  rust = [[
fn main() {
    println!("Hello, world!");
}
]],

  kotlin = [[
fun main() {
    println("Hello, world!")
}
]],

  swift = [[
print("Hello, world!")
]],

  dart = [[
void main() {
  print('Hello, world!');
}
]],

  scala = [[
@main def hello(): Unit = println("Hello, world!")
]],

  cs = [[
using System;

class Program {
    static void Main() {
        Console.WriteLine("Hello, world!");
    }
}
]],

  haskell = [[
main :: IO ()
main = putStrLn "Hello, world!"
]],

  -- ── 排版 ────────────────────────────────────────────────────────────
  html = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Hello, world!</title>
</head>
<body>
    Hello, world!
</body>
</html>
]],

  -- nvim 把 .tex 识别成 plaintex（不是 tex），所以键名按它的来
  plaintex = [[
\documentclass{article}

\begin{document}

Hello, world!

\end{document}
]],
}

-- 别名：语言名和 nvim 的 filetype 名不一致时写在这里
-- （.tex → plaintex、C# → cs；这样 :SayHello tex / :SayHello csharp 也能用，
--   而同一份模板不用写两遍）
M.aliases = {
  tex = "plaintex",
  csharp = "cs",
}

---支持的 filetype 列表（给命令补全和报错用），按字母序
---@return string[]
function M.supported()
  local list = vim.tbl_keys(M.templates)
  vim.list_extend(list, vim.tbl_keys(M.aliases))
  table.sort(list)
  return list
end

---把别名解析成真正的模板键
---@param lang string
---@return string
local function canonical(lang)
  return M.aliases[lang] or lang
end

---把「最小可运行命令」里的占位符换成当前 buffer 的实际值
---@param lang string
---@param frags? table 平台片段；默认取 platform.CMD，传参覆盖便于测试
---@return string? cmd 缓冲区还没有文件名（:enew 后没存盘）时返回 nil
function M.render_command(lang, frags)
  local tpl = M.commands[canonical(lang)]
  if not tpl then return nil end

  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then return nil end

  local file = vim.fn.fnamemodify(name, ":.")
  local stem = vim.fn.fnamemodify(name, ":t:r")
  frags = vim.tbl_deep_extend("force", P.CMD, frags or {})

  return (tpl:gsub("{(%w+)}", function(key)
    if key == "file" then return file end
    if key == "stem" then return stem end
    if key == "bin" then return frags.bin_prefix .. stem .. frags.exe_suffix end
    if key == "py" then return frags.python end
    if key == "opener" then return frags.opener end
    -- 未知占位符原样留着，写错了能一眼看出来
    return "{" .. key .. "}"
  end))
end

---长字符串 → 行数组。
---Lua 会吃掉 `[[` 紧跟的那个换行，所以这里只需要丢掉结尾多出来的那个空行。
---@param text string
---@return string[]
local function to_lines(text)
  local lines = vim.split(text, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

---缓冲区里除了空白什么都没有（新文件、或把内容删光了都算）
---@param bufnr integer
---@return boolean
local function is_blank(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    if line:match("%S") then return false end
  end
  return true
end

---按当前 buffer 判断语言
---@return string? lang
---@return string ft 当前 filetype（认不出时用它来报错）
local function resolve_language()
  local ft = vim.bo.filetype
  if M.templates[canonical(ft)] then return canonical(ft), ft end

  -- filetype 没设或不认识时按文件名再猜一次（例如 :enew 出来的空 buffer 另存为新名字）
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" then
    local ok, guessed = pcall(vim.filetype.match, { buf = 0, filename = name })
    if ok and guessed and M.templates[canonical(guessed)] then return canonical(guessed), ft end
  end

  return nil, ft
end

---写模板。arg 为空时按当前文件判断语言。
---@param arg? string 显式指定的语言（filetype 名）
function M.say_hello(arg)
  local bufnr = vim.api.nvim_get_current_buf()

  local buftype = vim.bo[bufnr].buftype
  if buftype ~= "" then
    vim.notify(":SayHello 只能用在普通文件缓冲区（当前是 " .. buftype .. "）", vim.log.levels.WARN)
    return
  end

  if not is_blank(bufnr) then
    vim.notify("当前文件不是空的 —— :SayHello 只往空文件里写模板", vim.log.levels.WARN)
    return
  end

  local lang
  if arg and arg ~= "" then
    if not M.templates[canonical(arg)] then
      vim.notify(
        string.format("没有 \"%s\" 的模板。支持：%s", arg, table.concat(M.supported(), " ")),
        vim.log.levels.WARN
      )
      return
    end
    lang = canonical(arg)
  else
    local ft
    lang, ft = resolve_language()
    if not lang then
      vim.notify(
        (ft ~= "" and ("没有 \"" .. ft .. "\" 的模板") or "这个缓冲区没有文件类型，认不出语言")
          .. "。可以显式指定：:SayHello python，或先 :setfiletype python",
        vim.log.levels.WARN
      )
      return
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, to_lines(M.templates[lang]))

  -- 语言是显式指定的、或原 filetype 不匹配时顺手设上，免得没有高亮/缩进
  if vim.bo[bufnr].filetype ~= lang then
    vim.bo[bufnr].filetype = lang
  end

  -- 顺带把「最小可运行命令」提示出来，省得每次还要想一下怎么编译 / 怎么跑。
  local msg = string.format("已写入 %s 的 Hello, world! 模板（u 可撤销）", lang)
  local cmd = M.render_command(lang)
  if cmd then
    -- 带 && 的说明要先编译再运行；解释型语言一条就是运行
    msg = msg .. "\n" .. (cmd:find("&&", 1, true) and "编译运行：" or "运行：") .. cmd
  else
    msg = msg .. "\n（文件存盘后，这里会给出运行命令）"
  end
  vim.notify(msg, vim.log.levels.INFO)
end

return M
