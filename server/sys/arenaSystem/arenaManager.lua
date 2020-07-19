---[[ Classes ]]---
local Arena = _G.get "sys/arenaSystem/Arena"

local arenaManager = {}

local arenasFolder = workspace:WaitForChild("arenasFolder")

function arenaManager:connect()
    for arenaIndex, arenaModel in next, arenasFolder:GetChildren() do
        coroutine.wrap(function()
            Arena.new(arenaModel)
        end)()
    end
end

function arenaManager:init()
    self:connect()
end

return arenaManager