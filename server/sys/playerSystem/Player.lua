---[[ Services ]]---
local PhysicsService = game:GetService("PhysicsService")
local Player = {}
Player.__index = Player
Player.playerClasses = {}


PhysicsService:CreateCollisionGroup("Players")
PhysicsService:CreateCollisionGroup("In Arena")

PhysicsService:CollisionGroupSetCollidable("Players", "Players",false)
function Player.new(playerObject)
    local self = setmetatable({}, Player)
    self.playerObject = playerObject
    self.characterCollision = true --Determines if character collision is on or off.
    self:HandleCharacter()
    Player.playerClasses[playerObject] = self
    return self
end

function Player:HandleCharacter()
    self.playerObject.CharacterAppearanceLoaded:Connect(function(characterObject)
        self:SetCharacterCollisionGroup("Players")
    end)
end

function Player:SetCharacterCollisionGroup(collisionGroup, isCollission)
    local characterObject = self.playerObject.Character or self.playerObject.CharacterAppearanceLoaded:Wait()
    for index, characterPart in next, characterObject:GetDescendants() do
        if(characterPart:IsA("BasePart")) then
            PhysicsService:SetPartCollisionGroup(characterPart, collisionGroup)
        end
    end
end


function Player:Destroy()
    self = nil
end

return Player