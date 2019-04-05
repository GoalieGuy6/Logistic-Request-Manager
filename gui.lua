local mod_gui = require 'mod-gui'
if not gui then gui = {} end

function gui.build_toggle_button(player)
	local button_flow = mod_gui.get_button_flow(player)
	if not button_flow[lrm.gui.toggle_button] then
		button_flow.add {
			type = "sprite-button",
			name = lrm.gui.toggle_button,
			sprite = "item/logistic-robot",
			style = mod_gui.button_style,
			tooltip = {"gui.button-tooltip"}
		}
	end
end

function gui.build_main_frame(player)
	local frame_flow = mod_gui.get_frame_flow(player)
	if frame_flow[lrm.gui.frame] then
		return nil
	end
	
	local gui_frame = frame_flow.add {
		type = "frame",
		name = lrm.gui.frame,
		style = lrm.gui.frame,
		caption = {"gui.title"},
		direction = "vertical"
	}
	gui_frame.visible = false
	
	local gui_toolbar = gui_frame.add {
		type = "flow",
		name = lrm.gui.toolbar,
		direction = "horizontal"
	}
	gui_toolbar.style.vertical_align = "center"
	
	gui_toolbar.add {
		type = "textfield",
		name = lrm.gui.save_as_textfield,
		style = lrm.gui.save_as_textfield
	}
	
	gui_toolbar.add {
		type = "button",
		name = lrm.gui.save_as_button,
		style = lrm.gui.save_as_button,
		caption = {"gui.save-as"}
	}
	
	gui_toolbar.add {
		type = "sprite-button",
		name = lrm.gui.blueprint_button,
		style = lrm.gui.blueprint_button,
		sprite = "item.blueprint",
		tooltip = {"gui.blueprint-request-tooltip"}
	}
	
	local gui_body = gui_frame.add {
		type = "flow",
		name = lrm.gui.body,
		direction = "horizontal"
	}
	
	local sidebar = gui_body.add {
		type = "flow",
		name = lrm.gui.sidebar,
		style = lrm.gui.sidebar,
		direction = "vertical"
	}
	
	local sidebar_menu = sidebar.add {
		type = "flow",
		name = lrm.gui.sidebar_menu,
		direction = "horizontal"
	}
	
	sidebar_menu.add {
		type = "button",
		name = lrm.gui.save_button,
		style = lrm.gui.sidebar_button,
		caption = {"gui.save"},
		tooltip = {"gui.save-preset-tooltip"}
	}
	
	sidebar_menu.add {
		type = "button",
		name = lrm.gui.load_button,
		style = lrm.gui.sidebar_button,
		caption = {"gui.load"},
		tooltip = {"gui.load-preset-tooltip"}
	}
	
	sidebar_menu.add {
		type = "button",
		name = lrm.gui.delete_button,
		style = lrm.gui.sidebar_button,
		caption = {"gui.delete"},
		tooltip = {"gui.delete-preset-tooltip"}
	}
	
	local preset_list = sidebar.add {
		type = "scroll-pane",
		name = lrm.gui.preset_list,
		style = lrm.gui.preset_list,
	}
	
	local presets = global["preset-names"][player.index]
	for i,preset in pairs(presets) do
		preset_list.add {
			type = "button",
			name = lrm.gui.preset_button .. i,
			style = lrm.gui.sidebar_button,
			caption = preset
		}
	end
	
	local request_window = gui_body.add {
		type = "scroll-pane",
		name = lrm.gui.request_window,
		style = lrm.gui.request_window
	}
	
	local request_table = request_window.add {
		type = "table",
		name = lrm.gui.request_table,
		column_count = 6
	}
	
	for i = 1, player.force.character_logistic_slot_count do
		local request = request_table.add {
			type = "choose-elem-button",
			name = lrm.gui.request_slot .. i,
			elem_type = "item",
			style = lrm.gui.request_slot
		}
		request.locked = true
		request.ignored_by_interaction = true
		
		request.add {
			type = "label",
			name = lrm.gui.request_label .. i,
			style = lrm.gui.request_label
		}
	end
end

function gui.build(player)
	if not player.force.technologies["character-logistic-slots-1"].researched then
		return nil
	end
	
	gui.build_toggle_button(player)
	gui.build_main_frame(player)
end

function gui.force_rebuild(player, open)
	open = open or false
	
	local button_flow = mod_gui.get_button_flow(player)
	if button_flow[lrm.gui.toggle_button] then
		button_flow[lrm.gui.toggle_button].destroy()
	end
	
	local frame_flow = mod_gui.get_frame_flow(player)
	if frame_flow[lrm.gui.frame] then
		frame_flow[lrm.gui.frame].destroy()
	end
	
	gui.build(player)
	if open then frame_flow[lrm.gui.frame].visible = true end
end

function gui.get_save_as_name(player)
	local save_as_field = mod_gui.get_frame_flow(player)
		[lrm.gui.frame]
		[lrm.gui.toolbar]
		[lrm.gui.save_as_textfield]
	return save_as_field.text
end

function gui.select_preset(player, preset_selected)
	preset_selected = lrm.gui.preset_button .. preset_selected
	local preset_list = mod_gui.get_frame_flow(player)
		[lrm.gui.frame]
		[lrm.gui.body]
		[lrm.gui.sidebar]
		[lrm.gui.preset_list]
	for _, preset in pairs(preset_list.children) do
		if preset.name == preset_selected then
			preset.style = lrm.gui.preset_button_selected
			preset_list.scroll_to_element(preset)
		else
			preset.style = lrm.gui.preset_button
		end
	end
end

function gui.display_preset(player, preset_data)
	local request_table = mod_gui.get_frame_flow(player)
		[lrm.gui.frame]
		[lrm.gui.body]
		[lrm.gui.request_window]
		[lrm.gui.request_table]
		
	for i = 1, player.force.character_logistic_slot_count do
		local item = preset_data and preset_data[i] or nil
		if item then
			request_table.children[i].elem_value = item["name"]
			request_table.children[i].children[1].caption = item["count"]
		else
			request_table.children[i].elem_value = nil
			request_table.children[i].children[1].caption = " "
		end
	end
end

function gui.delete_preset(player, preset)
	local preset_list = mod_gui.get_frame_flow(player)
		[lrm.gui.frame]
		[lrm.gui.body]
		[lrm.gui.sidebar]
		[lrm.gui.preset_list]
	preset_list[lrm.gui.preset_button .. preset].destroy()
end