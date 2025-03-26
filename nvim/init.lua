-- Initialize lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- or "main" for latest features
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("config.keymaps")
require("config.options")

require("lazy").setup({
	{ "LazyVim/LazyVim", import = "lazyvim.plugins" },
	{ import = "plugins" },
})
