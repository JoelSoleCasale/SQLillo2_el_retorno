-- Global variables
local tick = 0 -- current tick
local center = vec.new(250,250) -- center of the map
local LAMB = 100 -- coefficient of the CoD score
local DASH_PEN = -100 -- penalty for dashing
local MELE_PEN = -100 -- penalty for being too close to an enemy
local N = 8 -- number of directions
local SHOOT_RANGE = 120 -- range of the gun
local MARGIN = 0.9
-- Initialize bot
function bot_init(me)
end

function get_dist(pos, obs, player)
    -- Returns the distance to the closest enemy
    local min_distance = math.huge -- initial value
    local closest_player = nil
    for _, object in ipairs(obs) do
        if object:type() == "player" then
            local dist = vec.distance(pos, object:pos())
            if dist < min_distance then
                min_distance = dist
                closest_player = object  
            end
        end

    end
    if player then
        return {min_distance, closest_player}
    end
    return min_distance
end


function dist_to_scr(dist)
    -- Returns the score related to the distance 
    local log_dist = math.log(dist)
    if dist <= 2 then
        return log_dist + MELE_PEN
    end
    return log_dist
end

function dist_score(pos, obs)
    -- Returns the score related to the distance to the closest enemy 
    return dist_to_scr(get_dist(pos, obs, false))

end

function cod_score(pos, cod)
    -- Returns the score related to the CoD
    local r = MARGIN*cod:radius() -- cod radius
    
    
    if vec.distance(pos, center) > r then
        return -vec.distance(pos, center)
    else
        return -1
    end
    
end

function score(pos, d,  me)
    -- Returns the score of a given position
    return LAMB * cod_score(pos, me:cod()) + dist_score(pos, me:visible()) + DASH_PEN*d
end

function next_move(me, n)

    local best_move = vec.new(0, 0);
    local best_score = score(me:pos(), 0, me)
    local me_pos = me:pos()
    local ds = false

    local ang = 2 * math.pi / n

    for i = 1, n do
        local move = vec.new(math.cos(ang * i), math.sin(ang * i))
        local new_pos = me_pos:add(move)
        local new_score = score(new_pos, 0, me)

        if new_score > best_score then
            best_score = new_score
            best_move = move
            ds = false
        end
        if me:cooldown(1) < 1 then
            new_pos = me_pos:add(vec.new(move:x()*10, move:y()*10))
            new_score = score(new_pos, 1, me)
            if new_score > best_score then
                best_score = new_score
                best_move = move
                ds = true
            end
        end
    end


    return {best_move, ds}
    
end

function try_to_cast(me)
    if me:cooldown(2) < 1 then
        if get_dist(me:pos(), me:visible(), false) < 2 then
            me:cast(2, me:pos())
            return
        end
    end
    if me:cooldown(0) < 1 then
        local closest = get_dist(me:pos(), me:visible(), true)
        if closest[1] < SHOOT_RANGE then
            me:cast(0, closest[2]:pos():sub(me:pos()))
            return
        end
    end
end




-- Main bot function
function bot_main(me)
    if me:cod():x() ~= -1 then
        center = me:cod():pos()
    end

    local move = next_move(me, N)
    local cast = false


    if move[2] then
        me:cast(1, move[1])
        cast = true
        move = next_move(me, N)
    end
    me:move(move[1])

    if not cast then
        try_to_cast(me)
    end

    tick = tick + 1
end