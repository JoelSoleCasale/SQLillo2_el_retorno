-- Global variables
local target = nil
local cooldowns = {0, 0, 0}
-- Initialize bot
function bot_init(me)
end
-- Main bot function
function bot_main(me)
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
    local direction = {0, 0}
    if target then
        direction = target:pos():sub(me_pos)
        -- If target is within melee range and melee attack is not on cooldown, use melee atif min_distance <= 2 and cooldowns[3] == 0 then
        me:cast(2, direction)
        cooldowns[3] = 50
        -- If target is not within melee range and projectile is not on cooldown, use projecelseif cooldowns[1] == 0 then
        me:cast(0, direction)
        cooldowns[1] = 1
    end

    if direction[1] == 0 and direction[2] == 0 then
        direction = {1, 1}
    end
    -- Move towards the target
    me:move(direction)
end