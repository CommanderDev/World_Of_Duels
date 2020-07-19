---[[ Dependencies ]]---
local Field = require(game.ReplicatedStorage.Field)

local Arena = {}
Arena.__index = Arena

arenaData = 

{
    defaultTeamColors = 
    {
        team1 = BrickColor.new("Bright red");
        team2 = BrickColor.new("Bright blue")
    }
}

function Arena.new(arenaModel) 
    print(arenaModel.Name.." created!")
    local self = setmetatable({}, Arena)
    self.arenaModel = arenaModel
    self.padsFolder = arenaModel:WaitForChild("padsFolder")
    self.spawnsFolder = ArenaModel:WaitForChild("spawnsFolder")
    self.teamCount =
    {
        team1 = 0;
        team2 = 0;
    }
    self.padFields = {}
    self:ActivatePads()
    return self
end

function Arena:HandleEnteringAndLeavingPad(padObject, padField)
    padField.PlayerEntered:Connect(function(playerObject)
    
    end)
end

function Arena:ActivatePads() --Handles the pad activation
    for index, pad in next, self.padsFolder:GetChildren() do 
        coroutine.wrap(function()
            self.padFields[pad] = Field.new({pad})
            self:HandleEnteringAndLeavingPad(pad, self.padFields[pad]) 
        end)()
    end
end

return Arena