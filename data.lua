data:extend({{
    type = "custom-input",
    name = "mt_give-gps-selection-tool",
    key_sequence = "SHIFT + ALT + G",
    action = "spawn-item",
    item_to_spawn = "mt_gps-selection-tool",
    order = "a"
}, {
    type = "shortcut",
    name = "mt_give-gps-selection-tool",
    icon = "__map-tag-core__/graphics/icons/pin.png",
    icon_size = 64,
    small_icon = "__map-tag-core__/graphics/icons/pin.png",
    small_icon_size = 64,
    action = "spawn-item",
    item_to_spawn = "mt_gps-selection-tool"
}, {
    type = "selection-tool",
    name = "mt_gps-selection-tool",
    icon = "__map-tag-core__/graphics/icons/pin.png",
    icon_size = 64,
    stack_size = 1,
    flags = {"only-in-cursor", "spawnable", "not-stackable"},
    hidden = true,
    select = {
        border_color = { 1, 1, 1 },
        cursor_box_type = 'not-allowed',
        mode = 'nothing',
    },
    alt_select = {
        border_color = {0, 0, 0, 0},
        cursor_box_type = 'not-allowed',
        mode = 'nothing',
    },
} --[[@as data.SelectionToolPrototype]] })
