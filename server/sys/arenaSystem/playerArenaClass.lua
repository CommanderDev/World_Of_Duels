---[[ Services ]]---
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")

--PhysicsService:CreateCollisionGroup("In Arena")

---[[ Dependencies ]]---
local Player = _G.get "sys/playerSystem/Player"

local arenaData = _G.get "data/arenaData"

local playerArenaClass = {}
playerArenaClass.__index = playerArenaClass 

playerArenaClass.arenaEvents = {} --Holds a array of all the events in each arena.

---[[ Local Variables ]]--- Variables that will play a part in all playerArenaClasses created
local countdownTime = 30 --Time until settings are locked

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
        settingChanged = _G.Event.new();
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
    self.matchInProgress = false 

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


    self.changeSettingsFrame = self.duelUI:WaitForChild("changeSettingsFrame")
    self.settingsborderPixel = self.changeSettingsFrame:WaitForChild("borderPixel")
    self.settingsGradient = self.changeSettingsFrame:WaitForChild("UIGradient")
    self.settingsborderGradient = self.settingsborderPixel:WaitForChild("UIGradient")
    self.firsttoButton = self.changeSettingsFrame:WaitForChild("firsttoButton")
    self.firsttoList = self.firsttoButton:WaitForChild("listFrame")
    self.winbyButton = self.changeSettingsFrame:WaitForChild("winbyButton")
    self.winbyList = self.winbyButton:WaitForChild("listFrame")
    self.countdownLabel = self.changeSettingsFrame:WaitForChild("countdownLabel")
    ---[[ Player Variables ]]---
    self.sword = nil --THe player's given sword

    self.kills = 0
    self.deaths = 0
    CollectionService:AddTag(playerObject, team)
    ---[[ Connections ]]---
    self.connections =
    {
        ["startButtonClicked"] = nil;
        ["diedConnection"] = nil;
    }

    self.eventConnections =
    {
        promptBegin = nil;
        matchBegun = nil;
        beginRound = nil;
        playerKilled = nil;
        playerMatchConcluded = nil;
    }

    self.matchsettingsEnabled = false
    self:HandlePlayerScoreboards()
    self:HandleMatchSettings()
    self:HandleEvents()
    return self
end

function playerArenaClass:HandlePlayerScoreboard(scoreboard)
    scoreboard.Visible = true
    scoreboard.avatar.Image = game.Players:GetUserThumbnailAsync(self.playerObject.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    scoreboard.playerName.Text = self.playerObject.Name
    scoreboard.kdrLabel.Text = self.kills.."-"..self.deaths
end 

function playerArenaClass:HandlePlayerScoreboards()
    self:HandlePlayerScoreboard(self.playerScoreboard1)    
    self:HandlePlayerScoreboard(self.playerScoreboard2)    
end

function playerArenaClass:HandleSettingList(listFrame)
    local start, finish = string.find(listFrame.Parent.Name, "Button") --Finds the frame so the system can find the name of the setting.
    local settingName = string.sub(listFrame.Parent.Name, 1, start-1)
    local events = playerArenaClass.arenaEvents[self.arena]
    for index, button in next, listFrame:GetChildren() do
        local clicker = button:WaitForChild("clicker")
        clicker.MouseButton1Click:Connect(function()
            if(not self.matchInProgress or self.matchsettingsEnabled == false) then return end
            events.settingChanged:fire(settingName, tonumber(button.Name))
        end)
    end
end 

function playerArenaClass:HandleMatchSettings() --Handles the match settings and Uis associated with it.
    self:HandleSettingList(self.firsttoList)
    self:HandleSettingList(self.winbyList)
    coroutine.wrap(function()
        for index = countdownTime, 1, -1 do
            self.countdownLabel.Text = index
            wait(1)
        end
        self.matchsettingsEnabled = false
        self.changeSettingsFrame.Visible = false
    end)()
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
    self.settingsGradient.Color = colorSequence
    self.settingsborderGradient.Color = colorSequence
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
         self.deaths += 1
        self:HandlePlayerScoreboards()
        local creator = humanoid:FindFirstChild("creator")
        events.playerKilled:fire(creator.Value, self.team, self.playerObject)
        self.sword = nil
        self.connections["diedConnection"]:Disconnect()
    end)
end

function playerArenaClass:HandleEvents() --Handles all of the events associated witht eh player class.
    self:HandleStartButton()
    local events = playerArenaClass.arenaEvents[self.arena]
    local connections = self.eventConnections
    connections.promptBegin = events.promptBegin:connect(function(isEligible)
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

    connections.matchBegun = events.matchBegun:connect(function()
        self.matchInProgress = true
        self.matchsettingsEnabled = true
        self.startButton.Visible = false
        self.changeSettingsFrame.Visible = true
    end)
    
    connections.beginRound = events.beginRound:connect(function()
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

    connections.playerKilled = events.playerKilled:connect(function(killer)
        if(killer == self.playerObject) then
            self.kills += 1
            self:HandlePlayerScoreboards()
        end
    end)
    connections.playerMatchConcluded = events.playerMatchConcluded:connect(function()
        print("Player match concluded")
        local playerObject = self.playerObject
        if(self.sword) then
            self.sword:Destroy()
        end
        self:Destroy()
        local characterObject = playerObject.Character --or self.playerObject.CharacterAppearanceLoaded:Wait()
        if(characterObject) then 
            local humanoidRootPart = characterObject:WaitForChild("HumanoidRootPart")
            local randomSpawn = math.random(1, #spawnsFolder:GetChildren())
            humanoidRootPart.CFrame = spawnsFolder:GetChildren()[randomSpawn].CFrame
        end
        Player.playerClasses[playerObject]:SetCharacterCollisionGroup("Players")
        if(self) then 
            self:Destroy()
        end
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
    local success, errorMessage = pcall(function()
        self:DisconnectConnections()
        self.playerScoreboard1.Visible = false 
        self.playerScoreboard2.Visible = false
        for index, event in next, self.eventConnections do
            event:disconnect()
        end
        self.changeSettingsFrame.Visible = false
        CollectionService:RemoveTag(self.playerObject, self.team)
        self = nil 
    end)
end

return playerArenaClass
