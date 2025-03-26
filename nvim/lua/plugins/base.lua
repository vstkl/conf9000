return {
	-- Base plugins
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "base16-framer",
		},
	},
	{ -- Minimal config
		"tinted-theming/tinted-vim",
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
	},
}
