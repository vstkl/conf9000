-- Seamless C-h/j/k/l between nvim splits and tmux panes.
-- tmux side: @plugin 'christoomey/vim-tmux-navigator' in tmux/tmux.conf.
-- Defined via lazy `keys`, so LazyVim's default <C-h/j/k/l> window maps step aside.
return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Window/tmux pane left" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Window/tmux pane down" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Window/tmux pane up" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Window/tmux pane right" },
      { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Window/tmux pane previous" },
    },
  },
}
