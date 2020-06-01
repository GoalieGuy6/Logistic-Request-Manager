for _, player in pairs(game.players) do
    mod_gui.get_frame_flow(player).destroy()
    local old_button_flow=mod_gui.get_button_flow(player)
                        ["logistic-request-manager-button"]
    if old_button_flow then
        old_button_flow.destroy()
    end
end