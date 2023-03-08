local TableReserver = {}
TableReserver.__index = TableReserver

function TableReserver.new()
    return setmetatable({reserve = {}}, TableReserver)
end

function TableReserver:getOrReserve(id: string)
    local table = self.reserve[id]
    if table == nil then
        table = {}
        self.reserve[id] = table
    end

    return table
end

return TableReserver