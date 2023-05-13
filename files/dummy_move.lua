-- Global variables
local cooldowns = {0, 0, 0}
local tick = 0
local center = vec.new(250,250)
-- Initialize bot
function bot_init(me)
end

function get_dist(pos, obs)
    -- Returns the distance to the closest enemy
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

function dist_to_scr(dist, mele_pen)
    -- Returns the score related to the distance 
    local log_dist = math.log(dist)
    if dist <= 2 then
        return log_dist - mele_pen
    end
    return log_dist
end

function dist_score(pos, obs)
    -- Returns the score related to the distance to the closest enemy 
    return dist_to_scr(get_dist(pos, obs), 100)

end

function cod_score(pos, cod)
    -- Returns the score related to the CoD
    local r = cod:radius()/2 -- cod radius
    
    if tick < 500 then
        return 0
    elseif tick < 800 then
        return -tick*vec.distance(pos, center)/2
    elseif vec.distance(pos, center) > r then
        return -tick*vec.distance(pos, center)
    else
        print("  -> Radio: ", r)
        print("  -> Dista: ", vec.distance(pos, center))
        return -1
    end
    
end

function score(pos, lamb, me)
    print("cod_score: ", cod_score(pos, me:cod()))
    print("dist_score: ", dist_score(pos, me:visible()))
    return lamb * cod_score(pos, me:cod()) + dist_score(pos, me:visible())
end

function next_move(me, n)

    local best_move = vec.new(0, 0);
    local best_score = -math.huge
    local me_pos = me:pos()

    local ang = 2 * math.pi / n

    for i = 1, n do
        local move = vec.new(math.cos(ang * i), math.sin(ang * i))
        local new_pos = move:add(me_pos)
        local new_score = score(new_pos, 200, me)
        if new_score > best_score then
            best_score = new_score
            best_move = move
        end
    end

    return best_move
    
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
    print("###### tick: ", tick)
    local move = next_move(me, 8)
    me:move(move)
    tick = tick + 1
end