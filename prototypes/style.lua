default_gui = data.raw["gui-style"].default

default_gui["logistic-request-manager-main-gui-frame"] = {
	type = "frame_style",
	maximal_width = 412,
	maximal_height = 700
}

default_gui["logistic-request-manager-save-as-textfield"] = {
	type = "textbox_style",
	width = 230
}

default_gui["logistic-request-manager-save-as-button"] = {
	type = "button_style",
	parent = "button",
	width = 85,
	left_margin = 4,
	right_margin = 4
}

default_gui["logistic-request-manager-preset-flow"] = {
	type = "vertical_flow_style",
	width = 126
}

default_gui["logistic-request-manager-preset-scroll-pane"] = {
	type = "scroll_pane_style",
	parent = "scroll_pane",
	width = 126,
	margin = 0,
	padding = 0
}

default_gui["logistic-request-manager-control-button"] = {
	type = "button_style",
	parent = "button",
	width = 126
}

default_gui["logistic-request-manager-preset-button"] = {
	type = "button_style",
	parent = "button",
	width = 106
}

default_gui["logistic-request-manager-preset-button-selected"] = {
	type = "button_style",
	parent = "logistic-request-manager-preset-button",
	default_graphical_set = {base = {position = {34, 17}, corner_size = 8}},
	hovered_graphical_set = {base = {position = {34, 17}, corner_size = 8}},
	clicked_graphical_set = {base = {position = {34, 17}, corner_size = 8}},
	width = 108
}

default_gui["logistic-request-manager-request-scroll-pane"] = {
	type = "scroll_pane_style",
	parent = "scroll_pane",
	maximal_width = 258,
	margin = 0,
	padding = 0
}