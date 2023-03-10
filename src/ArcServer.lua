local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local requireFolder = require(script.Parent.Utility.requireFolder)
local getTime = require(script.Parent.Utility.getTime)
local CommandUtils = require(script.Parent.Utility.CommandUtils)

local TableReserver = require(script.Parent.Classes.TableReserver)
local Client = require(script.Parent.Classes.Client)

local Controllers = require(script.Parent.Controllers)
local Entities = require(script.Parent.Entities)
local Input = require(script.Parent.Input)
local PubTypes = require(script.Parent.PubTypes)

local TICK_RATE: number
local START_TIME: number
local networkRemote: RemoteEvent

local serviceReserver = TableReserver.new()
local serviceMap: PubTypes.Map<string, PubTypes.Service> = {}

local function getTickRate(): number
    return TICK_RATE
end

local function setTickRate(rate: number)
    TICK_RATE = rate
end

local clientEntityKind: string
local function setClientKind(entityKind: string)
    clientEntityKind = entityKind
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

local function startServices()
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

local clients = {}

local function receiveCommand(sender: Player, serializedCommand)
    local command = CommandUtils.deserializeCommand(serializedCommand, Input.getInputReader())

    local client = clients[sender]
    client:pushCommand(command)
end

local function onPlayerJoined(player: Player)
    clients[player] = Client.new(player)
end

local function onPlayerLeft(player: Player)
    clients[player] = nil
end

local function processTick()
    -- Simulate
    for _, client in pairs(clients) do
        client:processCommands()
    end

    -- Send snapshots
    for player, client in pairs(clients) do
        -- client hasnt simulated anything yet, dont send this
        if client.lastSimulatedTick == nil then continue end

        local snapshot = {
            tick = client.lastSimulatedTick;
            state = client.state;
        }
        networkRemote:FireClient(player, snapshot)
    end
end

local currentTick: number
local function onHeartbeat()
    local nextTick = math.ceil((getTime() - START_TIME) * TICK_RATE)

    while currentTick < nextTick do
        processTick()
        currentTick += 1
    end
end

local function start()
    assert(TICK_RATE ~= nil, "Tickrate not set")
    Input.checkSetup()

    START_TIME = getTime()
    currentTick = math.ceil((getTime() - START_TIME) * TICK_RATE)

    networkRemote = Instance.new("RemoteEvent")
    networkRemote.Name = "Network"
    networkRemote:SetAttribute("TickRate", TICK_RATE)
    networkRemote:SetAttribute("StartTime", START_TIME)
    networkRemote.Parent = script.Parent

    startServices()
    Controllers.start()

    networkRemote.OnServerEvent:Connect(receiveCommand)
    Players.PlayerAdded:Connect(onPlayerJoined)
    Players.PlayerRemoving:Connect(onPlayerLeft)
    RunService.Heartbeat:Connect(onHeartbeat)
end

return table.freeze({
    IS_SERVER = RunService:IsServer();
    IS_CLIENT = RunService:IsClient();

    getTickRate = getTickRate;
    setTickRate = setTickRate;
    setClientKind = setClientKind;

    getTime = getTime;
    
    setInputBuilder = Input.setInputBuilder;
    setInputWriter = Input.setInputWriter;
    setInputReader = Input.setInputReader;

    getService = getService;
    Service = Service;

    getController = Controllers.getController;
    Controller = Controllers.Controller;

    spawnEntity = Entities.spawnEntity;
    Entity = Entities.Entity;

    addFolder = requireFolder;
    start = start;
})