return {
	-- Base plugins
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "base16-atelier-forest",
		},
	},
	{ -- Minimal config
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
	{
		"mikesmithgh/borderline.nvim",
		enabled = true,
		lazy = true,
		event = "VeryLazy",
		config = function()
			require("borderline").setup({})
		end,
	},
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
			keymap = { preset = "default" },

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
				default = { "lsp", "path", "snippets", "buffer" },
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
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		opts = {
			ensure_installed = {
				"bash",
				"html",
				"javascript",
				"json",
				"lua",
				"markdown",
				"markdown_inline",
				"python",
				"query",
				"regex",
				"tsx",
				"typescript",
				"vim",
				"yaml",
			},
		},
	},

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
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		cond = vim.g.neovide == nil,
		opts = {
			hide_target_hack = true,
			cursor_color = "none",
		},
		specs = {
			-- disable mini.animate cursor
			{
				"echasnovski/mini.animate",
				optional = true,
				opts = {
					cursor = { enable = false },
				},
			},
		},
	},
	-- {
	-- 	"folke/persistence.nvim",
	-- 	event = "BufReadPre",
	-- 	opts = {},

	-- 	keys = {
	-- 		{
	-- 			"<leader>qs",
	-- 			function()
	-- 				require("persistence").load()
	-- 			end,
	-- 			desc = "Restore Session",
	-- 		},
	-- 		{
	-- 			"<leader>qS",
	-- 			function()
	-- 				require("persistence").select()
	-- 			end,
	-- 			desc = "Select Session",
	-- 		},
	-- 		{
	-- 			"<leader>ql",
	-- 			function()
	-- 				require("persistence").load({ last = true })
	-- 			end,
	-- 			desc = "Restore Last Session",
	-- 		},
	-- 		{
	-- 			"<leader>qd",
	-- 			function()
	-- 				require("persistence").stop()
	-- 			end,
	-- 			desc = "Don't Save Current Session",
	-- 		},
	-- 	},
	-- },

	{
		"huynle/ogpt.nvim",
		event = "VeryLazy",
		keys = {
			{
				"<leader>]]",
				"<cmd>OGPTFocus<CR>",
				desc = "GPT",
			},
			{
				"<leader>]",
				":'<,'>OGPTRun<CR>",
				desc = "GPT",
				mode = { "n", "v" },
			},
			{
				"<leader>]c",
				"<cmd>OGPTRun edit_code_with_instructions<CR>",
				"Edit code with instruction",
				mode = { "n", "v" },
			},
			{
				"<leader>]e",
				"<cmd>OGPTRun edit_with_instructions<CR>",
				"Edit with instruction",
				mode = { "n", "v" },
			},
			{
				"<leader>]g",
				"<cmd>OGPTRun grammar_correction<CR>",
				"Grammar Correction",
				mode = { "n", "v" },
			},
			{
				"<leader>]r",
				"<cmd>OGPTRun evaluate<CR>",
				"Evaluate",
				mode = { "n", "v" },
			},
			{
				"<leader>]i",
				"<cmd>OGPTRun get_info<CR>",
				"Get Info",
				mode = { "n", "v" },
			},
			{ "<leader>]t", "<cmd>OGPTRun translate<CR>", "Translate", mode = { "n", "v" } },
			{ "<leader>]k", "<cmd>OGPTRun keywords<CR>", "Keywords", mode = { "n", "v" } },
			{ "<leader>]d", "<cmd>OGPTRun docstring<CR>", "Docstring", mode = { "n", "v" } },
			{ "<leader>]a", "<cmd>OGPTRun add_tests<CR>", "Add Tests", mode = { "n", "v" } },
			{ "<leader>]<leader>", "<cmd>OGPTRun custom_input<CR>", "Custom Input", mode = { "n", "v" } },
			{ "g?", "<cmd>OGPTRun quick_question<CR>", "Quick Question", mode = { "n" } },
			{ "<leader>]f", "<cmd>OGPTRun fix_bugs<CR>", "Fix Bugs", mode = { "n", "v" } },
			{
				"<leader>]x",
				"<cmd>OGPTRun explain_code<CR>",
				"Explain Code",
				mode = { "n", "v" },
			},
		},

		opts = {

			default_provider = "openrouter",
			-- default edgy flag
			-- set this to true if you prefer to use edgy.nvim (https://github.com/folke/edgy.nvim) instead of floating windows
			edgy = true,
			providers = {
				openrouter = {
					enabled = true,
					api_host = "http://localhost:1234",
					api_key = "",
					api_params = {
						temperature = 0.5,
					},
					api_chat_params = {
						frequency_penalty = 0.8,
						temperature = 0.8,
					},
					models = {
						-- alias to actual model name, helpful to define same model name across multiple providers
						-- nested alias
						model = "gemma-3-1b-it",
					},
				},
				-- openrouter = {
				-- 	enabled = true,
				-- 	api_host = os.getenv("OPENROUTER_API_HOST") or "https://openrouter.ai/api",
				-- 	api_key = os.getenv("OPENROUTER_API_KEY") or "",
				-- 	model = "deepseek/deepseek-r1-zero:free",
				-- 	models = {
				-- 		-- alias to actual model name, helpful to define same model name across multiple providers
				-- 		-- nested alias
				-- 		general_model = "deepseek/deepseek-chat-v3-0324:free",
				-- 	},
				-- 	api_params = {
				-- 		model = "deepseek/deepseek-r1-zero:free",
				-- 		temperature = 0.5,
				-- 		top_p = 0.99,
				-- 	},
				-- 	api_chat_params = {
				-- 		frequency_penalty = 0.8,
				-- 		model = "deepseek/deepseek-r1-zero:free",
				-- 		presence_penalty = 0.5,
				-- 		temperature = 0.8,
				-- 	},
				-- },
			},
			yank_register = "+",
			edit = {
				edgy = nil, -- use global default, override if defined
				size = {
					width = "20%",
					height = 10,
				},
				keymaps = {
					close = "<C-c>",
					accept = "<M-CR>",
					toggle_diff = "<C-d>",
					toggle_parameters = "<C-o>",
					cycle_windows = "<Tab>",
					use_output_as_input = "<C-u>",
				},
			},
			popup = {
				edgy = false, -- use global default, override if defined
				size = {
					width = "50%",
					height = 30,
				},
				padding = { 1, 1, 1, 1 },
				enter = true,
				focusable = false,
				dynamic_resize = false,
				zindex = -1,
				buf_options = {
					modifiable = false,
					readonly = true,
					filetype = "ogpt-popup",
					syntax = "markdown",
				},
				win_options = {
					wrap = true,
					linebreak = true,
				},
				keymaps = {
					close = { "<C-c>", "q" },
					accept = "<C-CR>",
					append = "a",
					prepend = "p",
					yank_code = "c",
					yank_to_register = "y",
				},
			},
			chat = {
				edgy = false, -- use global default, override if defined
				welcome_message = "Hillow hillow",
				loading_text = "Loading, please wait ...",
				question_sign = "", -- 🙂
				answer_sign = "ﮧ", -- 🤖
				border_left_sign = "|",
				border_right_sign = "|",
				max_line_length = 120,
				sessions_window = {
					active_sign = " 󰄵 ",
					inactive_sign = " 󰄱 ",
					current_line_sign = "",
					border = {
						text = {
							top = " Sessions ",
						},
					},
				},
				keymaps = {
					close = { "<C-c>" },
					yank_last = "<C-y>",
					yank_last_code = "<C-i>",
					scroll_up = "<C-u>",
					scroll_down = "<C-d>",
					new_session = "<C-n>",
					cycle_windows = "<Tab>",
					cycle_modes = "<C-f>",
					next_message = "J",
					prev_message = "K",
					select_session = "<CR>",
					rename_session = "r",
					delete_session = "d",
					draft_message = "<C-d>",
					edit_message = "e",
					delete_message = "d",
					toggle_parameters = "<C-o>",
					toggle_message_role = "<C-r>",
					toggle_system_role_open = "<C-s>",
					stop_generating = "<C-x>",
				},
			},
			popup_layout = {
				default = "right",
				right = {
					width = "40%",
				},
			},
			-- {{{input}}} is always available as the selected/highlighted text
			actions = {
				grammar_correction = {
					type = "popup",
					template = "Correct the given text to standard {{{lang}}}:\n\n```{{{input}}}```",
					system = "You are a helpful note writing assistant, given a text input, correct the text only for grammar and spelling error. You are to keep all formatting the same, e.g. markdown bullets, should stay as a markdown bullet in the result, and indents should stay the same. Return ONLY the corrected text.",
					strategy = "replace",
					params = {
						temperature = 0.3,
					},
					args = {
						lang = {
							type = "string",
							optional = "true",
						},
					},
				},
				translate = {
					type = "popup",
					template = "Translate this into {{{lang}}}:\n\n{{{input}}}",
					strategy = "display",
					params = {
						temperature = 0.3,
					},
					args = {
						lang = {
							type = "string",
							optional = "true",
							default = "vietnamese",
						},
					},
				},
				keywords = {
					type = "popup",
					template = "Extract the main keywords from the following text to be used as document tags.\n\n```{{{input}}}```",
					strategy = "display",
					params = {
						model = "general_model", -- use of model alias, generally, this model alias should be available to all providers in use
						temperature = 0.5,
						frequency_penalty = 0.8,
					},
				},
				do_complete_code = {
					type = "popup",
					template = "Code:\n```{{{filetype}}}\n{{{input}}}\n```\n\nCompleted Code:\n```{{{filetype}}}",
					strategy = "display",
					params = {
						stop = {
							"```",
						},
					},
				},

				quick_question = {
					type = "popup",
					args = {
						-- template expansion
						question = {
							type = "string",
							optional = "true",
							default = function()
								return vim.fn.input("question: ")
							end,
						},
					},
					system = "You are a helpful assistant",
					template = "{{{question}}}",
					strategy = "display",
				},

				custom_input = {
					type = "popup",
					args = {
						instruction = {
							type = "string",
							optional = "true",
							default = function()
								return vim.fn.input("instruction: ")
							end,
						},
					},
					system = "You are a helpful assistant",
					template = "Given the follow snippet, {{{instruction}}}.\n\nsnippet:\n```{{{filetype}}}\n{{{input}}}\n```",
					strategy = "display",
				},

				optimize_code = {
					type = "popup",
					system = "You are a helpful coding assistant. Complete the given prompt.",
					template = "Optimize the code below, following these instructions:\n\n{{{instruction}}}.\n\nCode:\n```{{{filetype}}}\n{{{input}}}\n```\n\nOptimized version:\n```{{{filetype}}}",
					strategy = "edit_code",
					params = {
						stop = {
							"```",
						},
					},
				},
				-- all strategy "edit" have instruction as input
				edit_code_with_instructions = {
					type = "edit",
					strategy = "edit_code",
					template = "Given the follow code snippet, {{{instruction}}}.\n\nCode:\n```{{{filetype}}}\n{{{input}}}\n```",
					delay = true,
					extract_codeblock = true,
					params = {
						-- frequency_penalty = 0,
						-- presence_penalty = 0,
						temperature = 0.5,
						top_p = 0.99,
					},
				},

				-- all strategy "edit" have instruction as input
				edit_with_instructions = {
					-- if not specified, will use default provider
					-- provider = "ollama",
					-- model = "mistral:7b",
					type = "edit",
					strategy = "edit",
					template = "Given the follow input, {{{instruction}}}.\n\nInput:\n```{{{filetype}}}\n{{{input}}}\n```",
					delay = true,
					params = {
						temperature = 0.5,
						top_p = 0.99,
					},
				},
			},
		},
		dependencies = {
			"MunifTanjim/nui.nvim",
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
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
}
