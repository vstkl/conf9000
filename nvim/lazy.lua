return {

	{ "LazyVim/LazyVim", import = "lazyvim.plugins" },
	{ import = "plugins" },
	checker = {
		enabled = true,
		notify = false,
	},
	performance = {
		cache = {
			enabled = true,
		},
		rtp = {
			reset = true,
		},
	},
	ui = {
		border = "rounded",
		height = 80,
	},
}
