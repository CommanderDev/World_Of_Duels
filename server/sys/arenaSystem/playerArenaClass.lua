---[[ Services ]]---
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")

--PhysicsService:CreateCollisionGroup("In Arena")

---[[ Dependencies ]]---
local Player = _G.get "sys/playerSystem/Player"

local arenaData = _G.get "data/arenaData"

local playerArenaClass = {}
playerArenaClass.__index = playerArenaClass 

playerArenaClass.roundBegun = _G.Event.new() --Event to fire to a players for every new round.

playerArenaClass.promptBegin = {} --Holds a table of events for all the arenas!
playerArenaClass.beginRound = _G.Event.new()
playerArenaClass.arenaEvents = {} --Holds a array of all the events in each arena.

---[[ Workspace ]]---
local spawnsFolder = workspace:WaitForChild("spawnsFolder")

function playerArenaClass:GetEvents(arena) --Gets the events, not associated with the actual player.
    local events =
    {
        promptBegin = _G.Event.new();
        matchBegun = _G.Event.new();
        beginRound = _G.Event.new();
        roundConcluded = _G.Event.new();
        playerMatchConcluded = _G.Event.new();
        matchConcluded = _G.Event.new();
        playerKilled = _G.Event.new();
    }
    playerArenaClass.arenaEvents[arena] = events
    return events
end

playerArenaClass.new = function(playerObject, team, teamNumber, arena) --Creates a bew player arena class. Arguments are the player object, the team name(typically team 1 or team 2) and the number the player is on the team. So first on the pad is 1, second is 2, etc.
    local self = setmetatable({}, playerArenaClass)
    self.playerObject = playerObject
    self.team = team -- Player's team
    self.teamNumber = teamNumber --Player's number in the team
    self.arena = arena --The arena model the class is associated with
    self.isEligible = false --Determines if match is eligible fpr beginning
    self.spawnLocation = arena.spawnsFolder:FindFirstChild(team.."-"..teamNumber)

    self.playerScoreboard1 = arena.billMain.scoreboard1[team.."Frame"][teamNumber]
    self.playerScoreboard2 = arena.billMain.scoreboard2[team.."Frame"][teamNumber]
    ---[[ UI Elements ]]---
    self.playerGui = playerObject:WaitForChild("PlayerGui")
    self.duelUI = self.playerGui:WaitForChild("duelUI")
    self.startButton = self.duelUI:WaitForChild("startButton")
    self.realStartButton = self.startButton:WaitForChild("clicker")
    self.startGradient = self.startButton:WaitForChild("UIGradient")
    self.borderPixel = self.startButton:WaitForChild("borderPixel")
    self.startPixelGradient = self.borderPixel:WaitForChild("UIGradient")
    ---[[ Player Variables ]]---
    self.sword = nil --THe player's given sword
    CollectionService:AddTag(playerObject, team)
    ---[[ Connections ]]---
    self.connections =
    {
        ["startButtonClicked"] = nil;
        ["diedConnection"] = nil;
    }

    self:HandlePlayerScoreboards()
    self:HandleEvents()
    return self
end

function playerArenaClass:HandlePlayerScoreboard(scoreboard)
    scoreboard.Visible = true
    scoreboard.avatar.Image = game.Players:GetUserThumbnailAsync(self.playerObject.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    scoreboard.playerName.Text = self.playerObject.Name
end 

function playerArenaClass:HandlePlayerScoreboards()
    self:HandlePlayerScoreboard(self.playerScoreboard1)    
    self:HandlePlayerScoreboard(self.playerScoreboard2)    
end


function playerArenaClass:HandleStartButton()
    local startColor = Color3.fromRGB(170, 0, 0)
    local endColor = Color3.fromRGB(255,0,0)
    if(self.team == "team2") then --Handles UI color changing
        startColor = Color3.fromRGB(0,0,170)
        endColor = Color3.fromRGB(0,0,255)
    end
    local colorSequence = ColorSequence.new(
        {
            ColorSequenceKeypoint.new(0.0, startColor);
            ColorSequenceKeypoint.new(1.0, endColor)
        }
      )
    self.startGradient.Color = colorSequence
    self.startPixelGradient.Color = colorSequence
    local events = playerArenaClass.arenaEvents[self.arena]
    self.connections["startButtonClicked"] = self.realStartButton.MouseButton1Click:Connect(function()
        if(self.isEligible) then
            self.startButton.Visible = false
            events.matchBegun:fire()
            events.beginRound:fire()
        end
    end)
end


function playerArenaClass:HandleDeathEvent()
    local events = playerArenaClass.arenaEvents[self.arena]
    local characterObject = self.playerObject.Character or self.playerObject.CharacterAdded:Wait()
    local humanoid = characterObject:WaitForChild("Humanoid")
   self.connections["diedConnection"] = humanoid.Died:Connect(function()
        local creator = humanoid:FindFirstChild("creator")
        events.playerKilled:fire(creator.Value, self.team, self.playerObject)
        self.sword = nil
        self.connections["diedConnection"]:Disconnect()
    end)
end

function playerArenaClass:HandleEvents() --Handles all of the events associated witht eh player class.
    self:HandleStartButton()
    local events = playerArenaClass.arenaEvents[self.arena]
    events.promptBegin:connect(function(isEligible)
        print("Prompting begin!")
        if(isEligible) then
            self.startButton.Visible = true
            self.isEligible = true
        else
            if(self.isEligible) then
                self.startButton.Visible = false
                self.isEligible = false
            end
        end
    end)  

    events.matchBegun:connect(function()
        self.startButton.Visible = false
    end)
    
    events.beginRound:connect(function()
        if(self.connections["diedConnection"]) then
            self.connections["diedConnection"]:Disconnect()
        end
        local characterObject = self.playerObject.Character or self.playerObject.CharacterAdded:Wait()
        Player.playerClasses[self.playerObject]:SetCharacterCollisionGroup("In Arena")
        local humanoidRootPart = characterObject:WaitForChild("HumanoidRootPart")
        local humanoid = characterObject:WaitForChild("Humanoid")
        humanoid.Health = humanoid.MaxHealth
        humanoidRootPart.CFrame = self.spawnLocation.CFrame + Vector3.new(0,2,0)
        if(self.sword) then 
            self.sword.Parent = characterObject
        else
            if(characterObject:FindFirstChildOfClass("Tool")) then return end
            local sword = game.ServerStorage:FindFirstChild("Sword"):Clone()
            sword.Parent = characterObject
            self.sword = sword
        end 
        self:HandleDeathEvent()
    end)

    events.playerKilled:connect(function(killer)
        print(killer)
    end)
    events.playerMatchConcluded:connect(function()
        print("Player match concluded for "..self.playerObject.Name)
        local characterObject = self.playerObject.Character or self.playerObject.CharacterAppearanceLoaded:Wait()
        local humanoidRootPart = characterObject:WaitForChild("HumanoidRootPart")
        local randomSpawn = math.random(1, #spawnsFolder:GetChildren())
        humanoidRootPart.CFrame = spawnsFolder:GetChildren()[randomSpawn].CFrame
        if(self.sword) then
            self.sword:Destroy()
        end
        Player.playerClasses[self.playerObject]:SetCharacterCollisionGroup("Players")
        self:Destroy()
    end) 
end

function playerArenaClass:DisconnectConnections()
    for index, connection in next, self.connections do
        if(connection) then
            connection:Disconnect()
        end
    end
end

function playerArenaClass:Destroy()
    self:DisconnectConnections()
    self.playerScoreboard1.Visible = false 
    self.playerScoreboard2.Visible = false
    CollectionService:RemoveTag(self.playerObject, self.team)
    self = nil 
end

return playerArenaClass
