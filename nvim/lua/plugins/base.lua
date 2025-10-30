return {
	-- Base plugins
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = vim.env.BASE16_THEME,
		},
	},
	{ -- minimal config
		"tinted-theming/tinted-vim",
	},
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				"nvim-dap-ui",
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
			},
		},
	},
	{ "nvim-lua/plenary.nvim", branch = "master" },
	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		opts = {},
	},
	-- lazy.nvim
	{
		"folke/snacks.nvim",
		---@module 'snacks'
		---@type snacks.Config
		opts = {
			indent = {
				-- your indent configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
			},
		},
	}, --
	-- 	{
	-- 		"mikesmithgh/borderline.nvim",
	-- 		enabled = true,
	-- 		lazy = true,
	-- 		event = "VeryLazy",
	-- 		config = function()
	-- 			require("borderline").setup({})
	-- 		end,
	-- 	},
	{
		"saghen/blink.cmp",
		-- optional: provides snippets for the snippet source
		dependencies = { "rafamadriz/friendly-snippets" },

		-- use a release tag to download pre-built binaries
		version = "1.*",
		-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
		-- build = 'cargo build --release',
		-- If you use nix, you can build from source using latest nightly rust with:
		-- build = 'nix run .#build-plugin',

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			-- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
			-- 'super-tab' for mappings similar to vscode (tab to accept)
			-- 'enter' for enter to accept
			-- 'none' for no mappings
			--
			-- All presets have the following mappings:
			-- C-space: Open menu or open docs if already open
			-- C-n/C-p or Up/Down: Select next/previous item
			-- C-e: Hide menu
			-- C-k: Toggle signature help (if signature.enabled = true)
			--
			-- See :h blink-cmp-config-keymap for defining your own keymap
			keymap = { preset = "enter" },

			appearance = {
				-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
			},

			-- (Default) Only show the documentation popup when manually triggered
			completion = { documentation = { auto_show = false } },

			-- Default list of enabled providers defined so that you can extend it
			-- elsewhere in your config, without redefining it, due to `opts_extend`
			sources = {
				default = { "lazydev", "lsp", "path", "snippets", "buffer" },
			},

			-- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
			-- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
			-- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
			--
			-- See the fuzzy documentation for more information
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },
	},
	{
		"aietes/esp32.nvim",
		opts = {
			-- custom build dir
			build_dir = "build.clang",
		},
		config = function(_, opts)
			require("esp32").setup(opts)
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
			"saghen/blink.cmp",
		},
	},
	--	{
	--		"nvim-treesitter/nvim-treesitter",
	--		build = ":TSUpdate",
	--		opts = {
	--			ensure_installed = {
	--				"c",
	--				"bash",
	--				"html",
	--				"javascript",
	--				"json",
	--				"lua",
	--				"markdown",
	--				"markdown_inline",
	--				"python",
	--				"query",
	--				"regex",
	--				"tsx",
	--				"typescript",
	--				"vim",
	--				"yaml",
	--			},
	--		},
	--	},
	--
	{
		"ibhagwan/fzf-lua",
		-- optional for icon support
		dependencies = { "nvim-tree/nvim-web-devicons" },
		-- or if using mini.icons/mini.nvim
		-- dependencies = { "echasnovski/mini.icons" },
		opts = {},
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
	},
	{
		"akinsho/toggleterm.nvim",
		keys = {
			{
				"<leader>tt",
				function()
					require("toggleterm").toggle()
				end,
				desc = "Toggle Terminal",
			},
		},
	},
	--	{
	--		"sphamba/smear-cursor.nvim",
	--		event = "VeryLazy",
	--		cond = vim.g.neovide == nil,
	--		opts = {
	--			hide_target_hack = true,
	--			cursor_color = "none",
	--		},
	--		specs = {
	--			-- disable mini.animate cursor
	--			{
	--				"echasnovski/mini.animate",
	--				optional = true,
	--				opts = {
	--					cursor = { enable = false },
	--				},
	--			},
	--		},
	--	},
	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		opts = {},

		keys = {
			{
				"<leader>qs",
				function()
					require("persistence").load()
				end,
				desc = "Restore Session",
			},
			{
				"<leader>qS",
				function()
					require("persistence").select()
				end,
				desc = "Select Session",
			},
			{
				"<leader>ql",
				function()
					require("persistence").load({ last = true })
				end,
				desc = "Restore Last Session",
			},
			{
				"<leader>qd",
				function()
					require("persistence").stop()
				end,
				desc = "Don't Save Current Session",
			},
		},
	},

	{
		"MeanderingProgrammer/render-markdown.nvim",
		opts = {
			code = {
				sign = false,
				width = "block",
				right_pad = 1,
			},
			heading = {
				sign = false,
				icons = {},
			},
			checkbox = {
				enabled = false,
			},
			render_modes = { "n", "c", "v" },
			win_options = {
				conceallevel = {
					default = vim.api.nvim_get_option_value("conceallevel", {}),
					rendered = 3,
				},
				concealcursor = {
					default = vim.api.nvim_get_option_value("concealcursor", {}),
					rendered = "",
				},
			},
			anti_conceal = { enabled = true },
		},
		ft = { "markdown", "norg", "rmd", "org", "codecompanion" },
		config = function(_, opts)
			require("render-markdown").setup(opts)
			Snacks.toggle({
				name = "Render Markdown",
				get = function()
					return require("render-markdown.state").enabled
				end,
				set = function(enabled)
					local m = require("render-markdown")
					if enabled then
						m.enable()
					else
						m.disable()
					end
				end,
			}):map("<leader>um")
		end,
	},
	{
		"3rd/image.nvim",
		event = "VeryLazy",
		opts = {
			backend = "kitty",
			processor = "magick_rock",
			integrations = {
				markdown = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = true,
					only_render_image_at_cursor = false,
					filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
				},
				neorg = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = true,
					only_render_image_at_cursor = false,
					filetypes = { "norg" },
				},
			},
			max_width = nil,
			max_height = nil,
			max_width_window_percentage = nil,
			max_height_window_percentage = 50,
			kitty_method = "normal",
		},
	},
	{
		"goerz/jupytext.nvim",
		version = "0.2.0",
		opts = {}, -- see Options
	},
	{
		"pteroctopus/faster.nvim",
	},
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		build = ":Copilot auth",
		event = "BufReadPost",
		opts = {
			suggestion = {
				enabled = not vim.g.ai_cmp,
				auto_trigger = true,
				hide_during_completion = vim.g.ai_cmp,
				keymap = {
					accept = false, -- handled by nvim-cmp / blink.cmp
					next = "<M-]>",
					prev = "<M-[>",
				},
			},
			panel = { enabled = false },
			filetypes = {
				markdown = true,
				help = true,
			},
		},
	},
	--	{
	-- 		"sindrets/diffview.nvim",
	-- 		dependencies = { "nvim-lua/plenary.nvim" },
	-- 		cmd = { "DiffviewOpen", "DiffviewFileHistory" },
	-- 		keys = {
	-- 			{ "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Open diff view" },
	-- 			{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Open file history" },
	-- 			{ "<leader>gB", "<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>", desc = "Review branch changes" },
	-- 		},
	-- 		opts = {
	-- 			enhanced_diff_hl = true,
	-- 			use_icons = true,
	-- 			view = {
	-- 				default = { layout = "diff2_horizontal" },
	-- 				merge_tool = {
	-- 					layout = "diff4_mixed",
	-- 					disable_diagnostics = true,
	-- 				},
	-- 			},
	-- 		},
	-- 	},
}
