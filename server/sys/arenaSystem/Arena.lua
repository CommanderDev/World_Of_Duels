---[[ Dependencies ]]---
local playerArenaClass = _G.get "sys/arenaSystem/playerArenaClass"

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
    self.events = playerArenaClass:GetEvents(arenaModel)
    self:ActivatePads()
    return self
end

function Arena:DeterminePadActivation()
    for index, pad in next, self.padsFolder:GetChildren() do
        coroutine.wrap(function()
            local start, finish = string.find(pad.Name, "-")
            local team = string.sub(pad.Name, 1, start-1)
            local currentInTeam = self.teamCount[team]
            local padNumber = string.sub(pad.Name, finish+1, string.len(pad.Name))
            padNumber = tonumber(padNumber)
            if(padNumber > currentInTeam+1) then
                self.padFields[pad]:Stop()
                pad.Transparency = 1
                pad.BrickColor = arenaData.inactiveBrickColor
            else
                self.padFields[pad]:Start()
                pad.Transparency = 0
            end
        end)()
    end
end

function Arena:CheckMatchEligibility()
    if(self.teamCount["team1"] == self.teamCount["team2"]) then
        self.events.promptBegin:fire(true)
    else
        self.events.promptBegin:fire(false)
    end
end

function Arena:HandleEnteringAndLeavingPad(padObject, padField)
    local start, finish = string.find(padObject.Name, "-")
    local team = string.sub(padObject.Name, 1, start-1)
    local padNumber = string.sub(padObject.Name, finish+1, string.len(padObject.Name))
    local playerClass
    padNumber = tonumber(padNumber)
    padField.PlayerEntered:Connect(function(playerObject)
        if(self.padOwners[team][padNumber]) then return end
        local success, err = pcall(function()
            if(self.teamCount[team] == padNumber - 1) then
                padObject.BrickColor = arenaData.defaultTeamColors[team]
                self.teamCount[team] = padNumber
                self.padOwners[team][padNumber] = playerObject
                
                playerClass = playerArenaClass.new(playerObject, team, padNumber, self.arenaModel)
                self:DeterminePadActivation()
                self:CheckMatchEligibility()
            end
        end)
        if(not success) then
            print(err)
        end
    end)
    padField.PlayerLeft:Connect(function(playerObject)
        if(self.padOwners[team][padNumber] ~= playerObject) then return end
        self.padOwners[team][padNumber] = nil
        if(padNumber > self.teamCount[team]) then return end
        padObject.BrickColor = arenaData.inactiveBrickColor
        self.teamCount[team] = padNumber - 1
        if(self.teamCount[team]) < 0 then
            self.teamCount[team] = 0
        end
        if(playerClass) then
            playerClass:Destroy()
        end
        self:CheckMatchEligibility()
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