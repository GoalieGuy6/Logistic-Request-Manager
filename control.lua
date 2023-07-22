require 'defines'
require 'gui'

require 'scripts/globals'
require 'scripts/request-manager'
require 'scripts/blueprint-requests'
require 'scripts/commands'



function lrm.select_preset(player, preset)
    if global["presets-selected"][player.index] == preset then
        return
    end
    lrm.gui.select_preset(player, preset)

    local data = table.deepcopy(global["preset-data"][player.index][preset])
    local preset_name = global["preset-names"][player.index][preset]

    if type(preset_name) == "table" 
     and table.concat(preset_name) == table.concat{ "gui.auto_trash", } then 
        local temp_data = {}
        for index, item in pairs (data) do
            if not((item.min or 0) == 0) or not ((item.max or 0) == 0)  then
                table.insert (temp_data, item)
            end
        end
        temp_data.notice={"messages.auto_trash"}
        data = temp_data
    end
    if type(preset_name) == "table" 
     and table.concat(preset_name) == table.concat{ "gui.keep_all", } then 
        local temp_data = {}
        for index, item in pairs (data) do
            if not((item.min or 0) == 0) or not ((item.max or 0xFFFFFFFF) == 0xFFFFFFFF)  then
                table.insert (temp_data, item)
            end
        end
        temp_data.notice={"messages.keep_all"}
        data = temp_data
    end

    lrm.gui.display_preset(player, data)
    global["presets-selected"][player.index] = preset
    lrm.gui.set_gui_elements_enabled(player)
end

script.on_event(defines.events.on_gui_click, function(event)
    if not event.element.get_mod() == "LogisticRequestManager" then return end
    local player = game.players[event.player_index]
    if not (player and player.valid) then return end
    local frame_flow = player.gui.screen
    local gui_clicked = event.element.name

    
    if gui_clicked == lrm.defines.gui.toggle_button then
        if (event.control and event.alt and event.shift) then 
            local selected_preset = global["presets-selected"][player.index]
            lrm.gui.force_rebuild(player)
            global["presets-selected"][player.index] = 0
            lrm.select_preset(player, selected_preset)
            return
        end
        lrm.close_or_toggle(event, true, nil)

    elseif gui_clicked == lrm.defines.gui.close_button then
        lrm.close_or_toggle(event, false)
    end

    if not lrm.check_logistics_available(player) then return end

    local modifiers = lrm.check_modifiers(event)

    if gui_clicked == lrm.defines.gui.save_as_button then
        local parent_frame = event.element.parent and event.element.parent.parent
        if not parent_frame then return end
        local preset_name = lrm.gui.get_save_as_name(player, parent_frame)
        if not preset_name or preset_name == "" then
            lrm.message(player, {"messages.name-needed"})
        else
            local new_preset = nil

            if parent_frame.name == lrm.defines.gui.frame then
                new_preset = lrm.request_manager.save_preset(player, 0, preset_name, modifiers)
            elseif parent_frame.name == lrm.defines.gui.import_preview_frame then
                new_preset = lrm.request_manager.save_imported_preset(player, preset_name, modifiers)
                if (new_preset) then
                    lrm.gui.hide_frame(player, lrm.defines.gui.import_frame)
                    lrm.gui.hide_frame(player, lrm.defines.gui.import_preview_frame)    
                end
            end
            if not (new_preset) then return end
            lrm.gui.clear_save_as_name(player, parent_frame)
            lrm.gui.build_preset_list(player)
            lrm.select_preset(player, new_preset)
        end
    
    elseif gui_clicked == lrm.defines.gui.blueprint_button then
        lrm.request_manager.request_blueprint(player, modifiers)
    
    elseif gui_clicked == lrm.defines.gui.save_button then
        local preset_selected = global["presets-selected"][player.index]
        if preset_selected == 0 then
            lrm.message(player, {"messages.select-preset", {"messages.save"}})
        else
            local preset_saved = lrm.request_manager.save_preset(player, preset_selected, nil, modifiers)
            if preset_saved then
                global["presets-selected"][player.index]=0
                lrm.select_preset(player, preset_saved)
            end
        end
    
    elseif gui_clicked == lrm.defines.gui.load_button then
        local preset_selected = global["presets-selected"][player.index]
        if preset_selected == 0 then
            lrm.message(player, {"messages.select-preset", {"messages.load"}})
        else
            lrm.request_manager.load_preset(player, preset_selected, modifiers)
        end
    
    elseif gui_clicked == lrm.defines.gui.delete_button then
        local preset_selected = global["presets-selected"][player.index]
        if preset_selected == 0 then
            lrm.message(player, {"messages.select-preset", {"messages.delete"}})
        else
            lrm.request_manager.delete_preset(player, preset_selected)
            lrm.gui.delete_preset(player, preset_selected)
            lrm.select_preset(player, 0)
        end
    
    elseif gui_clicked == lrm.defines.gui.import_button then
        local i_frame = lrm.gui.get_gui_frame(player, lrm.defines.gui.import_frame) 
        local p_frame = lrm.gui.get_gui_frame(player, lrm.defines.gui.import_preview_frame)
        if i_frame and i_frame.visible or p_frame and p_frame.visible then
            lrm.gui.hide_frame(player, lrm.defines.gui.import_frame)
            lrm.gui.hide_frame(player, lrm.defines.gui.import_preview_frame)
        else    
            lrm.gui.clear_import_string(player)
            lrm.gui.hide_frame(player, lrm.defines.gui.export_frame)
            lrm.gui.show_frame(player, lrm.defines.gui.import_frame)
        end
        
    elseif gui_clicked == lrm.defines.gui.export_button then
        local frame = lrm.gui.get_gui_frame(player, lrm.defines.gui.export_frame)
        if frame and frame.visible then
            lrm.gui.hide_frame(player, lrm.defines.gui.export_frame)
        else
            local preset_selected = global["presets-selected"][player.index]
            if preset_selected == 0 then
                lrm.message(player, {"messages.select-preset", {"messages.export"}})
            else
                local encoded_string = lrm.request_manager.export_preset(player, preset_selected, coded)
                if encoded_string and not (encoded_string == "")  then
                    lrm.gui.hide_frame(player, lrm.defines.gui.import_frame)
                    lrm.gui.hide_frame(player, lrm.defines.gui.import_preview_frame)
                    lrm.gui.display_export_code(player, encoded_string)
                end
            end
        end

        
    elseif gui_clicked == lrm.defines.gui.autotrash_button then
        local frame = lrm.gui.get_gui_frame(player, lrm.defines.gui.autotrash_frame)
        if frame and frame.visible then
            lrm.gui.hide_frame(player, lrm.defines.gui.autotrash_frame)
        else
            lrm.gui.hide_frame(player, lrm.defines.gui.network_frame)
            lrm.gui.show_frame(player, lrm.defines.gui.autotrash_frame)
        end
        

    elseif gui_clicked == lrm.defines.gui.OK_button then
        local parent_frame = event.element.parent and event.element.parent.parent

        if parent_frame and parent_frame.name == lrm.defines.gui.export_frame then
            lrm.gui.hide_frame(player, lrm.defines.gui.export_frame)
        elseif parent_frame and parent_frame.name == lrm.defines.gui.import_frame then
            local preset_data = lrm.request_manager.import_preset(player)
            if preset_data then
                lrm.gui.show_imported_preset(player, preset_data)
                lrm.gui.hide_frame(player, lrm.defines.gui.import_frame)
            end
        end

    else
        local gui_parent = event.element.parent
        if gui_parent then
            if  gui_parent.name == lrm.defines.gui.preset_list then
                local preset_clicked = string.match(gui_clicked, string.gsub(lrm.defines.gui.preset_button, "-", "%%-") .. "(%d+)")
                if preset_clicked then
                    lrm.select_preset(player, tonumber(preset_clicked))
                end
            end
        end
    end
end)

script.on_event({defines.events.on_research_finished, defines.events.on_research_reversed}, function(event)
    lrm.globals.init()
    
    for _, player in pairs(event.research.force.players) do
        lrm.globals.init_player(player)

        local selected_preset = global["presets-selected"][player.index]
        lrm.gui.force_rebuild(player)
        global["presets-selected"][player.index] = 0
        lrm.select_preset(player, selected_preset)
    end
end)


script.on_event( {defines.events.on_technology_effects_reset, defines.events.on_force_reset}, function(event)
    lrm.globals.init()
    
    for _, player in pairs(event.force.players) do
        lrm.globals.init_player(player)

        local selected_preset = global["presets-selected"][player.index]
        lrm.gui.force_rebuild(player)
        global["presets-selected"][player.index] = 0
        lrm.select_preset(player, selected_preset)
    end
end)

script.on_event(defines.events.on_forces_merged, function(event)
    lrm.globals.init()
    
    for _, player in pairs(event.destination.players) do
        lrm.globals.init_player(player)

        local selected_preset = global["presets-selected"][player.index]
        lrm.gui.force_rebuild(player)
        global["presets-selected"][player.index] = 0
        lrm.select_preset(player, selected_preset)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]
    if not (player and player.valid) then return end
    
    lrm.globals.init_player(player)
    lrm.recreate_empty_preset (player)
    if player.mod_settings["LogisticRequestManager-create_preset-autotrash"].value == true then
        lrm.recreate_autotrash_preset (player)
    end
    if player.mod_settings["LogisticRequestManager-create_preset-keepall"].value == true then
        lrm.recreate_keep_all_preset (player)
    end
    
    lrm.gui.force_rebuild(player)
end)

script.on_init(function()
    lrm.globals.init()
    lrm.commands.init()
    lrm.get_feature_level ()

    for _, player in pairs(game.players) do
        lrm.globals.init_player(player)
        lrm.recreate_empty_preset (player)
        if player.mod_settings["LogisticRequestManager-create_preset-autotrash"].value == true then
            lrm.recreate_autotrash_preset (player)
        end
        if player.mod_settings["LogisticRequestManager-create_preset-keepall"].value == true then
            lrm.recreate_keep_all_preset (player)
        end
        if ( lrm.check_logistics_available (player) ) then
            lrm.gui.build(player)
        end
    end
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.players[event.player_index]
    if not (player and player.valid) then return end

    lrm.globals.init_player(player)
    lrm.gui.set_gui_elements_enabled(player)
end)

script.on_configuration_changed(function(event)
    lrm.globals.init()
    if (event.new_version) then
        local game_version= util.split(event.new_version or "", ".")
        for i, v in pairs (game_version) do
            game_version[i]=tonumber(v)
        end

        if game_version[1]<1 or game_version[1] == 1 and game_version[2] == 0 then
            global.feature_level = "1.0"
        else
            global.feature_level = "1.1"
        end
    end
    
    if ( event.mod_changes 
        and event.mod_changes.LogisticRequestManager 
        and event.mod_changes.LogisticRequestManager.old_version ) then

        lrm.get_feature_level ()

        local version_map_1_0_0={import_export={0,18,4}, modifiers_combinator={0,18,7}, reduce_freeze={0,18,15}}
        local version_map_1_1_0={import_export={1,1,7},  modifiers_combinator={1,1,10}, reduce_freeze={1,1,18}, keep_all={1,1,19}}


        local old_version = util.split (event.mod_changes.LogisticRequestManager.old_version, ".") or nil
        for i, v in pairs (old_version) do
            old_version[i]=tonumber(v)
        end

        local new_versions ={}
        local new_how_to = false
        
        if (old_version[1]==0) or (old_version[1]==1 and old_version[2]==0) then 
            new_versions = version_map_1_0_0
        else 
            new_versions = version_map_1_1_0 
        end


        for _, player in pairs(game.players) do
            lrm.globals.init_player(player)
    
            if old_version[3] < new_versions.import_export[3] then 
                lrm.message( player, {"", {"messages.new_feature-export_import"}, " [color=yellow]", {"messages.new-gui"}, "[/color] " })
                new_how_to = true
            end

            if old_version[3] < new_versions.modifiers_combinator[3] then 
                lrm.move_presets (player)
                lrm.recreate_empty_preset (player)
                if player.mod_settings["LogisticRequestManager-create_preset-autotrash"].value == true then
                    lrm.recreate_autotrash_preset (player)
                end         

                lrm.message( player, {"", {"messages.new_feature-constant_combinator"}, " [color=yellow]", {"messages.new-setting"}, "[/color] " })
                lrm.message( player, {"", {"messages.new_feature-modifiers"}, " [color=yellow]", {"messages.new-settings"}, "[/color] " })

                new_how_to = true

                global["inventories-open"][player.index]=global["inventories-open"][player.index]~=nil
            end

            if old_version[3] < new_versions.reduce_freeze[3] then 
                if (player.mod_settings["LogisticRequestManager-display_slots_by_tick_ratio"].value==0) then
                    player.mod_settings["LogisticRequestManager-display_slots_by_tick_ratio"] = {value=10}
                end
            end

            if old_version[3] < new_versions.keep_all[3] then 
                if player.mod_settings["LogisticRequestManager-create_preset-keepall"].value == true then
                    lrm.recreate_keep_all_preset (player)
                end
            end

            if new_how_to then 
                lrm.message( player, {"", " [color=orange]", {"messages.new-how_to"}, "[/color]\n" })
            end

        end
    end

    for _, player in pairs(game.players) do
        lrm.globals.init_player(player)
        lrm.update_presets (player)

        if ( lrm.check_logistics_available (player) ) then
            local selected_preset = global["presets-selected"][player.index]
            lrm.gui.force_rebuild(player)
            global["presets-selected"][player.index] = 0
            lrm.select_preset(player, selected_preset)
        end
    end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    local player = event.player_index and game.players[event.player_index]
        
    if not (player and player.valid) then return end

    if (event.setting == "LogisticRequestManager-default_to_user") then 
        lrm.gui.set_gui_elements_enabled(player) 
    end
    if ( (event.setting == "LogisticRequestManager-allow_gui_without_research") or
         (event.setting == "LogisticRequestManager-hide_toggle_gui_button") ) then
            lrm.gui.force_rebuild(player)
    end
end)

script.on_event("LRM-input-toggle-gui", function(event)
    lrm.close_or_toggle(event, true)
end)
script.on_event("LRM-input-close-gui", function(event)
    lrm.close_or_toggle(event, false)
end)

script.on_event (defines.events.on_lua_shortcut, function(event)
    if (event.prototype_name == "shortcut-LRM-input-toggle-gui") then
        lrm.close_or_toggle(event, true)
    end
end)


function lrm.recreate_empty_preset (player)
    local preset = {}
    local max=40
    if (global.feature_level=="1.0") then
        max=39
    end
    for i = 1, max do
        preset[i] = { nil }
    end
    global["preset-data"][player.index][1]  = preset
    global["preset-names"][player.index][1] = {"gui.empty"}
    lrm.gui.build_preset_list(player)
end
function lrm.recreate_autotrash_preset (player)
    local preset={}
	local slots=0
	local last_subgroup = nil
	for _, item in pairs (game.item_prototypes) do 
        if not(item.subgroup=="other" or (item.flags and item.flags["hidden"]) ) then 
			if not (last_subgroup == item.subgroup or last_subgroup == nil) then
				slots = table_size(preset)
				if ( slots % 10 > 0 ) then	
					last_slot = slots + 10 - (slots % 10)
					for i = slots+1, last_slot do
						preset[i] = { nil }
					end
				end
			end
			last_subgroup = item.subgroup
            
			local item_grid = item.equipment_grid or (item.place_result and item.place_result.grid_prototype) or nil
            if not (item_grid) then
                -- check if item is in weapon or amunition
                table.insert(preset,{name=item.name or "", min=0, max=0, type="item"})
            else
                table.insert(preset,{name=item.name or "", min=0, max=0xFFFFFFFF, type="item"})
            end
        end
    end
    slots = table_size(preset)
    if ( slots % 10 > 0 ) then
        local last_slot
        if (global.feature_level == "1.0") then
            last_slot = slots + 9 - (slots % 10)
        else
            last_slot = slots + 10 - (slots % 10)
        end
        for i = slots+1, last_slot do
            preset[i] = { nil }
        end
    end
    global["preset-data"][player.index][2]  = preset
    global["preset-names"][player.index][2] = {"gui.auto_trash"}
    lrm.gui.build_preset_list(player)
end
function lrm.recreate_keep_all_preset (player)
    local preset={}
	local slots=0
	local last_subgroup = nil
    for _, item in pairs (game.item_prototypes) do 
        if not(item.subgroup=="other" or (item.flags and item.flags["hidden"]) ) then 
			if not (last_subgroup == item.subgroup or last_subgroup == nil) then
				slots = table_size(preset)
				if ( slots % 10 > 0 ) then	
					last_slot = slots + 10 - (slots % 10)
					for i = slots+1, last_slot do
						preset[i] = { nil }
					end
				end
			end
			last_subgroup = item.subgroup
            table.insert(preset,{name=item.name or "", min=0, max=0xFFFFFFFF, type="item"})
        end
    end
	
	slots = table_size(preset)
    if ( slots % 10 > 0 ) then
        local last_slot
        if (global.feature_level == "1.0") then
            last_slot = slots + 9 - (slots % 10)
        else
            last_slot = slots + 10 - (slots % 10)
        end
        for i = slots+1, last_slot do
            preset[i] = { nil }
        end
    end
    global["preset-data"][player.index][3]  = preset
    global["preset-names"][player.index][3] = {"gui.keep_all"}
    lrm.gui.build_preset_list(player)
end

function lrm.get_feature_level ()
    if (game.active_mods["LogisticRequestManager"]) then
        local base_version= util.split(game.active_mods["LogisticRequestManager"] or "", ".")
        for i, v in pairs (base_version) do
            base_version[i]=tonumber(v)
        end

        if base_version[1]<1 or base_version[1] == 1 and base_version[2] == 0 then
            global.feature_level = "1.0"
        else
            global.feature_level = "1.1"
        end
    end
end

function lrm.move_presets (player)
    if not (player) then return end

    local new_index = lrm.defines.protected_presets
    local new_data = {}
    local new_names = {}

    
    local player_preset_names = global["preset-names"][player.index]
    local player_preset_data  = global["preset-data"][player.index]

    for preset_number, preset_name in pairs(player_preset_names) do
        if preset_number then
            
            if type(preset_name) == "table" and 
             (   table.concat(preset_name) == table.concat{ "gui.empty", } 
              or table.concat(preset_name) == table.concat{ "gui.auto_trash", } 
              or table.concat(preset_name) == table.concat{ "gui.keep_all", } 
            ) then 
                -- do nothing.
            else
                local request_data = table.deepcopy(player_preset_data[preset_number])
                if request_data then
                    new_index = new_index + 1
                    if not (global.feature_level == "1.0") then
                        local slots = table_size(request_data)
                        if ( slots % 10 > 0 ) then
                            local slot_10 = slots + 10 - (slots % 10)
                            for i = slots+1, slot_10 do
                                request_data[i] = { nil }
                            end
                        end
                    end
                    new_data[new_index]  = request_data
                    new_names[new_index] = preset_name
                end
            end
        end
    end
    global["preset-names"][player.index] = new_names
    global["preset-data"][player.index]  = new_data
end

function lrm.update_presets ( player )
    if not player then return nil end

    local selected_preset = global["presets-selected"][player.index] or nil

    for preset_number, preset_name in pairs(global["preset-names"][player.index]) do
        if preset_number then
            if type(preset_name) == "table" then
                if ( table.concat(preset_name) == table.concat{ "gui.empty", } ) then
                    lrm.recreate_empty_preset( player )
                elseif ( table.concat(preset_name) == table.concat{ "gui.auto_trash", } ) then 
                    lrm.recreate_autotrash_preset( player )
                elseif ( table.concat(preset_name) == table.concat{ "gui.keep_all", } ) then 
                    lrm.recreate_keep_all_preset( player )
                else
                    lrm.check_preset ( player, preset_number )
                end
            else
                lrm.check_preset ( player, preset_number )
            end
        end
    end

    if (selected_preset) then
        global["presets-selected"][player.index]=0
        lrm.select_preset(player, selected_preset)
    end
end

function lrm.check_preset ( player, preset_number )
    local preset_data = global["preset-data"][player.index][preset_number]
    local preset_name = global["preset-names"][player.index][preset_number]
    local slots = table_size(preset_data)
    for i = 1, slots do
        local item = preset_data[i]
        if item.name then
            if item.type == nil then
                item.type = "item"
            end
            if item.max == "" then
                item.max = item.min
            end

            if ( ( item.type=="item"    and game.item_prototypes          [item.name] == nil )
              or ( item.type=="fluid"   and game.fluid_prototypes         [item.name] == nil )
              or ( item.type=="virtual" and game.virtual_signal_prototypes[item.name] == nil ) ) then
                lrm.message (player, {"messages.error-object-removed", {"common.The-" .. item.type}, item.name, serpent.line(preset_name)} )
            else
                if not ( item.type=="item" 
                      or item.type=="fluid"
                      or item.type=="virtual" ) then
                    lrm.message (player, {"messages.error-unsupported-type", item.type, item.name, serpent.line(preset_name)} )
                end
            end
        end
    end
end

function lrm.close_or_toggle (event, toggle)
    local player = event.player_index and game.players[event.player_index]
    if not player then return end
    
    local frame_flow = player and player.gui.screen
    local master_frame = frame_flow and frame_flow[lrm.defines.gui.master] or nil
    local parent_frame = event.element and event.element.parent.parent or nil
    if not (parent_frame and parent_frame.parent) then
        parent_frame = nil
    end

    if (event.element and event.element.name == "logistic-request-manager-gui-button" ) then
        parent_frame = nil
        if event.shift then
            global["screen_location"][player.index] = {85, 65}
            if master_frame then
                master_frame.location = {85, 65}
                master_frame.visible = false
            end
        end
    end

    if master_frame and master_frame.visible then
        global["screen_location"][player.index] = master_frame.location
        if not parent_frame or parent_frame.name == lrm.defines.gui.frame then
            master_frame.visible = false
        else
            parent_frame.visible = false
            if parent_frame.name == lrm.defines.gui.import_frame then
                lrm.gui.hide_frame(player, lrm.defines.gui.import_preview_frame)
            end
        end
    elseif toggle then
        if not master_frame then
            local preset_selected = global["presets-selected"][player.index]
            global["presets-selected"][player.index] = 0
            lrm.gui.build(player, true)
            lrm.select_preset(player, preset_selected)
        else
            master_frame.visible = true
        end
        
        if not ( lrm.check_logistics_available (player) ) then return end
        
        if not master_frame then master_frame = frame_flow and frame_flow[lrm.defines.gui.master] or nil end
        
        if master_frame and master_frame[lrm.defines.gui.frame] then 
            master_frame[lrm.defines.gui.frame].visible = true 
            lrm.gui.set_gui_elements_enabled(player)
            if not (global.feature_level == "1.0") then
                master_frame.bring_to_front()
            end
        end
    end
end

function lrm.message (player, localized_string)
    if not ( player and localized_string ) then 
        return
    end

    player.print ({"", "[color=yellow][LRM][/color] ", localized_string})
end

function lrm.error (player, localized_string)
    if not ( player and localized_string ) then 
        return
    end

    player.print ({"", "[color=red][LRM][/color] ", {"messages.Error"}, ": ", localized_string})
end


function lrm.check_modifiers(event)
    local matched_modifiers = {}

    if not (event and event.player_index) then return nil end
    
    local player = game.players[event.player_index]
    if not (player) then return nil end

    matched_modifiers["always_append_blueprints"]          = settings.get_player_settings(player)["LogisticRequestManager-always_append_blueprints"].value
    matched_modifiers["blueprint_item_requests_unlimited"] = settings.get_player_settings(player)["LogisticRequestManager-blueprint_item_requests_unlimited"].value
    
    matched_modifiers["remove"] = event.button == defines.mouse_button_type.middle

    matched_modifiers["subtract"] = event.button == defines.mouse_button_type.right
    matched_modifiers["subtract_max"] = matched_modifiers["append"] or false -- will be mapped to "append"

    local active_modifiers={}
    if event.shift   then table.insert(active_modifiers, "SHIFT") end
    if event.control then table.insert(active_modifiers, "CTRL") end
    if event.alt     then table.insert(active_modifiers, "ALT") end

    local my_settings = {}
    
    for setting_name, setting_data in pairs (player.mod_settings) do
        my_settings[setting_name]={value=setting_data.value}
    end

    local cnt=0
    for setting, setting_data in pairs(my_settings) do

        local start_pos, end_pos = string.find(setting, "LogisticRequestManager-modifier-", 1, true) -- should match on the last 3 settings

        if end_pos and end_pos > 0 then
             local modifier=string.sub (setting, end_pos+1)
            --player.print(setting .. " matches from " .. start_pos .. " to " .. end_pos .. " -> " .. modifier .. " - cnt:" .. cnt)
            local matched=nil

        

            local modifier_enabled_setting=my_settings["LogisticRequestManager-enable-" .. modifier]
            -- allowed_values for modifier_enabled_setting = {"never", "always", "on modifier", "not on modifier"}
            if (modifier_enabled_setting) then
                if (modifier_enabled_setting.value=="never") then
                    matched=false
                elseif (modifier_enabled_setting.value=="always") then
                    matched=true
                else
                    -- possible modifiers: {"CTRL", "SHIFT", "ALT", "CTRL+SHIFT", "CTRL+ALT", "SHIFT+ALT", "CTRL+SHIFT+ALT"}
                    local modifiers_matched=true
                    local modifier_value=util.split(setting_data.value,"+")
                    for _,required_modidier in pairs(modifier_value) do
                        local required_mod_matched = false
                        for _,available_modifier in pairs(active_modifiers) do
                            if (required_modidier==available_modifier) then required_mod_matched=true end
                        end
                        modifiers_matched=modifiers_matched and required_mod_matched
                    end
                    if (modifier_enabled_setting.value=="on_modifier") then
                        matched=modifiers_matched
                    elseif (modifier_enabled_setting.value=="not_on_modifier") then
                        matched=not modifiers_matched
                    else
                        matched=nil
                    end
                end

            end
            matched_modifiers[modifier]=matched
        else
            --player.print(setting .. " does not match - cnt:" .. cnt)
        end
    end

    matched_modifiers["subtract_max"] = matched_modifiers["append"] or false
    
    return matched_modifiers
end

function lrm.check_logistics_available (player)
    if not player then return false end

    -- lrm.message (player, "player.force.character_logistic_requests: " .. tostring(player.force.character_logistic_requests) )
    local allow_gui_without_research = settings.get_player_settings(player)["LogisticRequestManager-allow_gui_without_research"].value or false
    if not ( allow_gui_without_research
            --or ( player.force.technologies["logistic-robotics"] and player.force.technologies["logistic-robotics"]["researched"] )
            --or ( player.character and player.character.get_logistic_point(defines.logistic_member_index.character_requester) )
            or ( player.force.character_logistic_requests )
        ) then
        return false
    end
    return true
end

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
    local flag = string.match(event.element.name, string.gsub(lrm.defines.guiprefix, "-", "%%-") .. "flag%-(.+)" ) 
    if flag then
        local player_index = event.player_index
        local flags = global["flags"][player_index]
        flags[flag] = event.element.state
        if flag == "autotrash" and flags.autotrash then
            lrm.request_manager.update_autotrash(player_index)
            script.on_nth_tick(60, lrm.update_autotrash)
        end
    end
end)

function lrm.update_autotrash(event)
    clear_event = true
    for index, flags in pairs(global["flags"]) do
        lrm.request_manager.update_autotrash(index)
        if flags.autotrash then
            if flags.autotrash_automatic and (next(global["trash"][index]) == nil) then
                flags.autotrash = false
                local autotrash_frame = lrm.gui.get_gui_frame(game.players[index], lrm.defines.gui.autotrash_frame)
                local autotrash_flow = autotrash_frame[lrm.defines.gui.autotrash_flow]
                autotrash_flow[lrm.defines.guiprefix .. "flag-autotrash"].state=false
            else
                clear_event = false
            end
        end
    end
    if clear_event then
        script.on_nth_tick(60, nil)
    end
end