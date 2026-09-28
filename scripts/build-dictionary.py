#!/usr/bin/env python3
"""
按词频重排英文词库，让补全的「第一个候选」是常用词而不是生僻词。

## 为什么需要它

blink-cmp-dictionary 用 fzf 做前缀过滤，而虚影补全（ghost text）只显示
**第一个**候选。词库原本是按字母序排的，于是生僻/古旧变形和常用词排在同
一起跑线甚至更前：

    前缀 real   → real, realarm, realer, reales, realest, realestate, realgar ...
    前缀 physi  → physianthropy, physiatric, physiatrical, physiatrics ...
    前缀 import → import, importability, importable, importableness ...

重排后：

    前缀 real   → really, real, realize, realized, reality, realm ...
    前缀 physi  → physical, physically, physics, physician, physicist ...
    前缀 import → important, importance, importantly, imported ...

## 两个约束

1. **fzf 必须加 `--tiebreak=index`**（见 lua/plugins/blink.lua）。
   fzf 的 `--filter` 默认会按自己的评分重新排序，**无视输入顺序**，
   所以光重排文件是没用的。`--tiebreak=index` 才能让它保持文件顺序。

2. **文件名的数字前缀决定候选优先级**（插件用 globpath 按文件名排序拼接）。
   `10-english-words.txt` 必须排在领域词表之前，否则打字 "an" 会先给
   `ANSI` 而不是 `and`。

## 用法

    python3 scripts/build-dictionary.py                # 下载词频表并重排
    python3 scripts/build-dictionary.py --dry-run      # 只看前后对比，不写文件
    python3 scripts/build-dictionary.py --keep-cache   # 保留下载的词频表

词频表不随仓库分发（20MB），脚本每次按需下载。换成别的词频源时，
只要保持「每行 `词 频次`」的格式即可。
"""

import argparse
import re
import sys
import urllib.request
from pathlib import Path

# MIT 许可（见 dictionary/README.md 的许可证说明）。
# 为什么不选 first20hours/google-10000-english：那份用 LDC 许可，
# 明确「不建议商用」，来源没这份干净。
FREQ_URL = (
    "https://cdn.jsdelivr.net/gh/hermitdave/FrequencyWords@master"
    "/content/2018/en/en_full.txt"
)

REPO = Path(__file__).resolve().parent.parent
DICT = REPO / "dictionary"
TARGET = DICT / "10-english-words.txt"
CACHE = Path("/tmp/en_full.txt")

# 只保留纯小写字母，与 english-words 的格式保持一致
WORD_RE = re.compile(r"^[a-z]+$")


def fetch_freq(keep_cache: bool) -> dict[str, int]:
    if not CACHE.exists():
        print(f"下载词频表 {FREQ_URL}")
        try:
            urllib.request.urlretrieve(FREQ_URL, CACHE)
        except Exception as e:  # noqa: BLE001
            sys.exit(f"下载失败: {e}\n可以手动下载后放到 {CACHE}")
        print(f"  已保存到 {CACHE} ({CACHE.stat().st_size / 1e6:.1f} MB)")
    else:
        print(f"复用已缓存的 {CACHE}")

    freq: dict[str, int] = {}
    with CACHE.open(encoding="utf-8", errors="replace") as f:
        for line in f:
            w, _, c = line.rstrip("\n").rpartition(" ")
            if not w or not WORD_RE.match(w):
                continue
            try:
                n = int(c)
            except ValueError:
                continue
            if n > freq.get(w, 0):
                freq[w] = n
    print(f"  词频表解析出 {len(freq):,} 个纯小写词")

    if not keep_cache:
        CACHE.unlink(missing_ok=True)
    return freq


def reorder(words: list[str], freq: dict[str, int]) -> list[str]:
    """有词频的按频次降序；没有词频的保持原字母序追加在后面。

    保持「词集合完全不变」——只调顺序，不动内容，
    所以跨文件去重规则（english-words > c-computing > physics）不受影响。
    """
    with_freq = sorted((w for w in words if w in freq), key=lambda w: -freq[w])
    without = [w for w in words if w not in freq]
    return with_freq + without


def preview(prefixes: list[str], before: list[str], after: list[str], n: int = 8) -> None:
    def top(lst: list[str], p: str) -> str:
        matches = [w for w in lst if w.startswith(p)]
        return " ".join(matches[:n])

    print()
    print(f"{'前缀':<9}{'重排前':<48}{'重排后'}")
    print("-" * 126)
    for p in prefixes:
        print(f"{p:<9}{top(before, p):<48}{top(after, p)}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="只预览，不写文件")
    ap.add_argument("--keep-cache", action="store_true", help="保留下载的词频表")
    ap.add_argument("--source", type=Path, default=None,
                    help="要重排的文件（默认 dictionary/10-english-words.txt）")
    args = ap.parse_args()

    src = args.source or TARGET
    if not src.exists():
        # 兼容重命名之前的旧文件名
        legacy = DICT / "english-words.txt"
        if legacy.exists():
            src = legacy
        else:
            sys.exit(f"找不到词库文件: {src}")

    words = [l.strip() for l in src.read_text(encoding="utf-8").splitlines() if l.strip()]
    print(f"词库 {src.name}: {len(words):,} 词")

    freq = fetch_freq(args.keep_cache)
    known = sum(1 for w in words if w in freq)
    print(f"  有词频数据的: {known:,} ({known / len(words) * 100:.1f}%)")

    after = reorder(words, freq)
    assert sorted(after) == sorted(words), "重排改变了词集合，这是 bug"
    assert len(after) == len(words), "重排改变了词数，这是 bug"
    print(f"  重排完成，词集合与词数均未变（已校验）")

    preview(
        ["real", "differ", "quick", "success", "beauti", "nation", "import", "physi"],
        words,
        after,
    )

    if args.dry_run:
        print("\n--dry-run：未写入文件")
        return

    if src != TARGET:
        src.rename(TARGET)
        print(f"\n已重命名为 {TARGET.name}")
    TARGET.write_text("\n".join(after) + "\n", encoding="utf-8")
    print(f"已写入 {TARGET} ({TARGET.stat().st_size / 1e6:.1f} MB)")
    print("\n提醒：blink.lua 的 fzf 参数必须带 --tiebreak=index，否则 fzf 会重排，白改。")


if __name__ == "__main__":
    main()
