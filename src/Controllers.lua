local TableReserver = require(script.Parent.Classes.TableReserver)

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

local simulatableControllers: PubTypes.List<PubTypes.Controller> = {}

local function start()
    -- check for undeclared controllers
    for name in pairs(controllerReserver.reserve) do
        assert(controllerMap[name] ~= nil, `Controller {name} is never defined`)
    end

    for _, controller in pairs(controllerMap) do
        if controller.simulate ~= nil then
            table.insert(simulatableControllers, controller)
        end
        
        controller:init()
    end

    -- priority goes from lesser to higher
    table.sort(simulatableControllers, function(ct1, ct2)
        return ct1.simulationPriority < ct2.simulationPriority
    end)

    for _, controller in pairs(controllerMap) do
        controller:start()
    end
end

local function simulate(playerState: PubTypes.Map<any, any>, input: PubTypes.Input)
    for _, controller in ipairs(simulatableControllers) do
        controller:simulate(playerState, input)
    end
end

return table.freeze({
    getController = getController;
    Controller = Controller;

    start = start;

    simulate = simulate;
})