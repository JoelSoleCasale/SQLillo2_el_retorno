-- Global variables
local cooldowns = {0, 0, 0}
local tick = 0
local center = vec.new(250,250)
-- Initialize bot
function bot_init(me)
end

function get_dist(pos, obs, me)
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

function dist_score(pos, obs, me)
    -- Returns the score related to the distance to the closest enemy 
    return dist_to_scr(get_dist(pos, obs, me), 100)

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
        return -1
    end
    
end

function score(pos, lamb, dash, me)
    -- Returns the score of a given position
    local a = lamb * cod_score(pos, me:cod())
    local b = dist_score(pos, me:visible(), me)
    print("cod_score: ", a)
    print("dist_score: ", b)
    print("dash: ", dash)
    print("total: ", a+b+dash)
    return lamb * cod_score(pos, me:cod()) + dist_score(pos, me:visible(), me) + dash
end

function next_move(me, n, lamb, dash)

    local best_move = vec.new(0, 0);
    local best_score = -math.huge
    local me_pos = me:pos()
    local ds = false

    local ang = 2 * math.pi / n

    for i = 1, n do
        local move = vec.new(math.cos(ang * i), math.sin(ang * i))
        local new_pos = me_pos:add(move)
        local new_score = score(new_pos, lamb, 0, me)

        if new_score > best_score then
            best_score = new_score
            best_move = move
            ds = false
        end
        if me:cooldown(1) == 0 then
            new_pos = me_pos:add(vec.new(move:x()*10, move:y()*10))
            new_score = score(new_pos, lamb, dash, me)
            if new_score > best_score then
                best_score = new_score
                best_move = move
                ds = true
            end
        end
    end


    return {best_move, ds}
    
end




-- Main bot function
function bot_main(me)
    print("########tick: ", tick)
    local move = next_move(me, 128, 200, -100)
    local cast = false
    if move[2] then
        me:cast(1, move[1])
        cast = true
        move = next_move(me, 128, 200, -100)
    end
    me:move(move[1])
   
    
    tick = tick + 1
end