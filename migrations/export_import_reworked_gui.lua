for _, player in pairs(game.players) do
    -- remove interim-version of floating screen - should never have been created for anybody but during testing (just playing it save as the old version was on github...)
    if player.gui.screen["logistic-request-manager-gui-frame"] then
        player.gui.screen["logistic-request-manager-gui-frame"].destroy()
    end
    if player.gui.screen["logistic-request-manager-gui-import-frame"] then
        player.gui.screen["logistic-request-manager-gui-import-frame"].destroy()
    end

    -- make sure an empty location is nil
    local location = global["screen_location"] and global["screen_location"][player.index] or nil
    if location and not next(location) then 
        global["screen_location"][player.index] = nil 
    end
end