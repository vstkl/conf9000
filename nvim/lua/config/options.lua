-- ~/.config/nvim/lua/config/options.lua

local opt = vim.opt

-- Basic settings
opt.number = true -- Enable line numbers
opt.relativenumber = true -- Enable relative line numbers
opt.signcolumn = "yes" -- Show sign column
opt.wrap = true -- Wrap lines

-- Indentation and tabs
opt.tabstop = 2 -- Tab width is 4 spaces
opt.softtabstop = 2 -- Soft tabstop is also 4 spaces
opt.shiftwidth = 2 -- Shifting uses 4 spaces
opt.expandtab = true -- Expand tabs to spaces

-- File handling
opt.swapfile = false -- Do not create swap files
opt.backup = false -- Do not create backup files
opt.undodir = vim.env.HOME .. "/.local/share/nvim/undodir" -- Save undo history
opt.undofile = true -- Enable undo persistence

-- Search and performance
opt.hlsearch = false -- Do not highlight searches
opt.incsearch = true -- Incremental search
opt.smartcase = true -- Case-insensitive search

-- UI
opt.termguicolors = true -- Enable true colors in the terminal
opt.wildmode = "longest,list:full" -- Better completion
opt.wildmenu = true -- Enable wildmenu
opt.guifont = "FiraCode Nerd Font:h12" -- Font configuration
opt.winborder = "single"

-- Editor behavior
opt.splitright = true -- Split windows to the right
opt.splitbelow = true -- Split windows below
opt.scrolloff = 5 -- Keep 5 lines between cursor and edge
opt.sidescrolloff = 5 -- Keep 5 columns between cursor and edge

-- File explorer and buffers
opt.belloff = "all" -- Disable all bells
opt.updatetime = 50 -- Faster updates
opt.lazyredraw = false -- Enable lazy redrawing

opt.textwidth = 200
