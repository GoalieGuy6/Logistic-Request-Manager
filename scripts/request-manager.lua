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
	total = 0
	for number, name in pairs(player_presets) do
		if number > total then total = number end
		if preset_number == number then
			preset_name = name
		end
	end

	if preset_number == 0 then
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