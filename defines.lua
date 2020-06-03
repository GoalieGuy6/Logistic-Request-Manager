if not lrm then lrm = {} end

lrm.id = "logistic-request-manager"
lrm.guiprefix = lrm.id .. "-gui-"
lrm.settingprefix = lrm.id .. "-setting-"

lrm.gui = {
	toggle_button =     lrm.guiprefix .. "button",
	frame =             lrm.guiprefix .. "frame",
	
	toolbar =           lrm.guiprefix .. "toolbar",
	save_as_textfield = lrm.guiprefix .. "save-as-input",
	save_as_button =    lrm.guiprefix .. "save-as-button",
	blueprint_button =  lrm.guiprefix .. "blueprint-request",
	
	body =              lrm.guiprefix .. "body",
	
	sidebar =           lrm.guiprefix .. "sidebar",
	sidebar_menu =      lrm.guiprefix .. "sidebar-menu",
	sidebar_button =    lrm.guiprefix .. "sidebar-button",
	save_button =       lrm.guiprefix .. "save-button",
	load_button =       lrm.guiprefix .. "load-button",
	delete_button =     lrm.guiprefix .. "delete-button",
	
	preset_list =       lrm.guiprefix .. "preset-list",
	preset_button =     lrm.guiprefix .. "preset-button",
	preset_button_selected = lrm.guiprefix .. "preset-button-selected",
	
	request_window =    lrm.guiprefix .. "request-window",
	request_table =     lrm.guiprefix .. "request-table",
	request_slot =      lrm.guiprefix .. "request-slot",
	request_min = 		lrm.guiprefix .. "request-min",
	request_max = 	    lrm.guiprefix .. "request-max",
	request_infinit =   lrm.guiprefix .. "request-infinit",
}

lrm.settings = {
	persistent_empty_template 	= "persistent_empty_template",
	empty_template_size			= "empty_template_size",
	initial_player_templates 	= "initial_player_templates",
	exported_player_templates 	= "exported_player_templates"
}