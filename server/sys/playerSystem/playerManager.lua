---[[ Services ]]---
local Players = game:GetService("Players")

---[[ Dependencies ]]---
local Player = _G.get "sys/playerSystem/Player"

local playerManager = {}

local playerClasses = {} --Array of all the player classes in the game.
function PlayerAdded(playerObject)
    playerClasses[playerObject] = Player.new(playerObject) --Creates a new player class for the player added.
end

function PlayerRemoving(playerObject)
    playerClasses[playerObject]:Destroy() --Fires the destroy function in every player class.
    playerClasses[playerObject] = nil --Deletes the index that once was the player's class.
end

function playerManager:connect()
    Players.PlayerAdded:Connect(PlayerAdded)    
    Players.PlayerRemoving:Connect(PlayerRemoving)
end

function playerManager:init()
    self:connect()
end

return playerManager