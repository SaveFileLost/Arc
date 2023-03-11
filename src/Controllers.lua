local TableReserver = require(script.Parent.Classes.TableReserver)

local Rpc = require(script.Parent.Rpc)
local PubTypes = require(script.Parent.PubTypes)

local rpcCallFunction
local function setRpcCallFunction(func)
    rpcCallFunction = func
end

local controllerReserver = TableReserver.new()
local controllerMap: PubTypes.Map<string, PubTypes.Controller> = {}

local function getController(name: string): PubTypes.Controller
    return controllerReserver:getOrReserve(name)
end

local function Controller(name: string): PubTypes.Controller
    local controller = controllerReserver:getOrReserve(name)
    controller.name = name

    function controller:init() end
    function controller:start() end
    
    function controller:bindRpc(rpcName: string)
        local method = self[rpcName]
        assert(method ~= nil, `No corresponding method on Controller for rpc {rpcName}`)

        Rpc.bindCallback(rpcName, function(...)
            method(self, ...)
        end)

        -- replace method with function that calls rpc
        self[rpcName] = function(self, targets, ...)
            assert(typeof(targets) == "table", `Rpc targets must be a Player set`)
            rpcCallFunction(rpcName, targets, ...)
        end
    end

    controllerMap[name] = controller
    return controller
end

local simulatableControllers: PubTypes.List<PubTypes.Controller> = {}
local frameSimulatableControllers: PubTypes.List<PubTypes.Controller> = {}

local function start()
    -- check for undeclared controllers
    for name in pairs(controllerReserver.reserve) do
        assert(controllerMap[name] ~= nil, `Controller {name} is never defined`)
    end

    for _, controller in pairs(controllerMap) do
        if controller.simulate ~= nil then
            table.insert(simulatableControllers, controller)
        end

        if controller.frameSimulate ~= nil then
            table.insert(frameSimulatableControllers, controller)
        end
        
        controller:init()
    end

    -- priority goes from lesser to higher
    table.sort(simulatableControllers, function(ct1, ct2)
        return (ct1.simulationPriority or 0) < (ct2.simulationPriority or 0)
    end)

    for _, controller in pairs(controllerMap) do
        controller:start()
    end
end

local function simulate(playerEntity: PubTypes.Entity, input: PubTypes.Input)
    for _, controller in ipairs(simulatableControllers) do
        controller:simulate(playerEntity, input)
    end
end

local function frameSimulate(playerEntity: PubTypes.Entity, input: PubTypes.Input)
    for _, controller in ipairs(frameSimulatableControllers) do
        controller:frameSimulate(playerEntity, input)
    end
end

return table.freeze({
    getController = getController;
    Controller = Controller;

    start = start;

    simulate = simulate;
    frameSimulate = frameSimulate;

    setRpcCallFunction = setRpcCallFunction;
})