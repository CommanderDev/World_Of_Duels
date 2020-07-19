GLOBAL_NAME = "get"

--Example Usage: get "sys/playerSystem/Player"

local get = {}

get.filesystem = nil

function get:getFilesystem()
    return self.filesystem
end

function get:setFilesystem(folder)
    assert(folder:IsA("Folder"), "Filesystem must be a folder")
    self.filesystem = folder
end

local function parsePath(pathString)
    local steps = {}
    for step in pathString:gmatch("[%w_]+") do
        table.insert(steps, step)
    end
    return steps
end

local function navigateSteps(steps, path) --Navigates to a specific module.
    local object = get:getFilesystem()
    for i = 1, #steps do
        local name = steps[i]
        object = object:FindFirstChild(name)
        if not object then
            error("Item not found in filesystem " .. name .. " (" .. path .. ")" )
        end
    end
    return object
end

local function getReturnValue(object) --Returns specific module required.
    if object:IsA("ModuleScript") then
        return require(object)
    else
        return object
    end
end

local function getAllModules() --Gets all the modules.
    local modules = {}
    for index, module in next, get:getFilesystem():GetDescendants() do
        if module:IsA("ModuleScript") then
            table.insert(modules, getReturnValue(module))
			--print(#modules.." is the index for "..module.Name)
        end
    end
    return modules
end

setmetatable(get, 
    {
        __call = function(self, path)
            if path == "all" then --get "all" 
                return getAllModules()
            else
                local steps = parsePath(path)
                local destination = navigateSteps(steps, path)
                return getReturnValue(destination)
            end
        end
    }
)

_G[GLOBAL_NAME] = get

return get