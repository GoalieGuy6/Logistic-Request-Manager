if not request_manager then request_manager = {} end

function request_manager.request_blueprint(player)
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
	
	local slots = 0
	local items = {}
	for item, count in pairs(blueprint.cost_to_build) do
		slots = slots + 1
		items[slots] = {name = item, count = count}
	end
	
	if slots > player.force.character_logistic_slot_count then
		player.print({"messages.not-enough-slots"})
		return nil
	end
	
	for i = 1, player.force.character_logistic_slot_count do
		if i <= slots then
			item = items[i]
			player.character.set_request_slot(item, i)
		else
			player.character.clear_request_slot(i)
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
	local slots = player.force.character_logistic_slot_count
	for i = 1, slots do
		local request = player.character.get_request_slot(i)
		if request then
			request_data[i] = { name = request.name, count = request.count }
		end
	end
	
	global["preset-names"][player.index][preset_number] = preset_name
	global["preset-data"][player.index][preset_number] = request_data
	
	return preset_number
end

function request_manager.load_preset(player, preset_number)
	local player_presets = global["preset-data"][player.index]
	
	request_data = player_presets[preset_number]
	
	local slots = player.force.character_logistic_slot_count
	for i = 1, slots do
		local item = request_data[i]
		if item then
			player.character.set_request_slot(item, i)
		else
			player.character.clear_request_slot(i)
		end
	end
end

function request_manager.delete_preset(player, preset_number)
	global["preset-names"][player.index][preset_number] = nil
	global["preset-data"][player.index][preset_number] = nil
end