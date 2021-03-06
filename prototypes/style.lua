default_gui = data.raw["gui-style"].default

default_gui[lrm.gui.frame] = {
	type = "frame_style",
	parent = "inner_frame_in_outer_frame",
	maximal_width = 462,
	maximal_height = 700
}

default_gui[lrm.gui.save_as_textfield] = {
	type = "textbox_style",
	parent = "stretchable_textfield"
}

default_gui[lrm.gui.save_as_button] = {
	type = "button_style",
	parent = "button",
	width = 70
}

default_gui[lrm.gui.blueprint_button] = {
	type = "button_style",
	parent = "slot_button"
}

default_gui[lrm.gui.sidebar] = {
	type = "vertical_flow_style",
	vertical_spacing = 5,
	width = 176
}

default_gui[lrm.gui.sidebar_button] = {
	type = "button_style",
	parent = "button",
	minimal_width = 40,
	maximal_width = 176,
	horizontally_stretchable = "on"
}

default_gui[lrm.gui.preset_list] = {
	type = "scroll_pane_style",
	parent = "scroll_pane"
}

default_gui[lrm.gui.preset_button] = {
	type = "button_style",
	parent = "button",
	horizontally_stretchable = "on",
	maximal_width = 176
}

default_gui[lrm.gui.preset_button_selected] = {
	type = "button_style",
	parent = lrm.gui.preset_button,
	default_graphical_set = {base = {position = {34, 17}, corner_size = 8}},
	hovered_graphical_set = {base = {position = {34, 17}, corner_size = 8}},
	clicked_graphical_set = {base = {position = {34, 17}, corner_size = 8}},
	horizontally_stretchable = "on"
}

default_gui[lrm.gui.request_window] = {
	type = "scroll_pane_style",
	parent = "scroll_pane",
	maximal_width = 258,
	margin = 0,
	padding = 0
}

default_gui[lrm.gui.request_slot] = {
	type = "button_style",
	parent = "slot_button"
}

default_gui[lrm.gui.request_label] = {
	type = "label_style",
	parent = "count_label",
	width = 36,
	height = 36,
	left_padding = -4,
	right_padding = 4,
	horizontal_align = "right",
	vertical_align = "bottom"
}