<div align="center">
  <img src="https://github.com/sxyazi/yazi/blob/main/assets/logo.png?raw=true" alt="Yazi logo" width="20%">
</div>

<h3 align="center">
	theme-dark flavor for <a href="https://github.com/sxyazi/yazi">Yazi</a>
</h3>

A flavor that reproduces Yazi's stock dark theme (v26.9.1) as a standalone,
editable flavor. It uses the terminal's own 16 ANSI colors, so it follows
whatever palette the terminal is running, and ships the same ANSI `tmtheme.xml`
that Yazi uses for code previews by default.

Layout: `flavor.toml` (UI styles), `tmtheme.xml` (syntax highlighting),
`LICENSE`, `LICENSE-tmtheme`. Built from
[yazi-rs/flavor-template](https://github.com/yazi-rs/flavor-template).

## ⚙️ Usage

`~/.config/yazi/theme.toml`:

```toml
[flavor]
dark = "theme-dark"
```

Keep `theme.toml` limited to `[flavor]` unless you want to override individual
styles of this flavor.

## 📜 License

The flavor is MIT-licensed, and the included tmTheme (from
[bat](https://github.com/sharkdp/bat)) is also MIT-licensed. See
[LICENSE](LICENSE) and [LICENSE-tmtheme](LICENSE-tmtheme).
