--Using "Object Oriented Programming"

local RunService = game:GetService("RunService")

local EventSignal = require(script.EventSignal)

local Event = {}
Event.__index = Event

local GLOBAL_NAME = "Event"

function Event:connect(func) --Connects a new function to be fired on a certain event.
	local signal = EventSignal.new(func)	
	table.insert(self.signals, signal)	
	return signal
end

function Event:disconnect(index) --Disconnectsthe function in the given index.
	table.remove(self.signals, index)
end
function Event:disconnectAll()
	for index, value in next, self.signals  do
		self:disconnect(index) 
	end 
end 
function Event:fire(...) --Fires the event and calls every function in the event's connection.
	for index, signal in next, self.signals do
		if signal.connected then
			coroutine.wrap(signal.fire)(signal, ...)
		else
			self:disconnect(index)		
		end
	end
end

function Event:wait() --Essentially never used and outdated concept and can be worked around without.
	local returnValues
	
	local signal 
	signal = self:connect(function(...)
		returnValues = {...}
		signal:disconnect()
	end)
	while signal.connected do RunService.Stepped:Wait() end
	return unpack(returnValues)
end

Event.new = function() --Creates a new event.
	local self = setmetatable({}, Event)	

	self.signals = {}
	
	return self
end

_G[GLOBAL_NAME] = Event

return Event