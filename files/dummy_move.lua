-- Global variables
local cooldowns = {0, 0, 0}
-- Initialize bot
function bot_init(me)
end

function closest_player(pos, obs)

    local min_distance = math.huge -- initial value
    for _, object in ipairs(obs) do
        if object:type() == "player" then
            local dist = vec.distance(pos, object:pos())
            if dist < min_distance then
                min_distance = dist
            end
        end

    end
    return min_distance
end

function cod_score(pos, obs )
    return 1
end

function score(pos, lamb, obs)
    return lamb * cod_score(pos, obs) - closest_player(pos, obs)
    
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
    local min_dist = closest_player(me:pos(), me:visible())
    print(min_dist)
end