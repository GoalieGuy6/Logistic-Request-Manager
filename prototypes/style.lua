default_gui = data.raw["gui-style"].default

default_gui["logistic-request-manager-main-gui-frame"] = {
	type = "frame_style",
	maximal_width = 462,
	maximal_height = 700
}

default_gui["logistic-request-manager-save-as-textfield"] = {
	type = "textbox_style",
	parent = "stretchable_textfield"
}

default_gui["logistic-request-manager-save-as-button"] = {
	type = "button_style",
	parent = "button",
	width = 70
}

default_gui["logistic-request-manager-preset-flow"] = {
	type = "vertical_flow_style",
	width = 176
}

default_gui["logistic-request-manager-preset-scroll-pane"] = {
	type = "scroll_pane_style",
	parent = "scroll_pane",
	top_margin = 5
}

default_gui["logistic-request-manager-control-button"] = {
	type = "button_style",
	parent = "button",
	minimal_width = 40
}

default_gui["logistic-request-manager-preset-button"] = {
	type = "button_style",
	parent = "button",
	horizontally_stretchable = "on"
}

default_gui["logistic-request-manager-preset-button-selected"] = {
	type = "button_style",
	parent = "logistic-request-manager-preset-button",
	default_graphical_set = {base = {position = {34, 17}, corner_size = 8}},
	hovered_graphical_set = {base = {position = {34, 17}, corner_size = 8}},
	clicked_graphical_set = {base = {position = {34, 17}, corner_size = 8}},
	horizontally_stretchable = "on"
}

default_gui["logistic-request-manager-request-scroll-pane"] = {
	type = "scroll_pane_style",
	parent = "scroll_pane",
	maximal_width = 258,
	margin = 0,
	padding = 0
}