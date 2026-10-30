-- Full rounded border around all panes (as in the yazi-rs/flavor-template preview)
require("full-border"):setup({
	type = ui.Border.ROUNDED,
})

-- Git status signs in the file list (fetchers registered in yazi.toml)
require("git"):setup()

-- Built-in plugins
require("zoxide"):setup({
	update_db = true,
})

require("session"):setup({
	sync_yanked = true,
})
