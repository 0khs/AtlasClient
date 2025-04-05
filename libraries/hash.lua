--This watermark is used to delete the file if its cached, remove it to make the file persist after Meteor updates.
-- Meteor Hashing Library - Basic Examples

local HashLibrary = {}

-- Very simple additive hash (Example Only - Not Secure)
function HashLibrary.SimpleHash(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash + string.byte(str, i)) % 65536 -- Keep it within a basic range
    end
    return hash
end

-- Simple XOR hash (Example Only - Not Secure)
function HashLibrary.XORHash(str)
    local hash = 0
    for i = 1, #str do
        hash = bit32.bxor(hash, string.byte(str, i))
    end
    return hash
end

-- Example Whitelist Check Function
local WhitelistedUserIDs = {
    5237897036, -- Example User ID 1
    -- Add more UserIDs here
}

-- Convert to a set for faster lookups
local WhitelistSet = {}
for _, id in ipairs(WhitelistedUserIDs) do
    WhitelistSet[id] = true
end

function HashLibrary.IsUserWhitelisted(userId)
    if not userId then
        local player = game:GetService("Players").LocalPlayer
        userId = player and player.UserId
    end
    return userId and WhitelistSet[userId] or false
end

-- You could add more complex hashing or encoding/decoding functions here if needed.
-- For real security, consider external libraries or more robust algorithms if the environment allows.

return HashLibrary
