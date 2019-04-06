function get_event_entities(event)
	if event.gui_type ~= defines.gui_type.entity or event.entity.request_slot_count < 1 then
		return nil, nil
	end
	
	return game.players[event.player_index], event.entity
end

function on_tick()
	local chests = global["chests-open"] or {}
	
	if table_size(chests) == 0 then
		unregister_on_tick()
		return
	end
	
	for player_index,chest in pairs(chests) do
		local player = game.players[player_index]
		if not (player and player.valid) then
			global["chests-open"][player_index] = nil
			return
		end
		
		for slot = 1, chest.request_slot_count do
			local request = chest.get_request_slot(slot)
			if request and (request.name == "blueprint" or request.name == "blueprint-book") then
				chest.clear_request_slot(slot)
				request_manager.request_blueprint(player, chest)
			end
		end
	end
end

function register_on_tick()
	global.on_tick = true
	script.on_event(defines.events.on_tick, on_tick)
end

function unregister_on_tick()
	global.on_tick = false
	script.on_event(defines.events.on_tick, nil)
end

function check_on_tick()
	if global.on_tick and table_size(global["chests-open"]) == 0 then
		unregister_on_tick()
	end
end

script.on_event(defines.events.on_gui_opened, function(event)
	global["chests-open"] = global["chests-open"] or {}

	local player, chest = get_event_entities(event)
	if not (player and chest) then return end
	
	global["chests-open"][player.index] = chest
	
	register_on_tick()
end)

script.on_event(defines.events.on_gui_closed, function(event)
	local player, chest = get_event_entities(event)
	if not (player and chest) then return end
	
	global["chests-open"][player.index] = nil
	check_on_tick()
end)

script.on_load(function()
	if global.on_tick then
		register_on_tick()
	end
end)