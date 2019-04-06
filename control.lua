local mod_gui = require 'mod-gui'

require 'defines'
require 'gui'

require 'scripts/globals'
require 'scripts/request-manager'
require 'scripts/blueprint-requests'

function select_preset(player, preset)
	gui.select_preset(player, preset)
	local data = global["preset-data"][player.index][preset]
	gui.display_preset(player, data)
	global["presets-selected"][player.index] = preset
end

script.on_event(defines.events.on_gui_click, function(event)
	local player = game.players[event.player_index]
	if not (player and player.valid) then return end
	local frame_flow = mod_gui.get_frame_flow(player)
	local gui_clicked = event.element.name
	
	if mod_gui.get_button_flow(player)["logistic-request-manager-button"] then
		gui.kill_old(player)
		gui.build(player)
		frame_flow[lrm.gui.frame].visible = true
		return
	end
	
	if gui_clicked == lrm.gui.toggle_button then
		if frame_flow[lrm.gui.frame].visible then
			frame_flow[lrm.gui.frame].visible = false
		else
			gui.force_rebuild(player, true)
			select_preset(player, global["presets-selected"][player.index])
		end
		
	elseif gui_clicked == lrm.gui.save_as_button then
		preset_name = gui.get_save_as_name(player)
		if preset_name == "" then
			player.print({"messages.name-needed"})
		else
			local new_preset = request_manager.save_preset(player, 0, preset_name)
			gui.force_rebuild(player, true)
			select_preset(player, new_preset)
		end
		
	elseif gui_clicked == lrm.gui.blueprint_button then
		request_manager.request_blueprint(player)
		
	elseif gui_clicked == lrm.gui.save_button then
		preset_selected = global["presets-selected"][player.index]
		if preset_selected == 0 then
			player.print({"messages.select-preset", {"messages.save"}})
		else
			request_manager.save_preset(player, preset_selected)
			select_preset(player, preset_selected)
		end
	
	elseif gui_clicked == lrm.gui.load_button then
		preset_selected = global["presets-selected"][player.index]
		if preset_selected == 0 then
			player.print({"messages.select-preset", {"messages.load"}})
		else
			request_manager.load_preset(player, preset_selected)
		end
	
	elseif gui_clicked == lrm.gui.delete_button then
		preset_selected = global["presets-selected"][player.index]
		if preset_selected == 0 then
			player.print({"messages.select-preset", {"messages.delete"}})
		else
			request_manager.delete_preset(player, preset_selected)
			gui.delete_preset(player, preset_selected)
			select_preset(player, 0)
		end
	
	else
		local preset_clicked = string.match(gui_clicked, string.gsub(lrm.gui.preset_button, "-", "%%-") .. "(%d+)")
		if preset_clicked then
			select_preset(player, tonumber(preset_clicked))
		end
	end
end)

script.on_event(defines.events.on_research_finished, function(event)
	if string.match(event.research.name, "character%-logistic%-slots%-%d+") then
		globals.init()
		
		for _, player in pairs(event.research.force.players) do
			globals.init_player(player)
			gui.force_rebuild(player)
			select_preset(player, global["presets-selected"][player.index])
		end
	end
end)
	
script.on_event(defines.events.on_player_created, function(event)
	local player = game.players[event.player_index]
	if not (player and player.valid) then return end
	
	globals.init_player(player)
	gui.build(player)
end)

script.on_init(function()
	globals.init()

	for _, player in pairs(game.players) do
		globals.init_player(player)
		gui.build(player)
	end
end)

script.on_configuration_changed(function()
	globals.init()
end)