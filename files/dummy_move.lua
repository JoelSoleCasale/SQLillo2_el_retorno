-- Global variables
local cooldowns = {0, 0, 0}
-- Initialize bot
function bot_init(me)
end

-- Find the best move for the bot
function best_move(me)
    local me_pos = me:pos()

    local min_distance = 100
    local closest_enemy = nil

    for _, player in ipairs(me:visible()) do
        local dist = vec.distance(me_pos, player:pos())
        if dist < min_distance then
            min_distance = dist
            closest_enemy = player
        end
    end
    if closest_enemy == nil then
        return vec.new(0, 0)
    end
    return me_pos:sub(closest_enemy:pos())

end

-- Main bot function
function bot_main(me)
    local best_move = best_move(me)
    
    -- Move towards the target
    me:move(best_move)
end