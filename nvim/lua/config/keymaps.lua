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

-- LSP
map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", { desc = "Code actions" })
map("n", "<leader>gd", "<cmd>lua vim.lsp.buf.definition()<cr>", { desc = "Goto definition" })
map("n", "<leader>gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", { desc = "Goto implementation" })
map("n", "<leader>gr", "<cmd>lua vim.lsp.buf.references()<cr>", { desc = "Goto references" })
map("n", "<leader>gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", { desc = "Goto declaration" })

-- diffview
map("n", "<leader>gx", "<cmd>DiffviewFileHistory<cr>", { desc = "Open diff" })
