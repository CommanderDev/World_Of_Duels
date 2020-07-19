local util = {}

GLOBAL_NAME = "util"

util.services = setmetatable({}, {
	__index = function(self, name)
		local service = game:GetService(name)
		self[name] = service
		return service
	end
})

--

util.get = function(name)
	assert(script:FindFirstChild(name), "no module found for " .. name)
	return require(script[name])
end

_G[GLOBAL_NAME] = util

return util