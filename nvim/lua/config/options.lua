-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.o.completeopt = "menu,menuone,noselect"

-- Dont show leading whitespace dashes
vim.opt.list = false

-- Use system clipboard
vim.o.clipboard = "unnamedplus"

-- Set line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Turn off backup
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- Use spaces instead of tabs
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.g.lazyvim_picker = "snacks"

-- Spelling
vim.opt.spell = true
vim.opt.spelllang = { "en" }

-- Performance optimizations for large files
vim.opt.updatetime = 250 -- Faster completion
vim.opt.timeoutlen = 300 -- Faster key sequence timeout
vim.opt.redrawtime = 1500 -- Allow more time for redrawing

-- Better scrolling performance
vim.opt.smoothscroll = true
vim.opt.scrolloff = 8 -- Keep 8 lines visible when scrolling

-- Optimize for large files
vim.opt.synmaxcol = 240 -- Don't highlight long lines

-- Better search performance
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
