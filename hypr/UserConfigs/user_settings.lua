-- conf9000 2026-11-16: values from configs/SystemSettings.conf that differ from the
-- KoolDots Lua defaults (configs/system_settings.lua), so the Lua config behaves like
-- the old hyprlang one.
hl.config({
    input = {
        kb_layout  = "us,cz",
        kb_options = "grp:alt_shift_toggle",
        touchpad = {
            scroll_factor = 0.3,
        },
    },
    cursor = {
        no_hardware_cursors = 2,
    },
    gestures = {
        workspace_swipe_distance = 500,
        workspace_swipe_forever  = true,
    },
    master = {
        mfact      = 0.5,
        new_on_top = true,
        new_status = "master",
    },
    misc = {
        vrr = 2,
    },
})
