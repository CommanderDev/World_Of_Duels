---[[ Services ]]---
local PhysicsService = game:GetService("PhysicsService")
local Player = {}
Player.__index = Player

PhysicsService:CreateCollisionGroup("Players")
PhysicsService:CollisionGroupSetCollidable("Players", "Players",false)
function Player.new(playerObject)
    local self = setmetatable({}, Player)
    self.playerObject = playerObject
    self:HandleCharacter()
    return self
end

function Player:HandleCharacter()
    self.playerObject.CharacterAppearanceLoaded:Connect(function(characterObject)
        for index, characterPart in next, characterObject:GetDescendants() do
            if(characterPart:IsA("BasePart")) then
                PhysicsService:SetPartCollisionGroup(characterPart, "Players")
            end
        end
    end)
end

function Player:Destroy()
    self = nil
end

return Player