-- ==================================================
-- conf9000 2026-11-16: copied from lua/decorations.lua; colors = wallust $color12/$color10/$color15/$color0 as in UserDecorations.conf.
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================

-- Converted from config/hypr/UserConfigs/UserDecorations.conf.
-- NOTE: wallust-hyprland.conf is hyprlang-sourced in the original config.
-- Lua parity for importing that file is still evolving; using static color fallbacks here.

hl.config({
    general = {
        border_size = 2,
        gaps_in = 2,
        gaps_out = 4,
        col = {
            active_border = "rgba(AA9A20ff)",
            inactive_border = "rgba(E27B1Aff)",
        },
    },
})

hl.config({
    decoration = {
        rounding = 10,
        active_opacity = 1.0,
        inactive_opacity = 0.9,
        fullscreen_opacity = 1.0,
        dim_inactive = true,
        dim_strength = 0.1,
        dim_special = 0.8,
        shadow = {
            enabled = true,
            range = 3,
            render_power = 1,
            color = "rgba(AA9A20ff)",
            color_inactive = "rgba(E27B1Aff)",
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            new_optimizations = true,
            xray = true,
            ignore_opacity = true,
            special = true,
            popups = true,
        },
    },
})

hl.config({
    group = {
        col = {
            border_active = "rgba(E9E3D0ff)",
        },
        groupbar = {
            col = {
                active = "rgba(444545ff)",
            },
        },
    },
})
