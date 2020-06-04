local mod_gui = require 'mod-gui'

for _, player in pairs(game.players) do
    -- remove old static gui from gui.top
    local old_frame=mod_gui.get_frame_flow(player)
                        ["logistic-request-manager-gui-frame"]
    if old_frame then 
        old_frame.destroy() 
    end

    -- remove old unused button
    local old_button_flow=mod_gui.get_button_flow(player)
                            ["logistic-request-manager-button"]
    if old_button_flow then
        old_button_flow.destroy()
    end

    player.print("[LRM] Migration to 0.18.1 complete.")
end