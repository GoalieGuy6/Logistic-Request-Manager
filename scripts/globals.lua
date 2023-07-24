if not lrm.globals then lrm.globals = {} end

function lrm.globals.init()
    global                     = global or {}
    global["preset-data"]      = global["preset-data"] or {}
    global["preset-names"]     = global["preset-names"] or {}
    global["presets-selected"] = global["presets-selected"] or {}
    global["inventories-open"] = global["inventories-open"] or {}
    global["screen_location"]  = global["screen_location"] or {}
    global["bring_to_front"]   = global["bring_to_front"] or {}
    global["data_to_view"]     = global["data_to_view"] or {}
    global["flags"]            = global["flags"] or {}
    global["trash"]            = global["trash"] or {}
    
    global.feature_level = global.feature_level or "1.1"
end

function lrm.globals.init_player(player)
    local index = player.index
    
    global["preset-data"][index]      = global["preset-data"][index] or {}
    global["preset-names"][index]     = global["preset-names"][index] or {}
    global["presets-selected"][index] = global["presets-selected"][index] or 0
    global["screen_location"][index]  = global["screen_location"][index] or nil
    global["flags"][index]            = global["flags"][index] or {
                                                                    autotrash = false, 
                                                                    autotrash_automatic = true,
                                                                    trash_selection_tools = false, 
                                                                    trash_blueprints = false, 
                                                                    trash_blueprint_books = false, 
                                                                    trash_deconstruction_planers = false, 
                                                                    trash_upgrade_planers = false, 
                                                                    trash_copy_paste_tools = false, 
                                                                    trash_hidden_items = false, 
                                                                    trash_gridded_items = false, 
                                                                    trash_remotes = false
                                                                }
    global["trash"][index]            = global["trash"][index] or {}
end