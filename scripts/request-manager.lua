require 'defines'
if not lrm.request_manager then 
    lrm.request_manager = {} 
end

function lrm.request_manager.request_blueprint(player, modifiers)
    local entity = lrm.blueprint_requests.get_inventory_entity(player, {"messages.target-entity"}, {"messages.append"}, {"messages.blueprint"})
    if not (entity and entity.valid) then
        return nil
    end
    local blueprint = player.cursor_stack
    local blueprint_bom = {}
    
    if not (blueprint and blueprint.valid and blueprint.valid_for_read) then
        if (global.feature_level == "1.0") then
            lrm.message(player, {"messages.error-library_blueprints"})
            return nil
        else
            if player.is_cursor_blueprint() then 
                lrm.message(player, {"messages.library_blueprints"})
                for _, item in pairs(player.get_blueprint_entities()) do
                    blueprint_bom[item.name] = (blueprint_bom[item.name] or 0) + 1
                end
            else
                return nil
            end
        end
    else
        if blueprint.is_blueprint_book and blueprint.active_index then
            blueprint = blueprint.get_inventory(defines.inventory.item_main)[blueprint.active_index]
        end
        
        if not blueprint.is_blueprint then
            return nil
        end
        
        if next(blueprint.cost_to_build) == nil then
            return nil
        else
            blueprint_bom = blueprint.cost_to_build
        end
    end
    
    

    if modifiers.always_append_blueprints then -- this overwrites the other append-settings
        modifiers.append=true
    end
    
    local required_slots = 0
    local blueprint_data = {}
    for item, count in pairs(blueprint_bom) do
        if item and not (game.item_prototypes[item] == nil) then
            if (modifiers.blueprint_item_requests_unlimited or modifiers.undefined_max_as_infinit) then
                table.insert (blueprint_data, {name=item, min=count, max=0xFFFFFFFF, type="item"})
            else
                table.insert (blueprint_data, {name=item, min=count, max=count, type="item"})
            end
        end
    end

    lrm.request_manager.apply_preset(player, entity, blueprint_data, modifiers, {"messages.blueprint"})
end

function lrm.request_manager.get_current_data(player, entity, modifiers)
    if not (player or entity or data_to_apply) then 
        return
    end

    local logistic_requester = entity.get_logistic_point and entity.get_logistic_point(defines.logistic_member_index.character_requester) or false
    local logistic_provider  = entity.get_logistic_point and entity.get_logistic_point(defines.logistic_member_index.character_provider)  or false
    
    local current_data = {}
    local max_value = (modifiers and modifiers.undefined_max_as_infinit and 0xFFFFFFFF) or nil
    local target_supports_items_only = true

    if ( not logistic_requester    
        or ( not (logistic_requester.mode == defines.logistic_mode.requester )            -- no requester
        and not (logistic_requester.mode == defines.logistic_mode.buffer )  ) ) then     -- no buffer

        current_data = lrm.request_manager.pull_requests_from_constant_combinator(player, entity, max_value)
        target_supports_items_only = false
    else
        if not (logistic_provider) then                                                 -- no auto-trash
            current_data = lrm.request_manager.pull_requests_from_requester(player, entity, max_value)
        else
            current_data = lrm.request_manager.pull_requests_from_autotrasher(player, entity)
        end
    end
    return {
        data                        = current_data.data,
        slot_map                    = current_data.slot_map,
        free_slots                  = current_data.free_slots,
        slot_limit                  = current_data.slot_limit,
        highest_configured_slot     = current_data.highest_configured_slot,
        target_supports_items_only  = target_supports_items_only,
        logistic_requester          = logistic_requester,
        logistic_provider           = logistic_provider
    }
end

function lrm.request_manager.apply_preset(player, entity, data_to_apply, modifiers, localized_data_type)
    if not (player and entity and data_to_apply) then 
        return
    end
    if next ( data_to_apply ) == nil then 
        return
    end

    local current_dataset = lrm.request_manager.get_current_data(player, entity, modifiers)

    local logistic_requester = current_dataset.logistic_requester
    local logistic_provider  = current_dataset.logistic_provider
    local target_supports_items_only = current_dataset.target_supports_items_only

    local current_requests        = current_dataset.data
    local slot_map                = current_dataset.slot_map
    local free_slots              = current_dataset.free_slots
    local slot_limit              = current_dataset.slot_limit
    local highest_configured_slot = current_dataset.highest_configured_slot

    if modifiers.round_up then
        for index, item in pairs(data_to_apply) do
            if item and item.name then
                local min_count = data_to_apply[index].min or 0
                local stack_size= game.item_prototypes[item.name] and game.item_prototypes[item.name].stack_size or 1

                item.min = math.ceil (min_count / stack_size) * stack_size
                if not ( item.max ) or ( item.max < item.min ) then
                    item.max = item.min
                end
            end
        end
    end

    if modifiers.subtract then
        modifiers.append = true
        for index, item in pairs(data_to_apply) do
            if item and item.name then
                item.min = 0 - item.min
                if modifiers.subtract_max then
                    item.max = 0 - item.max
                else
                    item.max = 0
                end
            end
        end
    end

    if modifiers.remove then
        for index, item in pairs(data_to_apply) do
            if ( item and item.name 
                and (
                    ( ( item.type == nil or item.type == "item" ) and game.item_prototypes[item.name] )
                or ( ( not ( target_supports_items_only ) or append_at_end )
                and ( ( ( item.type == "fluid" ) and game.fluid_prototypes[item.name] )
                    or ( ( item.type == "virtual" or item.type == "virtual-signal" ) and game.virtual_signal_prototypes[item.name] ) ) ) )
                ) then
                local slot = nil
                local min_count = item.min
                local max_count = item.max and (item.max < 0 or item.max == 0xFFFFFFFF) and item.max or 0
                if slot_map[item.name] then
                    slot = slot_map[item.name]
                    if modifiers.remove then
                        slot_map[item.name]=nil
                        current_requests[slot]={}
                        free_slots[slot]=true
                    end
                end
            end
        end
        data_to_apply = current_requests
    elseif modifiers.append then

        local append_at_end = player.mod_settings["LogisticRequestManager-appended_requests_after_existing_ones"].value or true
        if append_at_end then 
            if (slot_limit) then 
                slot_limit = slot_limit + table_size(free_slots)
            end
            free_slots = {}
            -- make sure to add new items in new line
            if ( highest_configured_slot % 10 > 0 ) then
                local highest_configured_slot_full_row = highest_configured_slot + 10 - ( highest_configured_slot % 10 )
                for index = highest_configured_slot + 1, highest_configured_slot_full_row do
                    current_requests[index] = { nil }
                end
                highest_configured_slot = highest_configured_slot_full_row
            end
        end
        local matched_in_row = 0
        local empty_in_row   = 0
        for index, item in pairs(data_to_apply) do
            if ( item and item.name 
                and (
                    ( ( item.type == nil or item.type == "item" ) and game.item_prototypes[item.name] )
                or ( ( not ( target_supports_items_only ) or append_at_end )
                and ( ( ( item.type == "fluid" ) and game.fluid_prototypes[item.name] )
                    or ( ( item.type == "virtual" or item.type == "virtual-signal" ) and game.virtual_signal_prototypes[item.name] ) ) ) )
                ) then
                local slot = nil
                local min_count = item.min
                local max_count = item.max and (item.max < 0 or item.max == 0xFFFFFFFF) and item.max or 0
                if slot_map[item.name] then
                    slot = slot_map[item.name]
                    current_requests[slot].min = current_requests[slot].min + min_count
                    current_requests[slot].max = current_requests[slot].max + max_count
                    if ( append_at_end ) then
                        matched_in_row = matched_in_row + 1
                        highest_configured_slot = highest_configured_slot + 1
                        current_requests[highest_configured_slot] = {}
                        if ( slot_limit ) then 
                            slot_limit = slot_limit + 1
                        end
                    end
                else
                    slot = next(free_slots, nil)
                    if (slot) then
                        free_slots[slot] = nil
                    else
                        if not slot_limit or slot_limit > highest_configured_slot then
                            highest_configured_slot = highest_configured_slot + 1
                            slot=highest_configured_slot
                        else
                            lrm.message(player, {"messages.not-enough-slots-to-append", localized_data_type})
                            return
                        end
                    end
                    current_requests[slot] = item
                end
    
                if ( current_requests[slot].min < 0 ) then 
                    current_requests[slot].min = 0
                end
                if ( current_requests[slot].max > 0xFFFFFFFF ) then 
                    current_requests[slot].max = 0xFFFFFFFF
                end
                if ( current_requests[slot].max < current_requests[slot].min ) then 
                    current_requests[slot].max = current_requests[slot].min
                end
            else
                empty_in_row = empty_in_row + 1
                highest_configured_slot = highest_configured_slot + 1
                current_requests[highest_configured_slot] = {}
                if ( slot_limit ) then 
                    slot_limit = slot_limit + 1
                end
            end
            if (index % 10 == 0) then
                -- check for complete matched/empty line
                if ( matched_in_row > 0 ) and ( matched_in_row + empty_in_row == 10 ) then 
                    highest_configured_slot = highest_configured_slot - 10
                    if ( slot_limit ) then 
                        slot_limit = slot_limit - 10
                    end
                end
                matched_in_row = 0
                empty_in_row   = 0
            end
        end
        data_to_apply = current_requests
    end

    if ( not logistic_requester 
      or ( not (logistic_requester.mode == defines.logistic_mode.requester )                -- no requester
       and not (logistic_requester.mode == defines.logistic_mode.buffer )  ) ) then         -- no buffer
        
        lrm.request_manager.push_requests_to_constant_combinator(player, entity, data_to_apply, localized_data_type)

    else
        if not (logistic_provider) then                                                     -- no auto-trash
            lrm.request_manager.push_requests_to_requester(player, entity, data_to_apply, localized_data_type)
        else
            lrm.request_manager.push_requests_to_autotrasher(player, entity, data_to_apply, localized_data_type)
        end
    end
end

function lrm.request_manager.save_preset(player, preset_number, preset_name, modifiers)
    local entity = lrm.blueprint_requests.get_inventory_entity(player, {"messages.source-entity"}, {"messages.save"}, {"messages.preset"})
    if not (entity and entity.valid) then
        return nil
    end
    
    local current_dataset = lrm.request_manager.get_current_data(player, entity, modifiers)
    local request_data    = current_dataset.data

     
    local player_presets = global["preset-names"][player.index]
    local total = lrm.defines.protected_presets
    for number, name in pairs(player_presets) do
        if number > total then total = number end
        if preset_number == number then
            preset_name = name
        end
    end
    
    if preset_number == 0 then
        preset_number = total + 1
    end
    
    local configured_slots = 0

    for index, item in pairs(request_data) do
        if item and item.name then
            configured_slots = configured_slots + 1
            if modifiers.round_up then
                local min_count = item.min or 0
                local stack_size= game.item_prototypes[item.name] and game.item_prototypes[item.name].stack_size or 1

                item.min = math.ceil (min_count / stack_size) * stack_size
                if (item.max and item.max < item.min) then
                    item.max = nil
                end
            end
        end
    end

    local slot_count_warning = player.mod_settings["LogisticRequestManager-display_slots_warning"].value or true
    if slot_count_warning and ( configured_slots > lrm.defines.preset_slots_warning_level )  then
        lrm.message(player, {"messages.large_preset_warning"})
    end
    
    global["preset-names"][player.index][preset_number] = preset_name
    global["preset-data"][player.index][preset_number]  = request_data
    
    return preset_number
end

function lrm.request_manager.push_requests_to_requester( player, entity, data_to_push, localized_data_type )
    local set_slot = entity.set_request_slot

    if not set_slot then
        return nil
    end

    local slots = 1000
    if global.feature_level == "1.0" then
        slots = entity.request_slot_count
    end
    for index, item in pairs(data_to_push) do
        if ( item and item.name and ( (game.item_prototypes[item.name] == nil) or item.min < 1 ) ) then
            data_to_push[index] = {}
        end
    end

    -- count-check in 1.1.x no longer required here as slots can grow as required
    --if (global.feature_level == "1.0") then
        data_to_push = lrm.request_manager.check_slot_count ( player, data_to_push, slots, localized_data_type )
        if not data_to_push then 
            return 
        end
    --end
    -- end count-check

    -- clear current logistic slots
    for i = 1, slots do
        entity.clear_request_slot(i)
    end

    -- get required number of personal logistic slots
    slots = table_size(data_to_push or {})
    
    -- apply only items to request slots
    for i = 1, slots do
        local item = data_to_push[i]
        if item and item.name then
            set_slot({name=item.name, count=item.min}, i)
        end
    end
end
function lrm.request_manager.push_requests_to_autotrasher( player, entity, data_to_push, localized_data_type )
    local set_slot = nil
    local clear_slot = entity.clear_request_slot
    
    if entity.type == "character" then                -- easy & quite certain
        set_slot = entity.set_personal_logistic_slot
        if (global.feature_level == "1.0") then
            clear_slot = entity.clear_personal_logistic_slot
        end
    else                                              -- spidertron OK & quite sure that this will work for modded vehicles as well...
        if not (global.feature_level == "1.0") then
            set_slot = entity.set_vehicle_logistic_slot
        end
    end

    if not set_slot then
        return nil
    end

    -- check number of requests against available (max) slotcount
    local slots = 1000
    if global.feature_level == "1.0" then
        slots = entity.request_slot_count
    end
    data_to_push = lrm.request_manager.check_slot_count ( player, data_to_push, slots, localized_data_type )
    if not data_to_push then 
        return 
    end

    local slots = entity.request_slot_count

    -- clear current logistic slots
    for i = 1, slots do
        clear_slot(i)
    end

    -- get required number of personal logistic slots
    slots = table_size(data_to_push or {})
    
    -- adjust request slots - no longer required in 1.1.x as requestslots are automatically generated as required
    if (global.feature_level == "1.0") then
        entity.character_logistic_slot_count = slots
    end
    -- end adjust request slots

    -- apply only items to request slots
    for i = 1, slots do
        local item = data_to_push[i]
        if item and item.name and not (game.item_prototypes[item.name] == nil) then
            set_slot(i, item)
        end
    end
end
function lrm.request_manager.push_requests_to_constant_combinator( player, entity, data_to_push, localized_data_type )
    local control_behavior = entity and entity.get_control_behavior and entity.get_control_behavior()

    if not ( control_behavior 
        and (control_behavior.type == defines.control_behavior.type.constant_combinator) ) then
        return nil
    end

    local slots = control_behavior.signals_count
    local set_slot = control_behavior.set_signal
    
    if not (slots and set_slot) then
        return nil
    end

    -- count-check in 1.1.x only required here as all other slots can grow as required
    data_to_push = lrm.request_manager.check_slot_count ( player, data_to_push, slots, localized_data_type )
    if not data_to_push then 
        return 
    end
    -- end count-check

    for i = 1, slots do
        local item = data_to_push[i]
        if item and item.name then
            local signal_id={type=item.type or "item", name=item.name}
            local signal={signal=signal_id, count=item.min}
            set_slot(i, signal)
        else -- clear slot
            set_slot (i, nil)
        end
    end
end

function lrm.request_manager.check_slot_count ( player, data_to_push, max_available_slots, localized_data_type )
    local signal_count = table_size(data_to_push)
    if max_available_slots and ( signal_count > max_available_slots ) then
        local valid_slots        = {}
        local valid_slot_count   = 0
        local highest_valid_slot = 0
        for i = 1, signal_count do
            local item = data_to_push[i]
            if ( item.name and (
                ( (item.type == nil or item.type == "item") and game.item_prototypes[item.name] )
             or ( (item.type == "fluid") and game.fluid_prototypes[item.name] )
             or ( (item.type == "virtual" or item.type == "virtual-signal") and game.virtual_signal_prototypes[item.name] )
               ) ) then
                valid_slot_count              = valid_slot_count + 1
                highest_valid_slot            = i
                valid_slots[valid_slot_count] = item
                --player.print("found valid item #"..valid_slot_count..":"..item.name)
            end
        end
        
        if valid_slot_count > max_available_slots then
            lrm.message(player, {"messages.not-enough-slots-to-request", localized_data_type})
            data_to_push = nil
        else
            if highest_valid_slot > max_available_slots then
                lrm.message(player, {"messages.removed-empty-request-slots", localized_data_type})
                data_to_push = valid_slots
            end
        end
    end
    return data_to_push
end

function lrm.request_manager.pull_requests_from_requester( player, entity, max_value)
    local get_slot = entity.get_request_slot
    local slots    = entity.request_slot_count
    
    if not (slots and get_slot) then
        return nil
    end
    
    local current_slots           = {}
    local free_slots              = {}
    local slot_map                = {}
    local highest_configured_slot = 0
    
    for i = 1, slots do
        local request = get_slot(i)
        if request and request.name then
            highest_configured_slot = i
            current_slots[i]        = { name = request.name, min = request.count, max = max_value or request.count, type ="item" }
            slot_map[request.name]  = i
        else
            current_slots[i] = { nil }
            free_slots[i]    = true
        end
    end

    return {data                    = current_slots, 
            slot_map                = slot_map, 
            free_slots              = free_slots, 
            slot_limit              = (global.feature_level=="1.0") and slots or 1000, 
            highest_configured_slot = highest_configured_slot}

end
function lrm.request_manager.pull_requests_from_autotrasher( player, entity )
    local get_slot = nil
    if entity.type == "character" then                -- easy & quite certain
        get_slot = entity.get_personal_logistic_slot
    else                                              -- spidertron OK & quite sure that this will work for modded vehicles as well...
        get_slot = entity.get_vehicle_logistic_slot
    end
    local slots  = entity.request_slot_count
    
    if not (slots and get_slot) then
        return nil
    end
    
    local current_slots           = {}
    local free_slots              = {}
    local slot_map                = {}
    local highest_configured_slot = 0
    
    for i = 1, slots do
        local request = get_slot(i)
        if request and request.name then
            highest_configured_slot = i
            current_slots[i] = { name = request.name, min = request.min, max = request.max, type ="item" }
            slot_map[request.name] = i
        else
            current_slots[i] = { nil }
            free_slots[i]    = true
        end
    end

    return {data                    = current_slots, 
            slot_map                = slot_map, 
            free_slots              = free_slots, 
            slot_limit              = 1000, 
            highest_configured_slot = highest_configured_slot}
end
function lrm.request_manager.pull_requests_from_constant_combinator( player, entity, max_value )
    local control_behavior = entity and entity.get_control_behavior and entity.get_control_behavior()

    if not ( control_behavior 
        and (control_behavior.type == defines.control_behavior.type.constant_combinator) ) then
        return nil
    end

    local slots    = control_behavior.signals_count
    local get_slot = control_behavior.get_signal
    
    if not (slots and get_slot) then
        return nil
    end

    local current_slots = {}
    local free_slots    = {}
    local slot_map      = {}
    local highest_configured_slot = 0

    for i = 1, slots do
        local signal = get_slot(i)
        if (signal and signal.signal) then
            highest_configured_slot = i
            local signal_id = signal.signal
            -- if  ( signal_id.type == "item" 
            --     and signal_id.name ) then
                slot_map[signal_id.name] = i
            -- end
            current_slots[i] = {name = signal_id.name, min = signal.count, max = max_value or signal.count, type = signal_id.type}
        else
            current_slots[i] = { nil }
            free_slots[i]    = true
        end
    end

    return {data                    = current_slots, 
            slot_map                = slot_map, 
            free_slots              = free_slots, 
            slot_limit              = slots, 
            highest_configured_slot = highest_configured_slot}
end

function lrm.request_manager.load_preset(player, preset_number, modifiers)
    local player_presets = global["preset-data"][player.index]
    local preset_data = table.deepcopy(player_presets[preset_number])
    if not preset_data then return end
    
    local entity = lrm.blueprint_requests.get_inventory_entity(player, {"messages.target-entity"}, {"messages.load"}, {"messages.preset"})
    if entity and entity.valid then
        lrm.request_manager.apply_preset(player, entity, preset_data, modifiers, {"messages.preset"})
    else
        return nil
    end
end

function lrm.request_manager.delete_preset(player, preset_number)
    global["preset-names"][player.index][preset_number] = nil
    global["preset-data"][player.index][preset_number] = nil
end

function lrm.request_manager.import_preset(player)
    local encoded_string = lrm.gui.get_import_string(player)
    if not (encoded_string) or encoded_string == "" then
        return nil
    end

    local decoded_string = game.decode_string(encoded_string)
    if decoded_string and (decoded_string ~= "") then
        local preset_data = game.json_to_table(decoded_string)
        if preset_data and (next(preset_data) ~= nil) then
            local last_slot = table_size (preset_data)
            local version_imported = preset_data[last_slot].LRM_preset_version or 0
            if ( version_imported <  lrm.defines.preset_string_version ) then
                if ( version_imported < 2 ) then
                    for index, dataset in pairs(preset_data) do
                        if  ( version_imported == 1 ) then -- only items were exported here
                            dataset.type="item"
                        elseif not dataset.name then
                            -- ?
                        elseif game.virtual_signal_prototypes[dataset.name] then
                            dataset.type="virtual"
                        elseif game.fluid_prototypes[dataset.name] then
                            dataset.type="fluid"
                        elseif game.item_prototypes[dataset.name] then
                            dataset.type="item"
                        end
                    end
                end
            end
            return preset_data
        end
    end
    lrm.error(player, {"messages.error-invalid-string"})
    return nil
end

function lrm.request_manager.save_imported_preset(player, preset_name)
    local preset_data = lrm.request_manager.import_preset(player)
    local last_slot = table_size (preset_data)
    
    if (preset_data[last_slot].LRM_preset_name) then
        preset_data[last_slot] = nil
    end

    local player_presets = global["preset-names"][player.index]
    local total = 0
    for number, name in pairs(player_presets) do
        if number > total then total = number end
    end
    
    local preset_number = total + 1

    local configured_slots = 0

    for index, item in pairs(preset_data) do
        if item and item.name then
            configured_slots = configured_slots + 1
        end
    end

    local slot_count_warning = player.mod_settings["LogisticRequestManager-display_slots_warning"].value or true
    if slot_count_warning and ( configured_slots > lrm.defines.preset_slots_warning_level )  then
        lrm.message(player, {"messages.large_preset_warning"})
    end
    
    global["preset-names"][player.index][preset_number] = preset_name
    global["preset-data"][player.index][preset_number]  = preset_data

    return preset_number
end

function lrm.request_manager.export_preset(player, preset_number, coded)
    local preset_table = {}

    local preset_name = global["preset-names"][player.index][preset_number]
    local preset_data = global["preset-data"][player.index][preset_number]
    local slots = table_size(preset_data) or 0

    if slots > 0 then
        for i = 1, slots do
            local slot = preset_data[i]
            if slot.name ~= nil then
                table.insert(preset_table, slot)
            else
                table.insert(preset_table, "")
            end
        end
    end

    table.insert(preset_table, {LRM_preset_version = lrm.defines.preset_string_version, LRM_preset_name = preset_name[1] or preset_name})
    local jsoned_table   = game.table_to_json(preset_table)
    local encoded_string = game.encode_string(jsoned_table)

    return encoded_string
end

function lrm.request_manager.autotrash_inventory(player_index)
    local player=game.players[player_index] or nil
    if not player then
        return
    end

    local character = player.character
    if not character then
        return
    end

    --local modifiers = lrm.check_modifiers({player_index=player.index})

    local current_dataset   = lrm.request_manager.get_current_data(player, character)

    local current_requests  = current_dataset.data
    local request_slot_map  = current_dataset.slot_map

    local inventory         = character.get_main_inventory()
    local inventory_items   = inventory.get_contents()

    local flags = global["flags"][player_index]

    local filtered_prototypes = lrm.request_manager.get_filtered_prototypes (player_index, true, "and")

    local trash_items = global["trash"][player_index]
    local update = false
    local trashnotempty = next(trash_items) ~= nil
    -- local last_subgroup

    for name, prototype in pairs(filtered_prototypes) do
        if inventory_items[name] and not request_slot_map[name] then
            if ( ( not (not flags.trash_gridded_items and ( prototype.equipment_grid or (prototype.place_result and prototype.place_result.grid_prototype) ) ) )
            and  ( not (not flags.trash_remotes and string.find(prototype.name, "remote", 0, true ) ) ) ) then
                table.insert(trash_items,{name=prototype.name or "", min=0, max=0, type="item"})
                update = true
            end
        end
    end
    
    if update then
        if (trashnotempty) then
            lrm.request_manager.clear_autotrash(player_index)
        end
        local modifiers = {append = true, appendinline = appendinline}
        lrm.request_manager.apply_preset(player, character, trash_items, modifiers, {"messages.autotrash_dataset"})

        global["trash"][player_index] = trash_items
    end
end

function lrm.request_manager.clear_autotrash(player_index)
    local player=game.players[player_index] or nil
    if not player then
        return
    end

    local character = player.character
    if not character then
        return
    end

    local modifiers = {remove = true}
    
    lrm.request_manager.apply_preset(player, character, global["trash"][player_index], modifiers, {"messages.autotrash_dataset"})
    global["trash"][player_index] = {}
end

function lrm.request_manager.update_autotrash(player_index)
    local player=game.players[player_index] or nil
    if not player then
        return
    end

    local character = player.character
    if not character then
        return
    end

    local trash_items = global["trash"][player.index]
    local flags=global["flags"][player_index]
    local update = not flags.autotrash
    if not (next(trash_items) == nil) then
        local inventory         = character.get_main_inventory()
        local inventory_items   = inventory.get_contents()
        
        local trash_map = {}
        for index, item in pairs(trash_items) do
            if not (inventory_items[item.name]) then
                update = true
                break
            else
                trash_map[item.name]=index
            end
        end

        local filtered_prototypes = lrm.request_manager.get_filtered_prototypes (player_index, true, "and")
        if not ( update and (next(trash_map) == nil) ) then
            for name, prototype in pairs(filtered_prototypes) do
                if trash_map[name] then
                    if ( ( not (not flags.trash_gridded_items and ( prototype.equipment_grid or (prototype.place_result and prototype.place_result.grid_prototype) ) ) )
                    and  ( not (not flags.trash_remotes and string.find(prototype.name, "remote", 0, true ) ) ) ) then
                                 update = true
                        break
                    end
                end
            end
        end
    end
    
    
    if update then
        lrm.request_manager.clear_autotrash(player_index)
    end
    if flags.autotrash then
        lrm.request_manager.autotrash_inventory(player_index)
    end
end

function lrm.request_manager.get_filtered_prototypes (player_index, invert, mode)
    if not game.players[player_index] then 
        return
    end

    local flags=global["flags"][player_index] 

    local filters = {}
    if (not flags.trash_selection_tools==invert) then
        -- table.insert (filters, {filter = "selection-tool", invert = true, mode = "and"} )
        table.insert (filters, {filter = "type", type = "selection-tool", invert = true, mode = "and"} )
    end
    if (not flags.trash_blueprints==invert) then
        table.insert (filters, {filter = "type", type = "blueprint", invert = invert, mode = mode} )
    end
    if (not flags.trash_blueprint_books==invert) then
        table.insert (filters, {filter = "type", type = "blueprint-book", invert = invert, mode = mode} )
    end
    if (not flags.trash_deconstruction_planers==invert) then
        table.insert (filters, {filter = "type", type = "deconstruction-item", invert = invert, mode = mode} )
    end
    if (not flags.trash_upgrade_planers==invert) then
        table.insert (filters, {filter = "type", type = "upgrade-item", invert = invert, mode = mode} )
    end
    if (not flags.trash_copy_paste_tools==invert) then
        table.insert (filters, {filter = "type", type = "copy-paste-tool", invert = invert, mode = mode} )
    end
    if (not flags.trash_hidden_items==invert) then
        table.insert (filters, {filter = "flag", flag = "hidden", invert = invert, mode = mode} )
    end

    return game.get_filtered_item_prototypes(filters)
end