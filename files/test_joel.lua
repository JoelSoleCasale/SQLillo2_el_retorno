-- Global variables
local target = nil
local cooldowns = { 0, 0, 0 }
local gametick = 0
local prev_bullet_pos = nil
-- Initialize bot
function bot_init(me)
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

function get_orthogonal_proj(x1, x2, p)
    local v_x = x2[1] - x1[1]
    local v_y = x2[2] - x1[2]
    local v = { v_x, v_y }
    local w_x = p[1] - x1[1]
    local w_y = p[2] - x1[2]
    local w = { w_x, w_y }
    local c1 = vec.dot(w, v)
    local c2 = vec.dot(v, v)
    local b = c1 / c2
    local pb_x = x1[1] + b * v_x
    local pb_y = x1[2] + b * v_y
    return { pb_x, pb_y }
end

-- Main bot function
function bot_main(me)
    gametick = gametick + 1

    if gametick % 100 == 0 and prev_bullet_pos[5] then
        print("=====\ntick " .. gametick)
        x1 = get_bullets_future_pos(me:visible(), prev_bullet_pos, 0)[5]
        x2 = get_bullets_future_pos(me:visible(), prev_bullet_pos, 1)[5]
        P = { me:pos():x(), me:pos():y() }
        print("x1 = ", x1[1], x1[2])
        print("x2 = ", x2[1], x2[2])
        print("P = ", P[1], P[2])
        print("P' = ", get_orthogonal_proj(x1, x2, P)[1], get_orthogonal_proj(x1, x2, P)[2])
    end

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
    if target then
        local direction = target:pos():sub(me_pos)
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
