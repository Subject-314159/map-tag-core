local gui = require("scripts.gui")
local gps = require("scripts.gps")

local function init_global_player(player_index)
    if not global.players then
        global.players = {}
    end

    if not global.players[player_index] then
        global.players[player_index] = {
            destinations = {},
            bookmarks = {}
        }
    end
end

local function global_init()
    for _, p in pairs(game.players) do
        init_global_player(p.index)
    end

    gui.init()
    gps.init()

    -- Remove all destinations if teleport is installed
    if game.active_mods["map-tag-teleport"] then
        for _, p in pairs(game.players) do
            gps.remove_all(p.index)
        end
    end

end

------------------------------------------------------------------------------------------
-- Game mechanics
------------------------------------------------------------------------------------------

script.on_event(defines.events.on_tick, function()
    gps.tick_update()
    gui.tick_update()
end)

script.on_init(function(e)
    global_init()
end)

script.on_configuration_changed(function(e)
    global_init()
end)

script.on_event(defines.events.on_player_created, function(e)
    if not global then
        global_init()
    end
    init_global_player(e.player_index)
end)

script.on_event(defines.events.on_chart_tag_added, function(e)
    -- Check if tag is GPS tag
    if game.active_mods["map-tag-gps"] and e.tag.text == settings.global["gps_tag-name"].value then
        gps.set_destination(e.player_index, e.tag)
    end
end)

script.on_event(defines.events.on_chart_tag_removed, function(e)
    gps.invalidate_tag(e.tag)
end)

---------------------------------------------------------------------------
-- SHORTCUTS
---------------------------------------------------------------------------

-- script.on_event(defines.events.on_lua_shortcut, function(e)
--     if not game.get_player(e.player_index) then
--         return
--     end

--     if e.prototype_name == "mt_toggle-gui" then
--         gui.toggle(e.player_index)
--     end
--     if e.prototype_name == "mt_set-gps-selection-tool" then
--         gps.give_selection_tool(e.player_index)
--     end
-- end)

-- script.on_event("mt_toggle-gui", function(e)
--     gui.toggle(e.player_index)
-- end)

script.on_event(defines.events.on_player_selected_area, function(e)
    -- Get the player that used the selection tool
    local player = game.get_player(e.player_index)
    if not player then
        return
    end

    -- Check if the selection tool is our tool
    local cursor_stack = player.cursor_stack
    if not cursor_stack or not cursor_stack.valid or not cursor_stack.valid_for_read then
        return
    end
    if cursor_stack.name == "mt_gps-selection-tool" then
        -- Get variables
        local mod_teleport = game.active_mods["map-tag-teleport"] ~= nil
        local mod_gps = game.active_mods["map-tag-gps"] ~= nil
        local mod_both = mod_teleport and mod_gps
        local ctrl_click_teleports = settings.global["mtc_ctrl-click-behavior"] and
                                         settings.global["mtc_ctrl-click-behavior"].value == "mtc_teleport"

        -- Process the action
        if (mod_both and not ctrl_click_teleports) or (not mod_both and mod_teleport) then
            -- If map tag teleport is installed, teleport instead
            local pos = {
                x = (e.area.left_top.x + e.area.right_bottom.x) / 2,
                y = (e.area.left_top.y + e.area.right_bottom.y) / 2

            }
            if gps.teleport_to_position(e.player_index, pos, e.surface) then
                if settings.global["gps_announce-teleport"].value then
                    player.print(
                        "[GPS] Teleported to [gps=" .. (pos.x) .. "," .. (pos.y) .. "," .. player.surface.name .. "]")
                end
            end
        else
            -- Create temporary stop
            gps.create_from_selection(e.player_index, e.surface, e.area)
        end
    end
end)

script.on_event(defines.events.on_gui_click, function(e)
    if e.element.name == "mt_tag-button" then
        -- Get the tag
        local player = game.get_player(e.player_index)
        if not player then
            return
        end
        local srf = game.get_surface(e.element.tags.surface)
        local tag
        for _, t in pairs(player.force.find_chart_tags(srf)) do
            if t.tag_number == e.element.tags.tag_id then
                tag = t
                break
            end
        end

        -- Process the action
        local mod_teleport = game.active_mods["map-tag-teleport"] ~= nil
        local mod_gps = game.active_mods["map-tag-gps"] ~= nil
        local mod_both = mod_teleport and mod_gps
        local ctrl_click_teleports = settings.global["mtc_ctrl-click-behavior"] and
                                         settings.global["mtc_ctrl-click-behavior"].value == "mtc_teleport"

        if mod_both then
            if ctrl_click_teleports and e.control or (not ctrl_click_teleports and not e.control) then
                gps.teleport_to_tag(e.player_index, tag)
            else
                gps.set_destination(e.player_index, tag)
            end
        else
            if mod_teleport then
                gps.teleport_to_tag(e.player_index, tag)
            else
                -- Fallback set gps
                gps.set_destination(e.player_index, tag)
            end
        end

        if (mod_both and ctrl_click_teleports and e.control) or (not mod_both and mod_teleport) then
        end
    elseif e.element.name == "mt_remove-all-destinations" then
        gps.remove_all(e.player_index)
    elseif e.element.name == "mt_bookmark-button" then
        gui.bookmark(e.player_index, e.element)
    end
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(e)
    -- Get some variables to work with
    local player = game.get_player(e.player_index)
    if not player then
        return
    end
    local cursor_stack = player.cursor_stack

    -- Check if this is our tool
    if (cursor_stack and cursor_stack.valid and cursor_stack.valid_for_read and cursor_stack.name ==
        "mt_gps-selection-tool") then
        gui.build_main(player)
    else
        gui.destroy_main(player)
    end
end)
