local Player = {}
Player.__index = Player

function Player.new(playerObject)
    local self = setmetatable({}, Player)
    
    return self
end

function Player:Destroy()
    self = nil
end

return Player