if not request_manager then request_manager = {} end

function request_manager.request_blueprint(player, entity)
	entity = entity or player.character
	local blueprint = player.cursor_stack
	
	if not (blueprint and blueprint.valid and blueprint.valid_for_read) then
		return nil
	end
	
	if blueprint.is_blueprint_book and blueprint.active_index then
		blueprint = blueprint.get_inventory(defines.inventory.item_main)[blueprint.active_index]
	end
	
	if not blueprint.is_blueprint then
		return nil
	end
	
	if next(blueprint.cost_to_build) == nil then
		return nil
	end
	
	local required_slots = 0
	local blueprint_items = {}
	for item, count in pairs(blueprint.cost_to_build) do
		required_slots = required_slots + 1
		blueprint_items[item] = count
	end
	
	local free_slots = {}
	for i = 1, entity.request_slot_count do
		local request = entity.get_request_slot(i)
		if request then
			-- If the item is already being requested add the count rather than overwriting it
			if blueprint_items[request.name] then
				blueprint_items[request.name] = blueprint_items[request.name] + request.count
				required_slots = required_slots - 1
			end
		else
			free_slots[i] = true
		end
	end
	
	if required_slots > table_size(free_slots) then
		player.print({"messages.not-enough-slots"})
		return nil
	end
	
	for i = 1, entity.request_slot_count do
		local request = entity.get_request_slot(i)
		if request then
			if blueprint_items[request.name] then
				entity.set_request_slot({name = request.name, count = blueprint_items[request.name]}, i)
				blueprint_items[request.name] = nil
			end
		end
	end
	
	for name,count in pairs(blueprint_items) do
		local slot = next(free_slots, nil)
		free_slots[slot] = nil
		entity.set_request_slot({name = name, count = count}, slot)
	end
end

function request_manager.apply_preset(preset_data, entity)
	if entity.type == "character" then
		local slots = entity.character_logistic_slot_count
		
		for i = 1, slots do
			entity.clear_request_slot(i)
		end
		
		for i = 1, slots do
			local item = preset_data[i]
			if item and item.name then
				entity.set_personal_logistic_slot(i, item)
			end
		end
	else
		local slots = entity.request_slot_count
		
		for i = 1, slots do
			entity.clear_request_slot(i)
		end
		
		for i = 1, slots do
			local item = preset_data[i]
			if item and item.name then
				entity.set_request_slot({name=preset_data[i].name, count=item.min}, i)
			end
		end
	end
end

function request_manager.save_preset(player, preset_number, preset_name)
	local player_presets = global["preset-names"][player.index]
	local total = 0
	for number, name in pairs(player_presets) do
		if number > total then total = number end
		if preset_number == number then
			preset_name = name
		end
	end

	if preset_number == 0 then
		-- make sure to add new templates behind the protected one(s)
		if total==0 then total=table_size(global["protected_presets"][player.index]) end
		preset_number = total + 1
	end

	request_data = {}
	local slots = player.character_logistic_slot_count
	for i = 1, slots do
		local request = player.get_personal_logistic_slot(i)
		if request and request.name then
			request_data[i] = { name = request.name, min = request.min, max = request.max }
		else
			request_data[i] = {nil}
		end
	end
	
	global["preset-names"][player.index][preset_number] = preset_name
	global["preset-data"][player.index][preset_number] = request_data
	
	return preset_number
end

function request_manager.load_preset(player, preset_number)
	local player_presets = global["preset-data"][player.index]
	preset = player_presets[preset_number]
	if not preset then return end
	
	local chest_open = global["inventories-open"][player.index]
	
	if chest_open and chest_open.valid then
		request_manager.apply_preset(preset, chest_open)
	else
		request_manager.apply_preset(preset, player.character)
	end
end

function request_manager.delete_preset(player, preset_number)
	global["preset-names"][player.index][preset_number] = nil
	global["preset-data"][player.index][preset_number] = nil
end

function request_manager.check_preset_protected(player, preset_number, caller_function)
	local empty_protected = global["player_settings"][player.index][lrm.settings.persistent_empty_template]
	if empty_protected == nil then empty_protected = get_player_setting (player, lrm.settings.persistent_empty_template) end
	if (preset_number == 1) and ((empty_protected==true) or (caller_function=="save")) then
		return true
	end

	return false
end

function request_manager.create_empty_template(player)
	local slots = global["player_settings"][player.index][lrm.settings.empty_template_size]
	if slots == nil then slots = get_player_setting (player, lrm.settings.empty_template_size) end
	if slots < 0 then slots = 0 end

	-- adjust slot-count to the logistics tab: will always be a full decade minus one: 9, 19,...49...99
	slots = math.floor(slots/10) * 10 + 9

	request_data = {}
	for i = 1, slots do
		request_data[i] = {nil}
	end
	
	global["preset-names"][player.index][1] = {"gui.empty-template"}
	global["preset-data"][player.index][1] = request_data

	global["protected_presets"][player.index][1] = {"gui.empty-template"}
	
	return preset_number
end

function request_manager.shift_free_presets(player, offset)
    -- shift any existing free presets up to make space for protected ones
	local player_presets = global["preset-names"]
	
	
    if player_presets and player_presets[player.index]  then 
        local total_presets = 0
        for number, name in pairs(player_presets[player.index]) do
            if number > total_presets then total_presets = number end
        end
        
        local protected_prestes = global["protected_presets"]
        local lowest_preset_to_move = 1
		if protected_presets and protected_presets[player.index] then
            lowest_preset_to_move = total_presets - table_size(protected_presets[player.index])
		end
		
		if (offset == nil) or (offset <= 0) then offset = 1 end

		for preset_number=total_presets, lowest_preset_to_move, -1 do
            global["preset-names"][player.index][preset_number+offset]=global["preset-names"][player.index][preset_number]
            global["preset-data"][player.index][preset_number+offset]=global["preset-data"][player.index][preset_number]
        end
    end
end