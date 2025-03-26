-- Keymap examples
local keymap = vim.keymap
local map = keymap.set

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Buffer navigation
map("n", "<C-~>", "<cmd>bn<cr>", { desc = "Next buffer" })
map("n", "<C-_>", "<cmd>bp<cr>", { desc = "Previous buffer" })

-- File explorer
map("n", "<leader>n", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file explorer" })

-- Search and navigation
map("n", "/", function()
	require("telescope.builtin").current_buffer_fuzzy_find()
end, { desc = "Fuzzy search in current buffer" })

-- Quickfix and Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope git_files<cr>", { desc = "Find Git files" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Switch buffers" })

-- Telescope Git
map("n", "<leader>gc", "<cmd>Telescope git_commits<cr>", { desc = "Git commits" })
map("n", "<leader>gs", "<cmd>Telescope git_status<cr>", { desc = "Git status" })
map("n", "<leader>gt", "<cmd>Telescope git_bcommits<cr>", { desc = "Git buffer commits" })
map("n", "<leader>gbl", "<cmd>Telescope git_branches<cr>", { desc = "Git branches" })

-- LSP
map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", { desc = "Code actions" })
map("n", "<leader>gd", "<cmd>lua vim.lsp.buf.definition()<cr>", { desc = "Goto definition" })
map("n", "<leader>gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", { desc = "Goto implementation" })
map("n", "<leader>gr", "<cmd>lua vim.lsp.buf.references()<cr>", { desc = "Goto references" })
map("n", "<leader>gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", { desc = "Goto declaration" })
