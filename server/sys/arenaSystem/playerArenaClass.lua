local playerArenaClass = {}
playerArenaClass.__index = playerArenaClass 

playerArenaClass.roundBegun = _G.Event.new() --Event to fire to a players for every new round.

playerArenaClass.new = function(playerObject, team, teamNumber) --Creates a bew player arena class. Arguments are the player object, the team name(typically team 1 or team 2) and the number the player is on the team. So first on the pad is 1, second is 2, etc.
    local self = setmetatable({}, playerArenaClass)
    return self
end

return playerArenaClass
