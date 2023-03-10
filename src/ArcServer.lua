local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local requireFolder = require(script.Parent.Utility.requireFolder)
local getTime = require(script.Parent.Utility.getTime)
local deepCopy = require(script.Parent.Utility.deepCopy)
local CommandUtils = require(script.Parent.Utility.CommandUtils)
local SnapshotUtils = require(script.Parent.Utility.SnapshotUtils)
local Comparison = require(script.Parent.Utility.Comparison)

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

local CLIENT_ENTITY_KIND: string
local function setClientEntityKind(kind: string)
    CLIENT_ENTITY_KIND = kind
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

local deletedEntityIds: PubTypes.List<number> = {}
local function deleteEntity(ent: PubTypes.Entity)
    Entities.deleteEntityPublic(ent)
    table.insert(deletedEntityIds, ent.id)
end

local clients = {}

local function receiveCommand(sender: Player, serializedCommand)
    local command = CommandUtils.deserializeCommand(serializedCommand, Input.getInputReader())

    local client = clients[sender]
    client:pushCommand(command)
end

local function onPlayerJoined(player: Player)
    clients[player] = Client.new(player, Entities.spawnEntity(CLIENT_ENTITY_KIND))
end

local function onPlayerLeft(player: Player)
    clients[player] = nil
end

local function processTick()
    -- Simulate
    for _, client in pairs(clients) do
        client:processCommands()
    end
    
    local allEntities = Entities.getAll()

    local deletedEntities = deletedEntityIds
    deletedEntityIds = {} -- we dont wanna clear, we wanna reassign to keep the original intact

    -- initialize snapshot
    local snapshot: PubTypes.Snapshot = {
        tick = 0;
        clientId = 0;
        entities = allEntities;
        deletedEntityIds = deletedEntities
    }

    -- Send snapshots
    for player, client in pairs(clients) do
        -- client hasnt simulated anything yet, dont send this
        if client.lastSimulatedTick == nil then continue end

        --personalize snapshot for this client
        snapshot.tick = client.lastSimulatedTick
        snapshot.clientId = client.entity.id

        local serializedSnapshot = SnapshotUtils.serialize(snapshot)
        networkRemote:FireClient(player, serializedSnapshot)
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
    assert(CLIENT_ENTITY_KIND ~= nil, "Client entity kind not set")

    Input.checkSetup()

    START_TIME = getTime()
    currentTick = math.ceil((getTime() - START_TIME) * TICK_RATE)

    local entityIdentifiers = Entities.getKindIdentifiersAsJson()
    Entities.setKindIdentifiersFromJson(entityIdentifiers) -- let server know the ids too

    networkRemote = Instance.new("RemoteEvent")
    networkRemote.Name = "Network"
    networkRemote:SetAttribute("TickRate", TICK_RATE)
    networkRemote:SetAttribute("StartTime", START_TIME)
    networkRemote:SetAttribute("KindIdentifiers", entityIdentifiers)
    networkRemote.Parent = script.Parent

    startServices()
    Controllers.start()

    networkRemote.OnServerEvent:Connect(receiveCommand)
    Players.PlayerAdded:Connect(onPlayerJoined)
    Players.PlayerRemoving:Connect(onPlayerLeft)
    RunService.Heartbeat:Connect(onHeartbeat)
end

return table.freeze {
    IS_SERVER = RunService:IsServer();
    IS_CLIENT = RunService:IsClient();

    getTickRate = getTickRate;
    setTickRate = setTickRate;

    getTime = getTime;
    
    setInputBuilder = Input.setInputBuilder;
    setInputWriter = Input.setInputWriter;
    setInputReader = Input.setInputReader;

    getService = getService;
    Service = Service;

    getController = Controllers.getController;
    Controller = Controllers.Controller;

    Entities = table.freeze {
        spawn = Entities.spawnEntity;
        delete = deleteEntity;

        setClientKind = setClientEntityKind;

        Entity = Entities.Entity;

        getAll = Entities.getAll;
        getAllWhere = Entities.getAllWhere;
        getFirstWhere = Entities.getFirstWhere;
        getById = Entities.getById;
    };

    Comparison = Comparison;

    addFolder = requireFolder;
    start = start;
}