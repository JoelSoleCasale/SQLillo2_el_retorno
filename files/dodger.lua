-- Global variables
local target = nil
local cooldowns = { 0, 0, 0 }
local gametick = 0
local prev_bullet_pos = nil
local prev_health = 100
local HIT_PENALTY = { -1, -0.5 }
local HIT_RADIUS = { 1.05, 1.5 }
local DASH_PEN = -0.1

-- Constants
local PLAYER_SPEED = 1
local SHOOT_RANGE = 2

-- Initialize bot
function bot_init(me)
    prev_health = me:health()
end

function display_entities(entities)
    for _, entity in ipairs(entities) do
        print(entity:id() .. ": " .. entity:type() .. " " .. entity:pos():x() .. " " .. entity:pos():y())
    end
end

function display_pos(pos, prefix)
    for id, p in pairs(pos) do
        print(prefix .. id .. ": " .. p[1] .. " " .. p[2])
    end
end

function get_bullets_future_pos(entities, prev_entities, t)
    fut_pos = {}
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

function bullet_collision(cp, np, p, player_radius)
    -- cp: current bullet position (array)
    -- np: next bullet position (array)
    -- p: future player position (array)

    local dist = (np[1] - p[1]) * (np[1] - p[1]) + (np[2] - p[2]) * (np[2] - p[2])
    local dist2 = (cp[1] - p[1]) * (cp[1] - p[1]) + (cp[2] - p[2]) * (cp[2] - p[2])
    return (dist <= player_radius * player_radius) or (dist2 <= player_radius * player_radius)
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

function score(pos, lamb, dash, me, bullet_pos, future_pos)
    -- Returns the score of a given position
    local hit_penalty = dash * DASH_PEN
    for id, p in pairs(HIT_PENALTY) do
        hit_penalty = hit_penalty +
            p * pos_bullet_collision({ pos:x(), pos:y() }, bullet_pos, future_pos[id], HIT_RADIUS[id])
    end
    return hit_penalty
end

function next_move(me, n, lamb, dash)
    local bullet_pos = get_bullets_future_pos(me:visible(), prev_bullet_pos, 0)
    local future_pos = {}
    for t = 1, #HIT_RADIUS do
        -- append at the end of future_pos
        table.insert(future_pos, get_bullets_future_pos(me:visible(), prev_bullet_pos, t))
    end

    local best_move = vec.new(0, 0);
    local best_score = score(me:pos(), lamb, 0, me, bullet_pos, future_pos)
    local me_pos = me:pos()
    local ds = false

    local ang = 2 * math.pi / n

    for i = 1, n do
        local move = vec.new(math.cos(ang * i) * PLAYER_SPEED, math.sin(ang * i) * PLAYER_SPEED)
        local new_pos = me_pos:add(move)
        local new_score = score(new_pos, lamb, 0, me, bullet_pos, future_pos)

        if new_score > best_score then
            print("¿" .. gametick .. "i moved!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            best_score = new_score
            best_move = move
            ds = false
        end
        if me:cooldown(1) <= 0 then
            new_pos = me_pos:add(vec.new(move:x() * 10, move:y() * 10))
            new_score = score(new_pos, lamb, 1, me, bullet_pos, future_pos)
            if new_score > best_score then
                best_score = new_score
                best_move = move
                ds = true
            end
        end
    end
    -- move_center is a vector that points to the center of the circle (250, 250)
    local center = vec.new(me:cod():x(), me:cod():y())
    if center:x() == -1 then
        center = vec.new(250, 250)
    end
    local move_center = vec.new(center:x() - me:pos():x(), center:y() - me:pos():y())
    mul_coef = PLAYER_SPEED / math.sqrt(move_center:x() * move_center:x() + move_center:y() * move_center:y())
    move_center = vec.new(move_center:x() * mul_coef, move_center:y() * mul_coef)

    local new_pos = me_pos:add(move_center)
    local new_score = score(new_pos, lamb, 0, me, bullet_pos, future_pos)

    if new_score >= best_score then
        print("¿" .. gametick .. "i moved!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        best_score = new_score
        best_move = move_center
        ds = false
    end

    if best_score < 0 then
        print("¿" .. gametick .. string.rep("$", 30) .. "UNAVOIDABLE" .. string.rep("$", 30))
    end
    return { best_move, ds }
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
        return { min_distance, closest_player }
    end
    return min_distance
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
    local move = next_move(me, 128, 200, -100)

    if gametick % 100 == 0 then
        print("¿" .. gametick .. " health: " .. me:health())
    end

    try_to_cast(me)

    if move[2] then
        me:cast(1, move[1])
        cast = true
        move = next_move(me, 128, 200, -100)
    end
    me:move(move[1])

    prev_bullet_pos = {}
    for _, entity in ipairs(me:visible()) do
        if entity:type() == "small_proj" then
            prev_bullet_pos[entity:id()] = { entity:pos():x(), entity:pos():y() }
        end
    end

    if me:health() < prev_health - 2 then
        print("?" .. gametick .. "====================================I got hit!" ..
            me:health() .. "==========================================")
    end
    prev_health = me:health()
    gametick = gametick + 1
end
