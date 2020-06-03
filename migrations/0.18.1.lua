for _, player in pairs(game.players) do
    -- remove old static gui from gui.top
    local old_frame=mod_gui.get_frame_flow(player)[lrm.gui.frame]
    if old_frame then 
        old_frame.destroy() 
    end

    -- remove old unused button
    local old_button_flow=mod_gui.get_button_flow(player)
                        ["logistic-request-manager-button"]
    if old_button_flow then
        old_button_flow.destroy()
    end

    -- shift any existing presets up to make space for the default empty-template
	local player_presets = global["preset-names"][player.index]
	total = 0
	for number, name in pairs(player_presets) do
		if number > total then total = number end
    end
    
    for preset_number=total, 1, -1 do
        global["preset-names"][player.index][preset_number+1]=global["preset-names"][player.index][preset_number]
        global["preset-data"][player.index][preset_number+1]=global["preset-data"][player.index][preset_number]
    end
end