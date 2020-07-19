local util = require(script.Parent)

local Event = util.get "Event"
local ReplicatedStorage = util.services.ReplicatedStorage
local RunService = util.services.RunService
local Players = util.services.Players

local networkEvent
local networkFunction

GLOBAL_NAME = "network"

function randomizeName() --Just a randomizer I apparently added to the util for not much of a reason a while ago.
	local length = 70
	local numLength = 15
	local RETURN = ""
	for i = 1,length do
		RETURN = RETURN..string.char(math.random(97,122))
	end	
	for i = 1,numLength do
		local num = math.random(1,9)
		RETURN = RETURN.. tostring(num)
	end
	return RETURN
end


local numberOfRemotes = 10
local rEvents = {}
local rFunctions = {}
local tempFunction
local tempFunctionName = "TempFunction"

local madeRemotes = false
local gotRealRemotes =  false

if not madeRemotes and RunService:IsServer() then	--	Need to do the first condition for play solo testing
	tempFunction = Instance.new("RemoteFunction",ReplicatedStorage)
	tempFunction.Name = tempFunctionName
	for i = 1,numberOfRemotes do
		newEvent = Instance.new("RemoteEvent")
		newEvent.Name = randomizeName()
		rEvents[#rEvents+1]=newEvent
		newFunction = Instance.new("RemoteFunction")
		newFunction.Name = randomizeName()
		
		rFunctions[#rFunctions+1]=newFunction
		
		newEvent.Parent = ReplicatedStorage
		newFunction.Parent = ReplicatedStorage
	end
	madeRemotes = true
	local realEventName = math.random(1,numberOfRemotes)
	networkEvent = rEvents[realEventName]
	rEvents[realEventName] = nil
	local realFunctionName = math.random(1,numberOfRemotes)
	networkFunction = rFunctions[realFunctionName]
	rFunctions[realFunctionName] = nil
	
elseif RunService:IsClient() then
	tempFunction = game.ReplicatedStorage:FindFirstChild(tempFunctionName)
	local rEvent,rFunction = tempFunction:InvokeServer("get remotes")
	networkEvent = ReplicatedStorage:FindFirstChild(rEvent)
	networkFunction = ReplicatedStorage:FindFirstChild(rFunction)
end

--

local networkUtil = {}

networkUtil.events = {}	--	[name] = {func, ...}
networkUtil.callbacks = {}

--


if RunService:IsServer() then --Required from the server
	networkEvent.OnServerEvent:Connect(function(playerObject, name, ...)
		if networkUtil.events[name] then --Checks to see if the event's name was already created. Event creation found in :createEventListener()
			networkUtil.events[name]:fire(playerObject, ...)
		end
	end)

	networkFunction.OnServerInvoke = function(playerObject, name, ...)
		if networkUtil.callbacks[name] then --Checks to see if the callback's name was already created. callback creation found in :setCallback()
			return networkUtil.callbacks[name](playerObject, ...)
		end
	end
	
	tempFunction.OnServerInvoke = function(playerObject,name) --This is just a random piece of code I created. The utility doesn't require any sort of index to what the event is or named so I did this when creating this just cause I could in all honestly.
		if gotRealRemotes == false then
			if name == "get remotes" then --Honestly I don't know why this is here. I coded this a while ago and am just now documenting it.
				return networkEvent.Name,networkFunction.Name --Returns the network event name and network function name so the real event can be hooked up correctly.
			end
			gotRealRemotes = true
		else
			playerObject:Kick('Attempt to fetch unauthorized information.')	
		end
	end
	for i,event in pairs(rEvents) do 
		event.OnServerEvent:Connect(function(player) --If a false event is fired then kick the player who fired it. 
			player:Kick("Attempt to exploit remote event")
		end)
	for i,Function in pairs(rFunctions) do
		Function.OnServerInvoke = function(player) --If a false function is fired then kick the player who fired it.
			player:Kick("Attempt to exploit remote function")
			end
		end
	end
end

if RunService:IsClient() then --Required from the client
	networkEvent.OnClientEvent:Connect(function(name, ...) 
		wait() 
		if networkUtil.events[name] then
			networkUtil.events[name]:fire(...)
		end
	end)
	
	networkFunction.OnClientInvoke = function(name, ...)
		if networkUtil.callbacks[name] then
			return networkUtil.callbacks[name](...)
		end
	end
end
--

function networkUtil:fireClient(playerObject, name, ...) --same as RemoteEvent:FireClient()
	networkEvent:FireClient(playerObject, name, ...)
end

function networkUtil:fireAllClients(name, ...)
	networkEvent:FireAllClients(name, ...)
end

function networkUtil:fireOtherClients(playerObject, name, ...) --Custom function that fires everyone's client but the playerObject's client.
	for _, otherPlayerObject in next, Players:GetPlayers() do
		if otherPlayerObject ~= playerObject then
			networkEvent:FireClient(otherPlayerObject, name, ...)
		end
	end
end

function networkUtil:fireServer(name, ...) --Sane as RemoteEvent:FireServer()
	networkEvent:FireServer(name, ...)
end

function networkUtil:invokeClient(playerObject, name, ...) --Same as RemoteFunction:InvokeClient()
	return networkFunction:InvokeClient(playerObject, name, ...)
end

function networkUtil:invokeServer(name, ...) --Same as RemoteFunction:InvokeServer()
	return networkFunction:InvokeServer(name, ...)
end

function networkUtil:createEventListener(name, func) --Creates a event with a given function. This will run if the name argument(first argument in the FireServer or FireClient) is the same as the name argument.
	if not self.events[name] then
		self.events[name] = Event.new()
	end
	return self.events[name]:connect(func)
end

function networkUtil:setCallback(name, callback) --Creates a callback with a given function. This will run if the name argument(first argument in the InvokeServer or InvokeClient) is the same as the name argument.
	self.callbacks[name] = callback
end

_G[GLOBAL_NAME] = networkUtil

return networkUtil