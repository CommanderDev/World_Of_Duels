---[[ Dependencies ]]---
local playerArenaClass = _G.get "sys/arenaSystem/playerArenaClass"
local Player = _G.get "sys/playerSystem/Player" --Player OOP

local Field = require(game.ReplicatedStorage.Field)

local Arena = {}
Arena.__index = Arena

---[[ Player OOP ]]---
local playerClasses = Player.playerClasses
---[[ Server Storage ]]---
local scoreboardUI = game.ServerStorage:WaitForChild("scoreboardUI")
local arenaData = 

{
    defaultTeamColors = 
    {
        team1 = BrickColor.new("Bright red");
        team2 = BrickColor.new("Bright blue")
    };
    inactiveBrickColor = BrickColor.new("Medium stone grey");
    firsttoSettings = --Just so exploiters can't change settings that aren't in the game.
    {
        [3] = true;
        [5] = true;
        [7] = true;
    };
    winbySettings =
    {
        [1] = true;
        [2] = true
    };
}

function Arena:CreateArenaData()
    self.teamCount =
    {
        team1 = 0;
        team2 = 0;
    }

    self.padOwners =
    {
        team1 = {};
        team2 = {};
    }
    self.scores =
    {
        team1 = 0;
        team2 = 0
    }

    self.firstto = 3
    self.winby = 1

    self.matchInProgress = false --Bool to see if the match is in progress.
    self.matchState = "Awaiting Players" --THe current state of the arena.
end

function Arena.new(arenaModel) 
    local self = setmetatable({}, Arena)
    self.arenaModel = arenaModel
    self.padsFolder = arenaModel:WaitForChild("padsFolder")
    self.spawnsFolder = arenaModel:WaitForChild("spawnsFolder")
    self.billMain = arenaModel:WaitForChild("billMain")
    self.padFields = {} --Fields for each pad

    if(not self.billMain:FindFirstChild("scoreboard1")) then 
        self.scoreboard1 = scoreboardUI:Clone()
        self.scoreboard1.Name = "scoreboard1"
        self.scoreboard1.Parent = self.billMain
        self.scoreboard2 = scoreboardUI:Clone()
        self.scoreboard2.Name = "scoreboard2"
        self.scoreboard2:WaitForChild("team1Frame").Name = "team2Frame"
        self.scoreboard2:WaitForChild("team2Frame").Name = "team1Frame"
        self.scoreboard2.Parent = self.billMain
        self.scoreboard2.Face = "Right"
    else
        self.scoreboard1 = self.billMain:FindFirstChild("scoreboard1")
        self.scoreboard2 = self.billMain:FindFirstChild("scoreboard2")
    end
    ---[[ Team Variables ]]---
    self:CreateArenaData()
    self.events = playerArenaClass:GetEvents(arenaModel)
    self.playerClasses = {} --Classes for all the players's playerArenaClass
    ---[[ Functionality ]]---
    self:HandleScoreboard()
    self:ActivatePads()
    self:HandleEvents()
    return self
end

function Arena:Destroy()
    for index, event in next, self.events do 
        event:disconnectAll()
    end
    self = nil
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
                if(not self.padFields[pad]) then
                    self.padFields[pad] = Field.new({pad})
                end
                self.padFields[pad]:Start()
                pad.Transparency = 0
            end
        end)()
    end
end

function Arena:CheckMatchEligibility()
    if(self.teamCount["team1"] == self.teamCount["team2"] and self.teamCount["team1"] > 0) then
        self.matchState = "Awaiting Begin"
        self.events.promptBegin:fire(true)
    else
        self.matchState = "Awaiting Players"
        self.events.promptBegin:fire(false)
    end
    self:UpdateScoreboards()
end

function Arena:HandleEnteringAndLeavingPad(padObject, padField)
    local start, finish = string.find(padObject.Name, "-")
    local team = string.sub(padObject.Name, 1, start-1)
    local padNumber = string.sub(padObject.Name, finish+1, string.len(padObject.Name))
    padNumber = tonumber(padNumber)
    padField.PlayerEntered:Connect(function(playerObject)
        print("Player entered pad!")
        if(self.padOwners[team][padNumber] ~= nil or self.matchInProgress) then return end
        local success, err = pcall(function()
            if(self.teamCount[team] == padNumber - 1) then
                padObject.BrickColor = arenaData.defaultTeamColors[team]
                self.teamCount[team] = padNumber
                self.padOwners[team][padNumber] = playerObject
                
                self.playerClasses[playerObject] = playerArenaClass.new(playerObject, team, padNumber, self.arenaModel) --Create player class.
                playerClasses[playerObject]:SetCharacterCollisionGroup("In Arena")
                self:DeterminePadActivation()
                self:CheckMatchEligibility()
            end
        end)
        if(not success) then
            print(err)
        end
    end)
    padField.PlayerLeft:Connect(function(playerObject)
        if(self.padOwners[team][padNumber] ~= playerObject or self.matchInProgress) then return end --Make sure the player who left is the same who originally activated the pad.
        self.padOwners[team][padNumber] = nil --Make it so the pad is now nil.
        if(padNumber > self.teamCount[team]) then return end --Check that would most likely work with or without this.
        padObject.BrickColor = arenaData.inactiveBrickColor --Change pad's brickcolor to be inactive.
        self.teamCount[team] = padNumber - 1 
        if(self.teamCount[team]) < 0 then
            self.teamCount[team] = 0
        end
        if(self.playerClasses[playerObject]) then
            self.playerClasses[playerObject]:Destroy() --Destroy player class
            self.playerClasses[playerObject] = nil
        end
        playerClasses[playerObject]:SetCharacterCollisionGroup("Players")
        self:CheckMatchEligibility()
        self:DeterminePadActivation()
    end)
end

function Arena:DeactivatePads()
    for index, pad in next, self.padsFolder:GetChildren() do
        local start, finish = string.find(pad.Name, "-")
        local team = string.sub(pad.Name, 1, start-1)
        local padNumber = string.sub(pad.Name, finish+1, string.len(pad.Name))
        padNumber = tonumber(padNumber)
        local currentInTeam = self.teamCount[team]
        if(padNumber > currentInTeam) then
            pad.Transparency = 1
        end
    end
end 

function Arena:HandleEvents()
    self.events.matchBegun:connect(function()
        self.matchInProgress = true
        self.matchState = "Match Underway"
        self.playersAlive = 
        {
            team1 = self.teamCount["team1"];
            team2 = self.teamCount["team2"];
        }
        for pad, field in next, self.padFields do
            field:Stop()
            self:DeactivatePads()
        end
        self.padOwners =
        {
            team1 = {};
            team2 = {};
        }
        self:UpdateScoreboards()
    end)
    self.events.playerKilled:connect(function(killer, team, killedPlayer)
        if(self.playersAlive) then
            killedPlayer.CharacterAppearanceLoaded:Wait()
            self.playersAlive[team] -= 1
            if(self.playersAlive[team] <= 0) then
                if(team == "team1") then
                    self.events.roundConcluded:fire("team2", "team1")
                else 
                    self.events.roundConcluded:fire("team1", "team2")
                end
            end
         end
    end)
    self.events.roundConcluded:connect(function(winnerTeam, loserTeam)
        self.scores[winnerTeam] += 1
        if(self.scores[winnerTeam] >= self.firstto and self.scores[winnerTeam]-self.scores[loserTeam] >= self.winby) then
            self.events.playerMatchConcluded:fire()
            self.events.matchConcluded:fire()
        else 
            self.events.beginRound:fire()
        end
        self:UpdateScoreboards()
    end)

    self.events.matchConcluded:connect(function()
        self:CreateArenaData()
        self:UpdateScoreboards()
        self:ActivatePads()
    end)

    self.events.settingChanged:connect(function(settingToChange, newValue) --Handles a certains etting being changed and sets the value accordingly.
        print(settingToChange)
        print(newValue)
        local setting = arenaData[settingToChange.."Settings"][newValue]
        print(setting)
        if(not setting) then return end 
        self[settingToChange] = newValue 
        self:UpdateScoreboards()
    end)
end

function Arena:UpdateScoreboard(scoreboard)
    local team1Frame = scoreboard:WaitForChild("team1Frame")
    local team2Frame = scoreboard:WaitForChild("team2Frame")
    local titleFrame = scoreboard:WaitForChild("titleFrame")
    local firsttoLabel = titleFrame:WaitForChild("firstToLabel")
    local winbyLabel = titleFrame:WaitForChild("winbyLabel")
    local statusLabel = titleFrame:WaitForChild("statusLabel")
    team1Frame.winsLabel.Text = self.scores["team1"]
    team2Frame.winsLabel.Text = self.scores["team2"]
    firsttoLabel.Text = "First to: "..self.firstto
    winbyLabel.Text = "Win by "..self.winby
    statusLabel.Text = self.matchState
end

function Arena:UpdateScoreboards()
    self:UpdateScoreboard(self.scoreboard1)
    self:UpdateScoreboard(self.scoreboard2)
end

function Arena:HandleScoreboard()
    self:UpdateScoreboards()
    self.events.roundConcluded:connect(function()
    end)
end

function Arena:ActivatePads() --Handles the pad activation
    for index, pad in next, self.padsFolder:GetChildren() do 
        coroutine.wrap(function()
            pad.BrickColor = arenaData.inactiveBrickColor
            if(not self.padFields[pad]) then 
            self.padFields[pad] = Field.new({pad})
            self:HandleEnteringAndLeavingPad(pad, self.padFields[pad])
            end 
        end)()
    end
    self:DeterminePadActivation()
end

return Arena