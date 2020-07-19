local EventSignal = {}
EventSignal.__index = EventSignal

--Cloned to every function in the event.

function EventSignal:fire(...) --Fires the given event signal.
	self.func(...)
end

function EventSignal:disconnect() --Disconnects the signal entirely. Essentially never used though.
	self.connected = false
	self.func = nil
end

EventSignal.new = function(func) --Creates a new event signal.
	local self = setmetatable({}, EventSignal)
	
	self.func = func	
	self.connected = true	
	
	return self
end

return EventSignal