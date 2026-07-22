-- ============================================================
--  VSCode + Neovim 配置 (asvetliakov/vscode-neovim 扩展)
--  设计原则: Neovim 只负责「编辑」, VS Code 负责「显示 + IDE 能力」
--  适用: 只用 VS Code 的用户。跳转/搜索/Git/补全/格式化/标签页/
--        文件树/状态栏 全部由 VS Code 原生提供, 通过 require('vscode')
--        桥接。这样能 100% 保证功能可用, 且不会有 UI 冲突。
--
--  结构:
--    1) 通用基础选项
--    2) 编辑类插件 (只装不需要 Neovim 自己画 UI 的, 且零原生构建)
--    3) lazy.nvim 引导
--    4) VSCode 专属快捷键 (仅 vscode 模式下生效)
-- ============================================================

-- 1) 基础选项 (终端 nvim 与 vscode 通用) --------------------
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.clipboard:append({ "unnamed", "unnamedplus" }) -- 共享系统剪贴板
vim.opt.undofile = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.showmode = false
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- 2) 编辑类插件 ----------------------------------------------
--  关键: 在 vscode-neovim 里, 凡是「需要 Neovim 自己画 UI」的插件
--  (Telescope / nvim-tree / lualine / bufferline / nvim-cmp /
--   mason + nvim-lspconfig / treesitter 等) 都不会正常工作, 一律交给
--   VS Code。下面只装纯「文本操作」类插件, 全部零原生构建、必可用。
--
--  文本对象说明: 日常所需的 i( a( i" a" i{ a{ iw aw i' it at 等
--  都是 Vim 内核内置的, 在 vscode-neovim 里无需任何额外依赖即可用。
--  (treesitter 增强文本对象 if/af/ic/ac 属锦上添花, 因新版
--   nvim-treesitter 解析器安装在新架构下不稳定, 此处不纳入, 见指南)
local plugins = {
  "tpope/vim-surround",        -- 快速改括号/引号: cs"'  ds"  ysiw]
  "tpope/vim-repeat",          -- 让 . 能重复 surround 等插件操作
  "tpope/vim-commentary",      -- gc 注释 (gcc 行, gc 选区)
  {
    url = "https://codeberg.org/andyg/leap.nvim",
    config = function()
      -- 新版 leap 的 add_default_mappings() 已弃用(会报警告),
      -- 这里直接把键位映射到官方 <Plug> 接口, 干净无警告。
      require("leap").setup({}) -- 用默认项; 需要区分大小写可加 case_sensitive = true
      vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap-forward)",
        { silent = true, desc = "Leap 向前跳转" })
      vim.keymap.set({ "n", "x", "o" }, "S", "<Plug>(leap-backward)",
        { silent = true, desc = "Leap 向后跳转" })
      vim.keymap.set({ "n", "x", "o" }, "gs", "<Plug>(leap-from-window)",
        { silent = true, desc = "Leap 跨窗口跳转" })
    end,
  },
  {
    "vscode-neovim/vscode-multi-cursor.nvim",
    event = "VeryLazy",
    cond = not not vim.g.vscode,
    opts = {}, -- default_mappings = true -> mc/mi/ma/mcc/mcs/mcw 等默认键已启用
  },
}

-- 3) 引导 lazy.nvim (未安装则自动 clone) ---------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup(plugins, {
  checker = { enabled = false },
  change_detection = { enabled = false },
  performance = { rtp = { disabled_plugins = { "netrw", "netrwPlugin" } } },
})

-- 4) VSCode 专属快捷键 (仅 vscode-neovim 模式下生效) --------
--  官方已内置: gd/gD(定义) gh/K(悬停) gH/gr(引用) gO(符号)
--              gf(声明) ==(格式化)。下面补充 <leader> 系列,
--              统一把操作桥接到 VS Code 命令。
if vim.g.vscode then
  local vscode = require("vscode")

  -- 代码操作
  vim.keymap.set("n", "<leader>cr", function() vscode.action("editor.action.rename") end,
    { desc = "重命名符号" })
  vim.keymap.set("n", "<leader>ca", function() vscode.action("editor.action.quickFix") end,
    { desc = "快速修复 / 代码操作" })
  vim.keymap.set("n", "<leader>cf", function() vscode.action("editor.action.formatDocument") end,
    { desc = "格式化文档" })
  vim.keymap.set("v", "<leader>cf", function() vscode.action("editor.action.formatSelection") end,
    { desc = "格式化选区" })
  vim.keymap.set("n", "]d", function() vscode.action("editor.action.marker.next") end,
    { desc = "下一个问题" })
  vim.keymap.set("n", "[d", function() vscode.action("editor.action.marker.prev") end,
    { desc = "上一个问题" })

  -- 文件 / 搜索
  vim.keymap.set("n", "<leader>ff", function() vscode.action("workbench.action.quickOpen") end,
    { desc = "快速打开文件" })
  vim.keymap.set("n", "<leader>fg", function() vscode.action("workbench.action.findInFiles") end,
    { desc = "全局搜索" })
  vim.keymap.set("n", "<leader>fr", function() vscode.action("workbench.action.recentlyOpened") end,
    { desc = "最近文件" })
  vim.keymap.set("n", "<leader>fs", function() vscode.action("workbench.action.files.save") end,
    { desc = "保存" })

  -- 窗口 / 面板
  vim.keymap.set("n", "<leader>tt", function() vscode.action("workbench.action.terminal.toggleTerminal") end,
    { desc = "切换终端" })
  vim.keymap.set("n", "<leader>e", function() vscode.action("workbench.action.toggleSidebarVisibility") end,
    { desc = "切换侧边栏" })
  vim.keymap.set("n", "<leader>gg", function() vscode.action("workbench.view.scm") end,
    { desc = "打开源代码管理(Git)" })

  -- 折叠 (VS Code 自管折叠系统, Neovim 的 zc/zo 不生效, 需桥接)
  vim.keymap.set("n", "zc", function() vscode.action("editor.fold") end,
    { desc = "折叠当前" })
  vim.keymap.set("n", "zo", function() vscode.action("editor.unfold") end,
    { desc = "展开当前" })
  vim.keymap.set("n", "zM", function() vscode.action("editor.foldAll") end,
    { desc = "折叠全部" })
  vim.keymap.set("n", "zR", function() vscode.action("editor.unfoldAll") end,
    { desc = "展开全部" })
  vim.keymap.set("n", "zC", function() vscode.action("editor.foldRecursively") end,
    { desc = "递归折叠" })
  vim.keymap.set("n", "zO", function() vscode.action("editor.unfoldRecursively") end,
    { desc = "递归展开" })

  -- 多光标 (vscode-multi-cursor.nvim)
  -- 本插件是「一套自洽体系」: 用 mc 系列把光标建进插件自己的 STATE,
  -- 再用 mi/ma 进入全光标编辑。它「不消费」VS Code 原生 Cmd+D 多选,
  -- 之前接的包装命令(addSelectionToNextFindMatch)会把人甩进 Insert 模式、
  -- 且脱离 STATE, 导致 mi/ma 用不上。这里把 Cmd+D 改为走同一套 mc 体系:
  --   <C-d> = mciw* : 标记光标下的词到 STATE, 并跳到下一个相同词(仍在 Normal)。
  --   连按 Cmd+D 逐个加选, 加够后按 mi(左)/ma(右) 进全光标编辑, Esc 结束。
  -- keybindings.json 把 Cmd+D 转发到 <C-d>。
  vim.keymap.set("n", "<C-d>", "mciw*<Cmd>nohlsearch<CR>",
    { remap = true, silent = true, desc = "多光标: 标记当前词并跳到下一个 (配合 mi/ma)" })
end
