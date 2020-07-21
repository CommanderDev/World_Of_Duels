local playerArenaClass = {}
playerArenaClass.__index = playerArenaClass 

playerArenaClass.roundBegun = _G.Event.new() --Event to fire to a players for every new round.

playerArenaClass.promptBegin = {} --Holds a table of events for all the arenas!
playerArenaClass.beginRound = _G.Event.new()
playerArenaClass.arenaEvents = {} --Holds a array of all the events in each arena.

function playerArenaClass:GetEvents(arena) --Gets the events, not associated with the actual player.
    local events =
    {
        promptBegin = _G.Event.new();
        beginRound = _G.Event.new();
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
    self.events = playerArenaClass.arenaEvents[arena] 
    self.isEligible = false --Determines if match is eligible fpr beginning
    self.spawnLocation = arena.spawnsFolder:FindFirstChild(team.."-"..teamNumber)
    print(self.spawnLocation)
    ---[[ UI Elements ]]---
    self.playerGui = playerObject:WaitForChild("PlayerGui")
    self.duelUI = self.playerGui:WaitForChild("duelUI")
    self.startButton = self.duelUI:WaitForChild("startButton")
    self.realStartButton = self.startButton:WaitForChild("clicker")
    ---[[ Connections ]]---
    self.connections =
    {
        ["startButtonClicked"] = nil
    }
    self:HandleEvents()
    return self
end


function playerArenaClass:HandleStartButton()
    self.connections["startButtonClicked"] = self.realStartButton.MouseButton1Click:Connect(function()
        print("Start clicked")
        if(self.isEligible) then
            self.realStartButton.Visible = false
            self.events.beginRound:fire()
        end
    end)
end

function playerArenaClass:HandleEvents() --Handles all of the events associated witht eh player class.
    self:HandleStartButton()
    self.events.promptBegin:connect(function(isEligible)
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
    
    self.events.beginRound:connect(function()
        print("Beginning round")
        local characterObject = self.playerObject.Character or self.playerObject.CharacterAdded:Wait()
        local humanoidRootPart = characterObject:WaitForChild("HumanoidRootPart")
        humanoidRootPart.CFrame = self.spawnLocation.CFrame + Vector3.new(0,2,0)
        local sword = game.ServerStorage:FindFirstChild("Sword") 
        sword:Clone().Parent = characterObject
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
    self = nil 
end

return playerArenaClass
