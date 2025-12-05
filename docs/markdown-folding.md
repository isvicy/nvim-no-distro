# Markdown Folding 功能设计文档

## 概述

基于 Treesitter 的 Markdown 标题折叠功能，能够精准识别代码块，避免将代码块内的 `#` 注释误判为标题。

## 问题背景

传统的基于正则的 Markdown 折叠会将代码块内的内容也当作标题处理：

```markdown
## 这是真正的标题

​```bash
# 这是代码注释，不应该被折叠
echo "hello"
​```
```

上面代码块中的 `# 这是代码注释` 会被错误识别为 H1 标题。

## 解决方案

使用 Treesitter 预先解析文档，缓存所有 `fenced_code_block` 节点的行范围，在 `foldexpr` 中通过简单的范围查找判断当前行是否在代码块内。

## 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                     FileType markdown                        │
│                            │                                 │
│                            ▼                                 │
│              ┌─────────────────────────┐                    │
│              │  set_markdown_folding() │                    │
│              └─────────────────────────┘                    │
│                            │                                 │
│              ┌─────────────┴─────────────┐                  │
│              ▼                           ▼                  │
│  ┌───────────────────────┐   ┌──────────────────────┐      │
│  │ build_code_block_ranges│   │ detect frontmatter   │      │
│  │  (Treesitter Query)   │   │  (vim.b.frontmatter_end)    │
│  └───────────────────────┘   └──────────────────────┘      │
│              │                                               │
│              ▼                                               │
│  ┌───────────────────────┐                                  │
│  │ vim.b.code_block_ranges│  ← 缓存代码块范围               │
│  │ [{start, end}, ...]   │                                  │
│  └───────────────────────┘                                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Fold Expression                           │
│                            │                                 │
│                            ▼                                 │
│              ┌─────────────────────────┐                    │
│              │  markdown_foldexpr()    │                    │
│              └─────────────────────────┘                    │
│                            │                                 │
│              ┌─────────────┴─────────────┐                  │
│              ▼                           ▼                  │
│  ┌───────────────────────┐   ┌──────────────────────┐      │
│  │is_in_code_block_cached│   │  heading pattern     │      │
│  │  (O(n) range lookup)  │   │  match: ^(#+)\s      │      │
│  └───────────────────────┘   └──────────────────────┘      │
│              │                           │                  │
│              ▼                           ▼                  │
│         在代码块内?                   是标题?               │
│         返回 "="                   返回 ">level"           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 核心函数

### `build_code_block_ranges(bufnr)`

使用 Treesitter 查询获取所有代码块的行范围。

```lua
-- Treesitter Query
(fenced_code_block) @block
```

返回值示例：
```lua
{ {15, 26}, {84, 99}, {108, 117} }  -- 每个元素是 {起始行, 结束行}
```

### `is_in_code_block_cached(lnum)`

O(n) 复杂度的范围查找，判断行号是否在任一代码块内。

### `markdown_foldexpr()`

自定义折叠表达式，返回值：
- `"="` - 保持当前折叠层级（代码块内的行）
- `">1"` - 开始 level 1 折叠（H1 标题，仅限文件开头或 frontmatter 后）
- `">2"` ~ `">6"` - 开始对应层级的折叠（H2-H6 标题）

## 快捷键

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `<CR>` | 切换折叠 | 在折叠行按回车切换展开/折叠 |
| `zk` | 折叠 H2+ | 折叠所有二级及以上标题 |
| `zu` | 展开所有 | 展开所有折叠 |

## 性能考虑

### 为什么使用缓存而非实时查询

`foldexpr` 会被 Neovim 频繁调用（每行都会调用），如果每次都执行 Treesitter 查询会导致严重的性能问题。

**错误示例**（每次调用都查询 Treesitter）：
```lua
function markdown_foldexpr()
  -- ❌ 每行都调用，太慢
  local parser = vim.treesitter.get_parser(bufnr, 'markdown')
  local trees = parser:parse()
  -- ...
end
```

**正确做法**（预先缓存）：
```lua
-- FileType 时一次性构建
vim.b.code_block_ranges = build_code_block_ranges(bufnr)

function markdown_foldexpr()
  -- ✅ 简单的范围查找，O(n) 但 n 很小
  if is_in_code_block_cached(lnum) then
    return '='
  end
end
```

### 缓存刷新时机

- `FileType markdown` - 打开文件时
- `zk` 快捷键执行时 - 手动刷新

## H1 特殊处理

H1 (`# 标题`) 只在以下位置被识别为折叠点：
1. 文件第一行
2. YAML frontmatter (`---`) 结束后的下一行

其他位置的 H1 会被忽略，因为很可能是代码块内的注释。

## 依赖

- `nvim-treesitter` - 提供 Markdown parser
- Treesitter `markdown` grammar - 解析 Markdown 语法

## 相关文件

- `lua/config/autocmd.lua` - 折叠功能实现
- `lua/plugins/markdown.lua` - render-markdown 插件配置
