-- Global variables
local target = nil
local cooldowns = { 0, 0, 0 }
local gametick = 0
local prev_bullet_pos = nil
-- Initialize bot
function bot_init(me)
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

function get_orthogonal_proj(x1, x2, p)
    local v_x = x2[1] - x1[1]
    local v_y = x2[2] - x1[2]
    local w_x = p[1] - x1[1]
    local w_y = p[2] - x1[2]
    local c1 = v_x * w_x + v_y * w_y
    local c2 = v_x * v_x + v_y * v_y
    local b = c1 / c2
    local pb_x = x1[1] + b * v_x
    local pb_y = x1[2] + b * v_y
    return { pb_x, pb_y }
end

function bullet_collision(cp, np, p)
    -- cp: current bullet position (array)
    -- np: next bullet position (array)
    -- p: future player position (array)
    local player_radius = 1
    local proj = get_orthogonal_proj(cp, np, p)
    -- if proj is not on the line segment, make proj the closest point on the line segment
    if proj[1] < math.min(cp[1], np[1]) then
        proj[1] = math.min(cp[1], np[1])
    elseif proj[1] > math.max(cp[1], np[1]) then
        proj[1] = math.max(cp[1], np[1])
    end
    if proj[2] < math.min(cp[2], np[2]) then
        proj[2] = math.min(cp[2], np[2])
    elseif proj[2] > math.max(cp[2], np[2]) then
        proj[2] = math.max(cp[2], np[2])
    end

    local dist = vec.distance(proj, p)

    return dist <= player_radius
end

function pos_bullet_collision(p, bullet_pos, future_pos)
    -- p: future player position (array)
    -- bullet_pos: bullet positions (array)
    -- future_pos: future bullet positions (array)
    -- returns 0 and 1
    for id, cp in pairs(bullet_pos) do
        local np = future_pos[id]
        if np ~= nil then
            if bullet_collision(cp, np, p) then
                return 1
            end
        end
    end
    return 0
end

-- Main bot function
function bot_main(me)
    gametick = gametick + 1

    local me_pos = me:pos()
    -- Update cooldowns
    for i = 1, 3 do
        if cooldowns[i] > 0 then
            cooldowns[i] = cooldowns[i] - 1
        end
    end
    -- Find the closest visible enemy
    local closest_enemy = nil
    local min_distance = math.huge
    for _, player in ipairs(me:visible()) do
        local dist = vec.distance(me_pos, player:pos())
        if dist < min_distance then
            min_distance = dist
            closest_enemy = player
        end
    end
    -- Set target to closest visible enemy
    local target = closest_enemy
    local direction = nil
    if target then
        direction = target:pos():sub(me_pos)
        -- If target is within melee range and melee attack is not on cooldown, use melee atif min_distance <= 2 and cooldowns[3] == 0 then
        me:cast(2, direction)
        cooldowns[3] = 50
        -- If target is not within melee range and projectile is not on cooldown, use projecelseif cooldowns[1] == 0 then
        me:cast(0, direction)
        cooldowns[1] = 1
    end
    -- Move towards the target
    me:move(direction)

    prev_bullet_pos = {}
    for _, entity in ipairs(me:visible()) do
        if entity:type() == "small_proj" then
            prev_bullet_pos[entity:id()] = { entity:pos():x(), entity:pos():y() }
        end
    end
end
