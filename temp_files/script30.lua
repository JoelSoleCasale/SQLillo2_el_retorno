local LAMB = 150
local DASH_PEN = -256.5774151566203
local MELE_PEN = -300
local WALL_PENALTY = -200
-- Global variables
local tick = 0                   -- current tick
local center = vec.new(250, 250) -- center of the map
local future_pos = {}            -- future position of the bullets
local bullet_pos = {}            -- position of the bullets
local prev_bullet_pos = nil      -- previous position of the bullets

-- Hyperparameters
local N = 8                            -- number of directions
local HIT_PENALTY = { -100000, -5000 } -- penalty for being hit by a bullet
local HIT_RADIUS = { 1.05, 1.5 }       -- radius of user for forecasting hits
local SHOOT_RANGE = 16                 -- range to be careful with dash
local SAFE_RANGE = 45                  -- safe range for the gun
local WALL_MARGIN = 5
local MARGIN = 0.9

-- Constants
local PLAYER_SPEED = 1 -- player speed
local COLUMNS = nil    -- columns of the map


--------------------------------------
-- ########## INITIALIZE ########## --
--------------------------------------

-- Initialize bot
function bot_init(me)
    COLUMNS = create_columns(me:visible())
end

function create_columns(obs)
    local columns = {}
    for _, object in ipairs(obs) do
        if object:type() == "wall" then
            table.insert(columns, object:pos())
        end
    end
    return columns
end

--------------------------------------
-- ########### DODGING ############ --
--------------------------------------
function get_bullets_future_pos(entities, prev_entities, t)
    local fut_pos = {}
    for _, bullet in ipairs(entities) do
        if bullet:type() == "small_proj" then
            local prev_bullet = prev_entities[bullet:id()]
            if prev_bullet ~= nil then
                local v_x = bullet:pos():x() - prev_bullet[1]
                local v_y = bullet:pos():y() - prev_bullet[2]
                local fut_x = bullet:pos():x() + v_x * t
                local fut_y = bullet:pos():y() + v_y * t
                fut_pos[bullet:id()] = { fut_x, fut_y }
            end
        end
    end
    return fut_pos
end

function pos_bullet_collision(p, bullet_pos, future_pos, rad_hitbox)
    -- p: future player position (array)
    -- bullet_pos: bullet positions (array)
    -- future_pos: future bullet positions (array)
    -- returns 0 and 1
    for id, cp in pairs(bullet_pos) do
        local np = future_pos[id]
        if np ~= nil then
            if bullet_collision(cp, np, p, rad_hitbox) then
                return 1
            end
        end
    end
    return 0
end

function bullet_collision(cp, np, p, player_radius)
    -- cp: current bullet position (array)
    -- np: next bullet position (array)
    -- p: future player position (array)

    local dist = (np[1] - p[1]) * (np[1] - p[1]) + (np[2] - p[2]) * (np[2] - p[2])
    local dist2 = (cp[1] - p[1]) * (cp[1] - p[1]) + (cp[2] - p[2]) * (cp[2] - p[2])
    return (dist <= player_radius * player_radius) or (dist2 <= player_radius * player_radius)
end

--------------------------------------
-- ########### SCORING ############ --
--------------------------------------

function score_bull(pos, me)
    -- Returns the score of a given position based on bullets
    local hit_penalty = 0
    for id, p in pairs(HIT_PENALTY) do
        hit_penalty = hit_penalty +
            p * pos_bullet_collision({ pos:x(), pos:y() }, bullet_pos, future_pos[id], HIT_RADIUS[id])
    end
    return hit_penalty
end

function dist_score(pos, obs)
    -- Returns the score related to the distance to the closest enemy
    return dist_to_scr(get_dist(pos, obs, false))
end

function cod_score(pos, cod)
    -- Returns the score related to the CoD
    local r = cod:radius() -- cod radius
    local dist = vec.distance(pos, center)

    if dist < MARGIN * r then
        return -1
    elseif dist < r then
        return -dist
    end

    return -math.huge
end

function column_score(pos)
    local dist = closest_column(pos)

    if dist <= 5 then
        return (dist - 16) * COLUMN_PENALTY
    elseif dist <= 7 then
        return (dist - 8) * COLUMN_PENALTY * 2
    end
    return 0
end

function wall_score(pos)
    local distx = math.min(pos:x(), 500 - pos:x())
    local disty = math.min(pos:y(), 500 - pos:y())

    if distx <= WALL_MARGIN then
        return (WALL_MARGIN - distx) * WALL_PENALTY
    end
    if disty <= WALL_MARGIN then
        return (WALL_MARGIN - disty) * WALL_PENALTY
    end
    return 0
end

function score(pos, d, me)
    -- Returns the score of a given position
    if not valid_pos(pos, me) then
        return -math.huge
    end

    return LAMB * cod_score(pos, me:cod()) +
        dist_score(pos, me:visible()) +
        DASH_PEN * d +
        score_bull(pos, me) +
        column_score(pos) +
        wall_score(pos)
end

--------------------------------------
-- ##### Auxiliary Functions ###### --
--------------------------------------

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

    if player then -- Returns the closest player
        return { min_distance, closest_player }
    end
    return min_distance
end

function dist_to_scr(dist)
    -- Returns the score related to the distance
    local log_dist = math.log(dist + 1)
    if dist <= 2 then
        return log_dist + MELE_PEN
    end
    return log_dist
end

function closest_column(pos)
    -- Returns the distance to the closest column
    local min_distance = math.huge -- initial value
    for _, coord in pairs(COLUMNS) do
        local dist = vec.distance(pos, coord)
        if dist < min_distance then
            min_distance = dist
        end
    end

    return min_distance
end

function valid_pos(pos, me)
    -- Returns true if the position is valid
    if closest_column(pos, me:visible()) <= 3 then
        return false
    elseif pos:x() < 0 or pos:x() > 500 or pos:y() < 0 or pos:y() > 500 then
        return false
    end
    return true
end

--------------------------------------
-- ########### MOVING ############# --
--------------------------------------

function next_move(me, n)
    -- Update the future position of the bullets
    bullet_pos = get_bullets_future_pos(me:visible(), prev_bullet_pos, 0)
    future_pos = {}
    for t = 1, #HIT_RADIUS do
        table.insert(future_pos, get_bullets_future_pos(me:visible(), prev_bullet_pos, t))
    end

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
            new_pos = me_pos:add(vec.new(move:x() * 10, move:y() * 10))
            new_score = score(new_pos, 1, me)
            if new_score > best_score then
                best_score = new_score
                best_move = move
                ds = true
            end
        end
    end


    return { best_move, ds }
end

--------------------------------------
-- ########### ATACKING ########### --
--------------------------------------
function shoot(me, closest)
    -- Shoots the closest enemy
    me:cast(0, closest[2]:pos():sub(me:pos()))
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
        -- If it too close or far enough, shoot
        if closest[1] < SHOOT_RANGE or closest[1] > SAFE_RANGE then
            shoot(me, closest)
            return
        end
    end
end

-- Main bot function
function bot_main(me)
    if me:cod():x() ~= -1 then
        center = vec.new(me:cod():x(), me:cod():y())
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


    prev_bullet_pos = {}
    for _, entity in ipairs(me:visible()) do
        if entity:type() == "small_proj" then
            prev_bullet_pos[entity:id()] = { entity:pos():x(), entity:pos():y() }
        end
    end
    tick = tick + 1
end
