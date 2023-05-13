-- Global variables
local target = nil
local cooldowns = { 0, 0, 0 }
local gametick = 0
local prev_entities = nil
-- Initialize bot
function bot_init(me)
end

function display_entities(entities, prev)
    local str = ""
    for _, entity in ipairs(entities) do
        print(entity:id() .. ": " .. entity:type() .. " " .. entity:pos():x() .. " " .. entity:pos():y())
        -- if prev is not nil then show prev
        if prev then
            local prev_entity = prev[entity:id()]
            if prev_entity then
                local prev_type = prev_entity[1]
                local prev_x = prev_entity[2]
                local prev_y = prev_entity[3]
                local prev_pos = vec.new(prev_x, prev_y)
                local prev_dist = vec.distance(prev_pos, entity:pos())
                print("prev: " .. entity:id() .. ": " .. prev_type .. " " .. prev_x .. " " .. prev_y .. " " .. prev_dist)
            end
        end
    end
    print(str)
end

-- Main bot function
function bot_main(me)
    gametick = gametick + 1

    if gametick % 100 == 0 then
        print("tick " .. gametick)
        display_entities(me:visible(), prev_entities)
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

    prev_entities = {}
    for _, entity in ipairs(me:visible()) do
        prev_entities[entity:id()] = { entity:type(), entity:pos():x(), entity:pos():y() }
    end
end
