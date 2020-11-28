for _, player in pairs(game.players) do
    local player_preset_names = global["preset-names"][player.index]
    local player_preset_data  = global["preset-data"][player.index]
    
    local new_data = {}
    local new_names = {}
    local new_index = 1
    
    local request_data = {}
	for i = 1, 40 do
        request_data[i] = { nil }
	end
    new_data[new_index]  = request_data
    new_names[new_index] = {"gui.empty"}
    player.print("[LRM] injected 'empty' preset")

    for preset_number, preset_name in pairs(player_preset_names) do
        if preset_number then
            local request_data = player_preset_data[preset_number]
            if request_data then
                new_index = new_index + 1
                local slots = table_size(request_data)
                if (slots % 10) then
                    local slot_10 = slots + 10 - (slots % 10)
                    for i = slots+1, slot_10 do
                        request_data[i] = { nil }
                    end
                    new_data[new_index]  = request_data
                    new_names[new_index] = preset_name
                    player.print("[LRM] updated preset #" .. preset_number .. " '" .. preset_name .. "' to #"..new_index)
                end
            end
        end
    end
    global["preset-names"][player.index] = new_names
    global["preset-data"][player.index]  = new_data
    global["presets-selected"][player.index]  = 1
    
    player.print("[LRM] Migration to 1.1.0 complete.")
end