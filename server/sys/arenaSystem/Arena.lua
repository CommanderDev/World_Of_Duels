local Arena = {}
Arena.__index = Arena
function Arena.new(arenaModel) 
    print(arenaModel.Name.." created!")
    local self = setmetatable({}, Arena)
    self.arenaModel = arenaModel
end

return Arena