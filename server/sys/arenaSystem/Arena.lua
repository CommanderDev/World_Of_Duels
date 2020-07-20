---[[ Dependencies ]]---
local Field = require(game.ReplicatedStorage.Field)

local Arena = {}
Arena.__index = Arena

local arenaData = 

{
    defaultTeamColors = 
    {
        team1 = BrickColor.new("Bright red");
        team2 = BrickColor.new("Bright blue")
    };
    inactiveBrickColor = BrickColor.new("Medium stone grey")
}

function Arena.new(arenaModel) 
    local self = setmetatable({}, Arena)
    self.arenaModel = arenaModel
    self.padsFolder = arenaModel:WaitForChild("padsFolder")
    self.spawnsFolder = arenaModel:WaitForChild("spawnsFolder")
    self.teamCount =
    {
        team1 = 0;
        team2 = 0;
    }
    self.padFields = {}
    self.padOwners =
    {
        team1 = {};
        team2 = {};
    }
    self:ActivatePads()
    return self
end

function Arena:DeterminePadActivation()
    for index, pad in next, self.padsFolder:GetChildren() do
        coroutine.wrap(function()
            local start, finish = string.find(pad.Name, "-")
            local team = string.sub(pad.Name, 1, start-1)
            local padNumber = string.sub(pad.Name, finish+1, string.len(pad.Name))
            padNumber = tonumber(padNumber)
            if(padNumber <= self.teamCount[team]+1) then
                self.padFields[pad]:Start()
                pad.Transparency = 0
            else
                self.padFields[pad]:Stop()
                pad.Transparency = 1
            end
        end)()
    end
end

function Arena:HandleEnteringAndLeavingPad(padObject, padField)
    local start, finish = string.find(padObject.Name, "-")
    local team = string.sub(padObject.Name, 1, start-1)
    local padNumber = string.sub(padObject.Name, finish+1, string.len(padObject.Name))
    padField.PlayerEntered:Connect(function(playerObject)
        if(self.padOwners[team][padNumber]) then return end
        local success, err = pcall(function()
            padObject.BrickColor = arenaData.defaultTeamColors[team]
            self.teamCount[team]  = padNumber
            self.padOwners[team][padNumber] = playerObject
           self:DeterminePadActivation()
        end)
        if(not success) then
            print(err)
        end
    end)
    padField.PlayerLeft:Connect(function()
        padObject.BrickColor = arenaData.inactiveBrickColor
        self.teamCount[team] = tonumber(padNumber-1)
        if(self.teamCount[team]) < 0 then
            self.teamCount[team] = 0
        end
        print(self.teamCount[team].." is the amount on "..team)
        self.padOwners[team][padNumber] = playerObject
        self:DeterminePadActivation()
    end)
end

function Arena:ActivatePads() --Handles the pad activation
    for index, pad in next, self.padsFolder:GetChildren() do 
        coroutine.wrap(function()
            self.padFields[pad] = Field.new({pad})
            self.padFields[pad]:Start()
            self:HandleEnteringAndLeavingPad(pad, self.padFields[pad]) 
        end)()
    end
    self:DeterminePadActivation()
end

return Arena