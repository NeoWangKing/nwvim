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

| 文件名 | 用途 | 优先级 |
|---|---|---|
| `10-english-words.txt` | 通用英文词表，370,105 词，**按词频排序** | 1（最高） |
| `20-physics.txt` | 物理专业词表，318 词 | 2 |
| `30-c-computing.txt` | C 语言 / 计算机词表，481 词 | 3 |
| （自己加） | 例如 `40-names.txt`、`50-personal.txt` | 看数字 |

⚠️ **文件名前的数字决定候选优先级**，别随便去掉。

插件用 `globpath(dir, "**/*.txt")` 收集词典，**按文件名排序后拼接**。
而补全的候选顺序就是拼接顺序（见下节「排序规则」），所以：

- 数字小的文件，它的词在前
- `10-english-words.txt` 必须在最前 —— 否则打字 `an` 会先给 `ANSI` 而不是 `and`
- 自己加文件时用中间的数字（比如 `25-mine.txt`）就能插到对应位置

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

### ⚠️ 排序规则（决定补全质量的关键）

虚影补全**只显示第一个候选**，所以「第一个是谁」直接决定体验好不好。
两个因素共同决定它：

**① 词库内部的顺序**

`10-english-words.txt` **按词频从高到低排序**，不是字母序。
字母序会让生僻词和常用词排在同一起跑线：

| 前缀 | 字母序（旧） | 词频序（现在） |
|---|---|---|
| `physi` | physianthropy, physiatric, physiatrical… | physical, physically, physics, physician… |
| `import` | importability, importable, importableness… | important, importance, importantly, imported… |
| `real` | realarm, realer, reales, realestate… | really, real, realize, realized, reality… |
| `beauti` | beautician, beauticians, beautied… | beautiful, beautifully, beauties, beautician… |

重建方式见 `scripts/build-dictionary.py`（会下载词频表、重排、并校验词集合不变）。
词频表覆盖 370,105 词里的 138,753 个（37.5%）；没有词频数据的词保持字母序、
排在所有有词频的词之后。

**② fzf 必须带 `--tiebreak=index`**

这一条同样关键：**fzf 的 `--filter` 默认会按自己的评分重新排序、完全无视输入顺序**
（实测：输入 `reales/realer/reality/really/real`，输出是
`real/reales/realer/really/reality`），`--no-sort` 也无效。
只有 `--tiebreak=index` 能让它保持文件顺序。

**③ 还要绕过插件丢顺序的 bug，并在 blink 层按排名重排**

即使 ① ② 都对（实测 `vim.system` 拦截确认 fzf 返回的就是
`important, importance, importantly, imported, import, imports`），
顺序仍然传不到虚影 —— 因为 `blink-cmp-dictionary` 内部是这样返回候选项的：

```lua
items[match] = { ... }          -- 用字典存
items = vim.tbl_values(items)   -- 取出时变成哈希序，顺序在这一步被销毁
```

所以 `lua/plugins/blink.lua` 里做了两件事把它救回来：

1. 用 `separate_output`（拿到的是**有序**原始输出，且返回类型就是 `any[]`）
   把「行号 = 该前缀下的词频排名」挂到条目上
2. 借 `data.documentation` 这个唯一能透传到 blink item 的字段带出去，
   在 `transform_items` 里写成零填充 `sortText`；
   再把 `fuzzy.sorts` 改成 `{ 'sort_text', 'score' }` 让排名优先于模糊分

三者缺一不可：**少了 ①②，fzf 给的顺序就是错的；少了 ③，正确的顺序会在插件内部丢掉。**

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

`10-english-words.txt` 的词表来自 **[dwyl/english-words](https://github.com/dwyl/english-words)**：

- 文件：`words_alpha.txt`
- 词数：370,105
- 许可证：**Unlicense**（公共领域，可自由分发）
- 内容：全部为纯小写字母的英文单词（不含专有名词）

选它而不是复制 macOS 的 `/usr/share/dict/words`，是因为后者源自韦氏第二版词典，
虽然一般认为已进入公共领域，但来源链不如 Unlicense 明确 ——
这个仓库是公开的，用许可证清晰的来源更稳妥。

文件已做过归一化处理：`CRLF → LF`。

### 排序用的词频表

`10-english-words.txt` 的**顺序**来自
**[hermitdave/FrequencyWords](https://github.com/hermitdave/FrequencyWords)**：

- 文件：`content/2018/en/en_full.txt`
- 规模：165 万行（纯小写词约 103 万个），格式为 `词 频次`
- 许可证：**MIT** —— 和上面一样是许可证清晰的来源
- 用法：**只用来决定顺序，不随仓库分发**（源文件 20MB），
  `scripts/build-dictionary.py` 每次按需下载

> 为什么不选 `first20hours/google-10000-english`：那份用的是 LDC 许可，
> README 里明确写「不建议在未向 LDC 取得授权的情况下用于商业用途」，
> 来源链不如 MIT 干净，且只有 1 万词、覆盖不够。

### 升级 / 重建

词表内容与顺序是两件事，重建顺序只调顺序、**不改词集合**：

```bash
# 1) 升级词表内容（会丢失词频顺序，必须接着做第 2 步）
curl -sL https://cdn.jsdelivr.net/gh/dwyl/english-words@master/words_alpha.txt \
  | tr -d '\r' > ~/.config/nvim/dictionary/10-english-words.txt

# 2) 按词频重排（会下载词频表，跑完自动校验词集合与词数不变）
python3 ~/.config/nvim/scripts/build-dictionary.py

# 只看效果不写文件
python3 ~/.config/nvim/scripts/build-dictionary.py --dry-run
```

（用 jsDelivr 是因为 `raw.githubusercontent.com` 在部分网络下不稳定）

---

## 补全行为

在**写作类文件类型**（markdown / text / tex / gitcommit / mail / rst / asciidoc / org 等）：

- 单词补全以**光标后的暗色虚影文字**出现（ghost text），不弹候选框
- 按 `Tab` 接受，按 `Esc` 或继续输入即可忽略
- ⚠️ **虚影只显示一个候选**（排序第一个，即最常用的那个）。
  如果它猜的不是你要的形态（例如你想用名词 `difference`、它给的是形容词
  `different`），**按 `<C-space>` 调出完整候选列表**再挑。
  这是 `super-tab` 预设里的手动触发键，因为散文下关闭了自动弹框，
  只能手动调出。

在**代码文件类型**：

- 维持原来的候选框补全（LSP / 路径 / 片段 / buffer）
- 词典源**不参与**代码补全，避免英文单词污染代码候选

两种行为的分流逻辑见 `lua/plugins/blink.lua`。
