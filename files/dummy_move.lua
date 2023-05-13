-- Global variables
local cooldowns = {0, 0, 0}
-- Initialize bot
function bot_init(me)
end

-- Find the best move for the bot
function best_move(me)
    local me_pos = me:pos()

    local min_distance = 10000000
    local closest_enemy = nil

    for _, player in ipairs(me:visible()) do
        print("chekpoint 1")
        local dist = vec.distance(me_pos, player:pos())
        if dist < min_distance then
            print("chekpoint 2")
            min_distance = dist
            closest_enemy = player
        end
    end
    if closest_enemy == nil then
        print("No enemy found")
        return vec.new(0, 0)
    end
    print("Enemy found")
    return closest_enemy:pos():sub(me_pos):neg()

end

-- Main bot function
function bot_main(me)
    local best_move = best_move(me)

    
    -- Move towards the target
    me:move(best_move)
end