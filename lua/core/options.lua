-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.opt.breakindent = true

-- 自动缩进设置
vim.opt.autoindent = true -- 新行继承当前行的缩进
vim.opt.smartindent = true -- 智能缩进（根据语法自动调整）
vim.opt.expandtab = true -- 用空格代替 Tab
vim.opt.shiftwidth = 2 -- 缩进宽度
vim.opt.tabstop = 2 -- Tab 显示宽度
vim.opt.softtabstop = 2 -- 编辑时 Tab 宽度
vim.opt.shiftround = true -- Round indent

-- Save undo history
vim.opt.undofile = true
vim.opt.undolevels = 10000

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true -- Don't ignore case with capitals

-- Keep signcolumn on by default
-- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.signcolumn = 'yes'

-- Decrease update time
-- Save swap file and trigger CursorHold
vim.opt.updatetime = 200

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true -- Put new windows right of current
vim.opt.splitbelow = true -- Put new windows below current
vim.opt.splitkeep = 'screen'

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.laststatus = 3

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'nosplit' -- preview incremental substitute

-- Show which line your cursor is on
vim.opt.cursorline = false

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 4 -- Lines of context
vim.opt.sidescrolloff = 8 -- Columns of context

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.opt.confirm = true

-- LazyVim-inspired defaults
vim.opt.autowrite = true -- Enable auto write
vim.opt.grepformat = '%f:%l:%c:%m'
vim.opt.grepprg = 'rg --vimgrep'
vim.opt.sessionoptions = { 'buffers', 'curdir', 'tabpages', 'winsize', 'help', 'globals', 'skiprtp', 'folds' }
vim.opt.shortmess:append { W = true, I = true, c = true, C = true }
vim.opt.spelllang = { 'en' }
vim.opt.termguicolors = true -- True color support
vim.opt.virtualedit = 'block' -- Allow cursor to move where there is no text in visual block mode
vim.opt.wildmode = 'longest:full,full' -- Command-line completion mode
vim.opt.winminwidth = 5 -- Minimum window width
vim.opt.wrap = false -- Disable line wrap

