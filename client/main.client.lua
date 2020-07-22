--- Services ---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--- File system ---
local fileSystem = script.Parent

--- Utility ---
local util = require(ReplicatedStorage:WaitForChild("util"))
local get = util.get "get"
local network = util.get "Network"

get:setFilesystem(fileSystem)
fileSystem.Parent = game.StarterPlayer.StarterPlayerScripts
for i, module in next, get "all" do
	coroutine.wrap(function()
		if(module.init) then
			module:init()
		end
	end)()	
end
