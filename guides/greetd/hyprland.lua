-- /etc/greetd/hyprland.lua: minimal Hyprland (0.57+, Lua config) that only runs the ReGreet login screen.
-- greetd starts it as the `greeter` user; when ReGreet exits (after a login) Hyprland exits too.
hl.on("hyprland.start", function()
    hl.exec_cmd("regreet; hyprctl dispatch 'hl.dsp.exit()'")
end)

hl.config({
    input = {
        kb_layout    = "us,cz",
        repeat_delay = 200,
        repeat_rate  = 30,
        touchpad = {
            natural_scroll    = true,
            tap_to_click      = true,
        },
    },
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },
    animations = {
        enabled = false,
    },
})
