local mod_gui = require 'mod-gui'
if not gui then gui = {} end

function gui.build(player, open)
	if not player.force.technologies["character-logistic-slots-1"].researched then
		return nil
	end
	
	open = open or false

	local button_flow = mod_gui.get_button_flow(player)
	if button_flow["logistic-request-manager-button"] then
		button_flow["logistic-request-manager-button"].destroy()
	end
	
	local button = button_flow.add {
		type = "sprite-button",
		name = "logistic-request-manager-button",
		sprite = "item/logistic-robot",
		style = mod_gui.button_style,
		tooltip = {"gui.button-tooltip"}
	}
	button.visible = true
	
	local frame_flow = mod_gui.get_frame_flow(player)
	if frame_flow["logistic-request-manager-gui"] then
		frame_flow["logistic-request-manager-gui"].destroy()
	end
	
	local main_flow = frame_flow.add {
		type = "flow",
		name = "logistic-request-manager-gui",
		direction = "horizontal"
	}
	main_flow.visible = open
	
	local gui_frame = main_flow.add {
		type = "frame",
		caption = {"gui.title"},
		name = "logistic-request-manager-main-gui-frame",
		direction = "vertical",
		style = "logistic-request-manager-main-gui-frame"
	}
	
	local control_flow = gui_frame.add {
		type = "flow",
		name = "logistic-request-manager-control-flow",
		direction = "horizontal"
	}
	control_flow.style.vertical_align = "center"
	
	control_flow.add {
		type = "textfield",
		name = "logistic-request-manager-save-as",
		text = "",
		style = "logistic-request-manager-save-as-textfield"
	}
	
	control_flow.add {
		type = "button",
		name = "logistic-request-manager-save-as-button",
		caption = {"gui.save-as"},
		style = "logistic-request-manager-save-as-button"
	}
	
	control_flow.add {
		type = "sprite-button",
		name = "logistic-request-manager-blueprint-request",
		style = "slot_button",
		sprite = "item/blueprint",
		tooltip = {"gui.blueprint-request-tooltip"}
	}
	
	local requests_flow = gui_frame.add {
		type = "flow",
		name = "logistic-request-manager-request-flow",
		direction = "horizontal"
	}
	
	local presets_flow = requests_flow.add {
		type = "flow",
		name = "logistic-request-manager-request-preset-flow",
		direction = "vertical",
		style = "logistic-request-manager-preset-flow"
	}
	
	presets_flow.add {
		type = "button",
		name = "logistic-request-manager-save-preset-button",
		caption = "Save",
		tooltip = {"gui.save-preset-tooltip"},
		style = "logistic-request-manager-control-button"
	}
	
	presets_flow.add {
		type = "button",
		name = "logistic-request-manager-load-preset-button",
		caption = "Load",
		tooltip = {"gui.load-preset-tooltip"},
		style = "logistic-request-manager-control-button"
	}
	
	presets_flow.add {
		type = "button",
		name = "logistic-request-manager-delete-preset-button",
		caption = "Delete",
		tooltip = {"gui.delete-preset-tooltip"},
		style = "logistic-request-manager-control-button"
	}
	
	local presets_scroll_pane = presets_flow.add {
		type = "scroll-pane",
		name = "logistic-request-manager-preset-scroll-pane",
		horizontal_scroll_policy = "never",
		style = "logistic-request-manager-preset-scroll-pane"
	}
	
	local player_presets = global["preset-names"][player.index]
	for i,preset in pairs(player_presets) do
		presets_scroll_pane.add {
			type = "button",
			name = "logistic-request-manager-preset-button-" .. i,
			caption = preset,
			style = "logistic-request-manager-preset-button"
		}
	end
	
	local request_scroll_pane = requests_flow.add {
		type = "scroll-pane",
		name = "logistic-request-manager-request-scroll-pane",
		style = "logistic-request-manager-request-scroll-pane"
	}
	
	local request_table = request_scroll_pane.add {
		type = "table",
		name = "logistic-request-manager-request-table",
		column_count = 6
	}
	request_table.style.horizontal_align = "center"
	
	local slots = player.force.character_logistic_slot_count
	for i = 1, slots do
		local request = request_table.add {
			type = "choose-elem-button",
			name = "logistic-request-manager-request-slot-" .. i,
			elem_type = "item",
			style = "slot_button",
		}
		request.locked = true
	end
end

function gui.get_save_as_name(player)
	local save_as_field = mod_gui.get_frame_flow(player)
		["logistic-request-manager-gui"]
		["logistic-request-manager-main-gui-frame"]
		["logistic-request-manager-control-flow"]
		["logistic-request-manager-save-as"]
	return save_as_field.text
end

function gui.select_preset(player, preset_selected)
	preset_selected = "logistic-request-manager-preset-button-" .. preset_selected
	local preset_list = mod_gui.get_frame_flow(player)
		["logistic-request-manager-gui"]
		["logistic-request-manager-main-gui-frame"]
		["logistic-request-manager-request-flow"]
		["logistic-request-manager-request-preset-flow"]
		["logistic-request-manager-preset-scroll-pane"]
	for _, preset in pairs(preset_list.children) do
		if preset.name == preset_selected then
			preset.style = "logistic-request-manager-preset-button-selected"
			preset_list.scroll_to_element(preset)
		else
			preset.style = "logistic-request-manager-preset-button"
		end
	end
end

function gui.display_preset(player, preset_data)
	local request_table = mod_gui.get_frame_flow(player)
		["logistic-request-manager-gui"]
		["logistic-request-manager-main-gui-frame"]
		["logistic-request-manager-request-flow"]
		["logistic-request-manager-request-scroll-pane"]
		["logistic-request-manager-request-table"]
	local slots = player.force.character_logistic_slot_count
	for i = 1, slots do
		local item = preset_data and preset_data[i] and preset_data[i]["name"] or nil
		request_table.children[i].elem_value = item
	end
end

function gui.delete_preset(player, preset)
	local preset_list = mod_gui.get_frame_flow(player)
		["logistic-request-manager-gui"]
		["logistic-request-manager-main-gui-frame"]
		["logistic-request-manager-request-flow"]
		["logistic-request-manager-request-preset-flow"]
		["logistic-request-manager-preset-scroll-pane"]
	preset_list["logistic-request-manager-preset-button-" .. preset].destroy()
end

return gui