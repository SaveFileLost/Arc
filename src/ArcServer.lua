local requireFolder = require(script.Parent.requireFolder)
local TableReserver = require(script.Parent.TableReserver)
local PubTypes = require(script.Parent.PubTypes)

local TICK_RATE: number

local serviceReserver = TableReserver.new()
local serviceMap: PubTypes.Map<string, PubTypes.Service> = {}

local function getTickRate(): number
    return TICK_RATE
end

local function setTickRate(rate: number)
    TICK_RATE = rate
end

local function getService(name: string): PubTypes.Service
    return serviceReserver:getOrReserve(name)
end

local function Service(name: string): PubTypes.Service
    local service = serviceReserver:getOrReserve(name)
    service.name = name

    service.init = function() end
    service.start = function() end

    serviceMap[name] = service
    return service
end

local function start()
    assert(TICK_RATE ~= nil, "Tickrate not set")

    -- check for undeclared services
    for name in pairs(serviceReserver.reserve) do
        assert(serviceMap[name] ~= nil, `Service {name} is never defined`)
    end

    for _, service in pairs(serviceMap) do
        service:init()
    end

    for _, service in pairs(serviceMap) do
        service:start()
    end
end

return table.freeze({
    getTickRate = getTickRate;
    setTickRate = setTickRate;

    getService = getService;
    Service = Service;

    addFolder = requireFolder;
    start = start;
})