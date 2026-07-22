# vscode-neovim 配置

为「只用 VS Code、但想要完整 Vim 编辑体验」设计的**单文件** Neovim 配置。
基于 [asvetliakov/vscode-neovim](https://github.com/vscode-neovim/vscode-neovim) 扩展。

核心思路：**Neovim 只负责「编辑」，UI 全部交给 VS Code。**
文件树 / 补全 / 状态栏 / 标签页 / 搜索 / Git / 诊断等由 VS Code 原生提供，
通过 `require('vscode')` 桥接，保证 100% 可用、且不会有 UI 冲突。

---

## 安装

1. 安装 Neovim（>= 0.9）。
2. VS Code 安装扩展 `asvetliakov.vscode-neovim`。
3. 把本仓库内容放到 Neovim 配置目录：
   - macOS / Linux：`~/.config/nvim/`
   - Windows：`~/AppData/Local/nvim/`
4. 重启 VS Code，或在命令面板执行 `VSCode Neovim: Reload Configuration`。
5. 插件由 [lazy.nvim](https://github.com/folke/lazy.nvim) 首次打开时自动 clone 安装，无需手动操作。

---

## 设计原则

- **不装任何「需要 Neovim 自己画 UI」的插件**（Telescope / nvim-tree / lualine /
  bufferline / nvim-cmp / mason / treesitter 等）。在 vscode-neovim 下这些无法
  正常工作，一律交给 VS Code。
- 只使用**纯文本操作类**插件，全部零原生构建、必可用。
- Vim 内核内置的文本对象（`i( a( i" a" i{ a{ iw aw i' it at …`）开箱即用，
  无需额外依赖。

---

## 插件

| 插件 | 作用 |
|---|---|
| [tpope/vim-surround](https://github.com/tpope/vim-surround) | 快速改括号/引号：`cs"'`、`ds"`、`ysiw]` |
| [tpope/vim-repeat](https://github.com/tpope/vim-repeat) | 让 `.` 能重复 surround 等插件操作 |
| [tpope/vim-commentary](https://github.com/tpope/vim-commentary) | 注释：`gcc` 行、`gc` 选区 |
| [leap.nvim](https://codeberg.org/andyg/leap.nvim)（Codeberg） | 二键精准跳转：`s` 向前、`S` 向后 |
| [vscode-multi-cursor.nvim](https://github.com/vscode-neovim/vscode-multi-cursor.nvim) | 多光标编辑（`mc` 体系） |

---

## 用法 / 按键

### 基础文本对象

`i(` `a(` `i"` `a"` `i{` `a{` `iw` `aw` `i'` `it` `at` … 等 Vim 内核内置，
在 vscode-neovim 下直接可用。

### leap 跳转

| 按键 | 作用 |
|---|---|
| `s` | 向前跳（如 `swo` 跳到下一个 "wo"） |
| `S` | 向后跳 |
| `gs` | `<Plug>(leap-from-window)` 跨窗口跳 **（见下方说明）** |

> **关于 `gs`（leap-from-window）**：该映射存在，但在 vscode-neovim 下**没有效果**。
> 原因是 `leap-from-window` 需要 Neovim 自己的多窗口（split）才能跨窗口跳，
> 而 vscode-neovim 只把「当前编辑器」渲染成单一 Neovim 窗口，VS Code 的其它
> editor group 不属于 Neovim，于是没有任何「其它窗口」可跳，等于空操作。
> 想在另一个编辑器分组里跳转，用 VS Code 自带导航 `Cmd+1/2/3` 或 `Cmd+Shift+\`
> 切过去，再按 `s` 即可。

### 折叠（桥接 VS Code）

VS Code 自己管理折叠，Neovim 在 vscode-neovim 下**没有自己的 fold**（折叠范围
由 VS Code 计算）。因此早期直接用 `zc` 会报 `E490: No fold found`——因为 Neovim
的 fold 系统里根本没有可折叠区域。本配置把折叠键**桥接**到 VS Code 命令解决：

| 按键 | 桥接到 | 作用 |
|---|---|---|
| `zc` | `editor.fold` | 折叠光标下最内层区域 |
| `zo` | `editor.unfold` | 展开当前 |
| `zM` | `editor.foldAll` | 折叠全部 |
| `zR` | `editor.unfoldAll` | 展开全部 |
| `zC` | `editor.foldRecursively` | 从光标处递归折叠 |
| `zO` | `editor.unfoldRecursively` | 从光标处递归展开 |

> **排查 / 前提**：`editor.fold` 只在「光标所在行属于某个可折叠区域」时生效。
> VS Code 的折叠范围来自语法（`editor.foldingStrategy: "auto"`，默认）或缩进
> （`"indentation"`）。若按 `zc` **没反应**，通常是：
> 1. 光标不在函数 / 类 / 代码块起始行 —— 先把光标移到块首再试；
> 2. 该文件既没有语法折叠又是无缩进文本 —— 在 `vscode/settings.json` 里加
>    `"editor.foldingStrategy": "indentation"`，改用缩进折叠（对任意缩进文件都
>    有效，如 Python / YAML / 多数代码）。
>
> 这些键是 Neovim 侧映射，只在 vscode-neovim 模式（非纯终端 nvim）下生效。

> **仍然弹 `E490: No fold found` 怎么解决**：说明桥接映射根本没生效，`zc` 还在
> 走 Neovim 原生 fold（空的），而不是走 `editor.fold`。按顺序排查：
> 1. **确认映射存在**：Normal 模式下敲 `:nmap zc`。若显示
>    `zc  * <Cmd>call VSCodeNotify('editor.fold')<CR>`（或类似），说明桥接已加载；
>    若显示 `No mapping found`，就是 `init.lua` 没被加载 → 看第 2 步。
> 2. **确认 init.lua 被加载**：VS Code 里 `neovimInitVimPaths` 必须指向本仓库的
>    `init.lua`（见 `vscode/settings.json`）。改完执行命令面板
>    `VSCode Neovim: Reload Configuration`，或直接重启 VS Code。
> 3. **确认没被别的映射覆盖**：`:verbose nmap zc` 会打印这条映射「最后是在哪个
>    文件设置的」。若来源不是本 `init.lua`，说明被其它配置抢了，删掉冲突项即可。
> 4. 以上都对但仍报错 → 用 `:messages` 看 Neovim 启动是否有 Lua 报错（例如插件
>    加载失败导致后续 keymap 没执行），修掉报错后重载。

### 多光标（vscode-multi-cursor.nvim 的 `mc` 体系）

这套插件是「自洽体系」：用 `mc` 系列把光标建进插件自己的 STATE，再用 `mi/ma`
进入全光标编辑。它**不消费** VS Code 原生 `Cmd+D` 多选，因此本配置把 `Cmd+D`
桥接到 `mc` 体系（见下方 keybindings.json）：

1. `Cmd+D`：标记光标下的词到 STATE，并跳到下一个相同词（**仍在 Normal**）。
2. 连按 `Cmd+D`：逐个加选相同词。
3. `mi`：从光标左侧进入全光标编辑；`ma`：从光标右侧（append）进入。
4. `Esc`：结束编辑，回到单光标。
5. `mcc`：取消所有多光标；`mcs`：跳过当前光标；`mcw`：按词加选。

> 关键：不要在 `Cmd+D` 后用原生的 `c`/`i` 等普通操作符——它们只作用于主光标，
> 要用 `mi/ma` 进入插件的全光标编辑模式才会同步改所有光标。

### `<leader>` 桥接 VS Code 命令

`<leader>` 默认为空格。

| 按键 | 作用 |
|---|---|
| `<leader>cr` | 重命名符号 |
| `<leader>ca` | 快速修复 / 代码操作 |
| `<leader>cf` | 格式化文档（选区模式为格式化选区） |
| `<leader>ff` | 快速打开文件 |
| `<leader>fg` | 全局搜索 |
| `<leader>fr` | 最近文件 |
| `<leader>fs` | 保存 |
| `<leader>tt` | 切换终端 |
| `<leader>e` | 切换侧边栏 |
| `<leader>gg` | 源代码管理（Git） |
| `]d` / `[d` | 下一个 / 上一个问题（诊断） |

---

## VS Code 配置（keybindings.json / settings.json）

本仓库附带两份 VS Code 配置文件，放在 `vscode/` 目录下，可直接拷到 VS Code
用户配置目录使用：

- **macOS**：`~/Library/Application Support/Code/User/`
- **Windows**：`%APPDATA%\Code\User\`
- **Linux**：`~/.config/Code/User/`

### `vscode/keybindings.json`

包含：Normal / Visual 模式下 `j/k/↑/↓` 跳过折叠（不展开）、以及 `Cmd+D` 转发到
Neovim 的 `<C-d>`（多光标，见上文「多光标」一节）。完整内容见仓库文件，关键条目：

```json
{
  "key": "cmd+d",
  "command": "vscode-neovim.send",
  "args": "<C-d>",
  "when": "editorFocus && neovim.mode == 'normal'"
}
```

> 关键：`when` 限定在 **Normal** 模式才转发，避免把人甩进 Insert 模式。
> 其它 VS Code 原生的 `Cmd+D`（如非 Neovim 模式）不受影响。
> `Cmd+Shift+L`（全选相同词）未接入插件——其 `selectHighlights` 不回填插件
> STATE，`mi/ma` 用不上；多处一起改请连按 `Cmd+D`。

### `vscode/settings.json`

vscode-neovim 所需的扩展设置（Neovim 可执行文件路径、init 入口、性能亲和性、
键位分发）。可直接合并进你的 `settings.json`：

```json
{
  "vscode-neovim.neovimExecutablePaths.darwin": "/opt/homebrew/bin/nvim",
  "vscode-neovim.neovimInitVimPaths.darwin": "~/.config/nvim/init.lua",
  "vscode-neovim.useWSL": false,
  "extensions.experimental.affinity": { "asvetliakov.vscode-neovim": 1 },
  "keyboard.dispatch": "keyCode"
}
```

> Intel Mac 请把 `neovimExecutablePaths.darwin` 改为 `/usr/local/bin/nvim`。
> 其余平台对应键为 `neovimExecutablePaths.win32` / `neovimExecutablePaths.linux`。

---

## 附带 Skill（WorkBuddy）

`skill/` 目录是一份可直接导入 WorkBuddy 的 Skill，封装了本配置的全部经验
（单文件结构、leap、多光标 `mc` 体系、折叠桥接、`<leader>` 桥接、keybindings）：

```
skill/
├── SKILL.md              # Skill 说明与触发条件
└── references/
    ├── init.lua          # 可直接用的 init.lua
    └── keybindings.json  # 配套的 VS Code keybindings
```

导入方式：把 `skill/` 内的内容放到 `~/.workbuddy/skills/vscode-neovim-config/`
（即 `SKILL.md` 与 `references/` 落在该目录），在 WorkBuddy 中即可使用。

---

## 文件结构

```
~/.config/nvim/
├── init.lua            # 全部配置（单文件）
├── lazy-lock.json      # 插件版本锁定（保证可复现）
├── README.md           # 本文档
├── .gitignore
├── vscode/             # VS Code 侧配置
│   ├── keybindings.json
│   └── settings.json
└── skill/              # 可导入 WorkBuddy 的 Skill
    ├── SKILL.md
    └── references/
        ├── init.lua
        └── keybindings.json
```

所有 Neovim 配置集中在 `init.lua`，没有 `lua/` 子目录——这是有意为之，保持
单文件、零 UI 依赖、易于同步。VS Code 侧配置与 Skill 单独放在 `vscode/` 和
`skill/`，随仓库一起版本管理。

---

## 备注

- 本仓库用于同步「vscode-neovim 单文件配置」。早期版本曾有模块化结构
  （`lua/config/*`、`lua/plugins/*`），已统一为现在的单文件形态。
- 任何 UI 类需求（文件树、模糊查找、Git 面板、诊断、补全）请直接使用 VS Code
  原生能力或对应扩展，不要在 Neovim 侧重复实现。
