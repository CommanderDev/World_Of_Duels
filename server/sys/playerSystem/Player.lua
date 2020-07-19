local Player = {}
Player.__index = Player

function Player.new(playerObject)
    local self = setmetatable({}, Player)
    self.playerObject = playerObject
    print(playerObject.Name.." CLass created")
    return self
end

function Player:Destroy()
    print(self.playerObject.Name.." class destroyed")
    self = nil
end

return Player