local TableReserver = require(script.Parent.TableReserver)
local PubTypes = require(script.Parent.PubTypes)

local controllerReserver = TableReserver.new()
local controllerMap: PubTypes.Map<string, PubTypes.Controller> = {}

local function getController(name: string): PubTypes.Controller
    return controllerReserver:getOrReserve(name)
end

local function Controller(name: string): PubTypes.Controller
    local controller = controllerReserver:getOrReserve(name)
    controller.name = name

    controller.init = function() end
    controller.start = function() end

    controllerMap[name] = controller
    return controller
end

local function start()
    -- check for undeclared controllers
    for name in pairs(controllerReserver.reserve) do
        assert(controllerMap[name] ~= nil, `Controller {name} is never defined`)
    end

    for _, controller in pairs(controllerMap) do
        controller:init()
    end

    for _, controller in pairs(controllerMap) do
        controller:start()
    end
end

return {
    getController = getController;
    Controller = Controller;

    start = start;
}