# 词典目录

这个目录里的**所有 `.txt` 文件**都会被当作英文词典，供 Neovim 写作时的单词补全使用
（通过 `blink-cmp-dictionary` 插件，配置见 `lua/plugins/blink.lua`）。

放在仓库里的好处：macOS / Linux / Windows 三端共用同一份词典 ——
Windows 本身没有系统词典，只有 macOS/Linux 才有 `/usr/share/dict/`。

---

## 文件格式

**一行一个单词**，纯小写字母即可：

```
apple
banana
cherry
```

两个必须注意的细节：

1. **行尾必须是 `LF`，不能是 `CRLF`。**
   带 `\r` 的话，补全插进去的单词末尾会多一个隐形字符。
   如果你在 Windows 上用编辑器保存过，检查一下：
   ```bash
   tr -cd '\r' < 你的文件.txt | wc -c    # 输出 0 才正常
   ```
   修正：`tr -d '\r' < 原文件.txt > 新文件.txt`

2. **不要用 `#` 写注释行。**
   `#` 开头的那一行会被当成一个「单词」出现在候选里。
   要写说明就写在 `.md` 文件里（本文件就是），不要写进 `.txt`。

---

## 怎么加自己的词典

直接往这个目录里丢新的 `.txt` 文件即可，重启 Neovim 生效。

按用途分开建文件比较好维护，例如：

| 文件名 | 用途 |
|---|---|
| `english-words.txt` | 通用英文词表，370,105 词（见文末来源） |
| `physics.txt` | 物理专业词表，318 词 |
| `c-computing.txt` | C 语言 / 计算机词表，481 词 |
| （自己加） | 例如 `names.txt`、`personal.txt` |

### 领域词表为什么「只留了几百词」

这两份词表初稿各有 400+ 条，但生成时**逐条与 `english-words.txt` 比对去重**，
物理被剔掉 246 条、计算机被剔掉 47 条 —— 因为 `momentum`、`entropy`、
`eigenvalue`、`pointer`、`algorithm` 这类小写词，37 万词的通用表里本来就有，
再加一遍只会产生重复候选。

**留下的正是通用表里真正缺失的部分**：

| 类型 | 例子 |
|---|---|
| 专有名词 | `Newton` `Feynman` `Schrodinger` `Linux` `Python` |
| 全大写缩写 | `CPU` `GPU` `JSON` `eV` `MeV` `QED` `LSP` |
| 带下划线的标识符 | `size_t` `uint32_t` `pthread_create` |
| 连字符复合词 | `phase-transition` `big-O` `binding-energy` |

（通用词表全部是小写字母，所以上面这些天然不冲突。你的 `iskeyword` 里包含
`-` 和 `_`，因此带连字符/下划线的词也能被正常补全。）

### ⚠️ 重复词会变成重复候选

插件是把目录里所有文件**拼在一起**的，**不会去重**。
如果两个文件里有同一个词，候选列表里就会出现两条一样的。
所以：

- 自己加的文件里，**只放已有词表里没有的词**（专有名词、技术缩写、中文拼音等）
- 或者干脆把不需要的词表删掉/改名（改成 `.txt.bak` 就不会被读取）

检查某个词是否已存在（三份表一起查）：
```bash
grep -x "yourword" ~/.config/nvim/dictionary/*.txt
```

**跨文件去重规则**：`english-words` > `c-computing` > `physics`。
目前只有一处冲突 —— `Pascal` 既是编程语言也是物理学家/压强单位，
按规则归到 `c-computing.txt`。词本身仍然能补全，从哪个文件来对使用没有影响。

---

## 内置词表的来源

`english-words.txt` 来自 **[dwyl/english-words](https://github.com/dwyl/english-words)**：

- 文件：`words_alpha.txt`
- 词数：370,105
- 许可证：**Unlicense**（公共领域，可自由分发）
- 内容：全部为纯小写字母的英文单词（不含专有名词）

选它而不是复制 macOS 的 `/usr/share/dict/words`，是因为后者源自韦氏第二版词典，
虽然一般认为已进入公共领域，但来源链不如 Unlicense 明确 ——
这个仓库是公开的，用许可证清晰的来源更稳妥。

文件已做过归一化处理：`CRLF → LF`。

想升级词表：
```bash
curl -sL https://cdn.jsdelivr.net/gh/dwyl/english-words@master/words_alpha.txt \
  | tr -d '\r' > ~/.config/nvim/dictionary/english-words.txt
```
（用 jsDelivr 是因为 `raw.githubusercontent.com` 在部分网络下不稳定）

---

## 补全行为

在**写作类文件类型**（markdown / text / tex / gitcommit / mail / rst / asciidoc / org 等）：

- 单词补全以**光标后的暗色虚影文字**出现（ghost text），不弹候选框
- 按 `Tab` 接受，按 `Esc` 或继续输入即可忽略

在**代码文件类型**：

- 维持原来的候选框补全（LSP / 路径 / 片段 / buffer）
- 词典源**不参与**代码补全，避免英文单词污染代码候选

两种行为的分流逻辑见 `lua/plugins/blink.lua`。
