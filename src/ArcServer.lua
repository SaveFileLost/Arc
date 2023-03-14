local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local requireFolder = require(script.Parent.Utility.requireFolder)
local getTime = require(script.Parent.Utility.getTime)
local deepCopy = require(script.Parent.Utility.deepCopy)
local CommandUtils = require(script.Parent.Utility.CommandUtils)
local SnapshotUtils = require(script.Parent.Utility.SnapshotUtils)
local Similar = require(script.Parent.Similar)

local TableReserver = require(script.Parent.Classes.TableReserver)
local Client = require(script.Parent.Classes.Client)

local Controllers = require(script.Parent.Controllers)
local Entities = require(script.Parent.Entities)
local Input = require(script.Parent.Input)
local Rpc = require(script.Parent.Rpc)
local PubTypes = require(script.Parent.PubTypes)

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()

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
    service.tickPriority = 0

    service.init = function() end
    service.start = function() end

    function service:bindServerRpc(rpcName: string)
        local method = self[rpcName]
        assert(method ~= nil, `No corresponding method on Controller for rpc {rpcName}`)

        Rpc.bindCallback(rpcName, function(...)
            method(self, ...)
        end)

        -- replace method with function that calls rpc
        self[rpcName] = function(self, targets, ...)
            error(`Tried calling ServerRpc {rpcName} on the server`, 2)
        end
    end

    serviceMap[name] = service
    return service
end

local tickableServices: PubTypes.List<PubTypes.Service> = {}

local function startServices()
     -- check for undeclared services
     for name in pairs(serviceReserver.reserve) do
        assert(serviceMap[name] ~= nil, `Service {name} is never defined`)
    end

    for _, service in pairs(serviceMap) do
        if service[tick] then
            table.insert(tickableServices, service)
        end

        service:init()
    end

    -- priority goes from lesser to higher
    table.sort(tickableServices, function(sv1, sv2)
        return (sv1.tickPriority or 0) < (sv2.tickPriority or 0)
    end)

    for _, service in pairs(serviceMap) do
        service:start()
    end
end

local currentTick: number

local function runServiceTick()
    for _, service in ipairs(tickableServices) do
        service:tick(currentTick)
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

    for _, call in ipairs(command.serverRpcs) do
        Rpc.runCallback(call.name, sender, table.unpack(call.args))
    end

    local client = clients[sender]
    client:pushCommand(command)
end

local function onPlayerJoined(player: Player)
    local pawn = Entities.spawnEntity(CLIENT_ENTITY_KIND)
    local client = Client.new(player, pawn)

    clients[player] = client
end

local function onPlayerLeft(player: Player)
    local client = clients[player]

    clients[player] = nil
    deleteEntity(client.entity)
end

local isCurrentlySimulating = false
local currentSimulatingPlayer: Player?
local function simulateClients()
    isCurrentlySimulating = true
    for _, client in pairs(clients) do
        currentSimulatingPlayer = client.player
        client:processCommands()
    end

    currentSimulatingPlayer = nil
    isCurrentlySimulating = false
end

local pendingRpcs = {}
local function callClientRpc(rpcName: string, targets: PubTypes.Set<Player>, ...: any)
    if targets == Rpc.EVERYONE then
        targets = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            targets[plr] = true
        end
    end
    
    -- cull for caller if simulating
    if isCurrentlySimulating and currentSimulatingPlayer and Rpc.isCulling() then
        targets[currentSimulatingPlayer] = nil
    end

    table.insert(pendingRpcs, Rpc.makeClientCall(rpcName, targets, ...))
end
-- i DO NOT like this
Controllers.setClientRpcCallFunction(callClientRpc)

local function callServerRpc()
    -- empty since server rpc calls are not predictable, but we still want them to exist in a shared context
end

local lastWorldSnapshotMap: PubTypes.Map<number, PubTypes.Entity>

local function sendSnapshots()
    local allEntitiesMap = Entities.getAllMap()

    -- calculate differences since last snapshot
    local deltaEntities = {}
    local allEntities = {}
    for id, ent in pairs(allEntitiesMap) do
        local oldEnt = lastWorldSnapshotMap[id]
        
        table.insert(allEntities, ent)

        -- we must include this entity if its new
        if oldEnt == nil then
            table.insert(deltaEntities, ent)
        else
            local intersection, fullySimilar = Entities.netDeltaIntersection(ent, oldEnt)

            -- if entity didnt change, dont send it at all
            if not fullySimilar then
                table.insert(deltaEntities, intersection)
            end
        end
    end

    -- initialize snapshot
    local snapshot: PubTypes.Snapshot = {
        tick = 0;
        clientId = 0;
        entities = deltaEntities;
        deletedEntityIds = deletedEntityIds;
        rpcs = {};
    }

    -- Send snapshots
    for player, client in pairs(clients) do
        -- client hasnt simulated anything yet, dont send this
        if client.lastSimulatedTick == nil then continue end

        --personalize snapshot for this client
        snapshot.tick = client.lastSimulatedTick
        snapshot.clientId = client.entity.id
        snapshot.entities = if client.grantFullSnapshot then allEntities else deltaEntities
        snapshot.rpcs = {}

        -- personalize rpcs
        for _, rpc in ipairs(pendingRpcs) do
            if not rpc.targets[player] then continue end
            table.insert(snapshot.rpcs, {
                name = rpc.name;
                args = rpc.args;
            })
        end

        local serializedSnapshot = SnapshotUtils.serialize(snapshot)
        networkRemote:FireClient(player, serializedSnapshot)
    end

    table.clear(pendingRpcs)
    table.clear(deletedEntityIds)
end

local function processTick()
    lastWorldSnapshotMap = deepCopy(Entities.getAllMap())
    simulateClients()
    runServiceTick()
    sendSnapshots()
end

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

    local rpcIdentifiers = Rpc.getRpcIdentifiersAsJson()
    Rpc.setRpcIdentifiersFromJson(rpcIdentifiers) -- let server know the ids too

    networkRemote = Instance.new("RemoteEvent")
    networkRemote.Name = "Network"
    networkRemote:SetAttribute("TickRate", TICK_RATE)
    networkRemote:SetAttribute("StartTime", START_TIME)
    networkRemote:SetAttribute("KindIdentifiers", entityIdentifiers)
    networkRemote:SetAttribute("RpcIdentifiers", rpcIdentifiers)
    networkRemote.Parent = script.Parent

    startServices()
    Controllers.start()

    networkRemote.OnServerEvent:Connect(receiveCommand)
    Players.PlayerAdded:Connect(onPlayerJoined)
    Players.PlayerRemoving:Connect(onPlayerLeft)
    RunService.Heartbeat:Connect(onHeartbeat)
end

local ArcServer: PubTypes.ArcServer = {
    IS_SERVER = IS_SERVER;
    IS_CLIENT = IS_CLIENT;

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

    Entity = Entities.Entity;
    spawnEntity = Entities.spawnEntity;
    deleteEntity = deleteEntity;

    setClientEntityKind = setClientEntityKind;

    getAllEntities = Entities.getAll;
    getAllEntitiesWhere = Entities.getAllWhere;
    getFirstEntityWhere = Entities.getFirstWhere;
    getEntityById = Entities.getById;

    RPC_EVERYONE = Rpc.EVERYONE;
        
    ClientRpc = Rpc.Client;
    ServerRpc = Rpc.Server;
    bindRpcCallback = Rpc.bindCallback;

    callClientRpc = callClientRpc;
    callServerRpc = callServerRpc;

    pauseRpcCulling = Rpc.pauseCulling;
    resumeRpcCulling = Rpc.resumeCulling;
    isRpcCulling = Rpc.isCulling;

    NetVector3 = require(script.Parent.Net.NetVector3);

    Similar = Similar;

    addFolder = requireFolder;
    start = start;
}

return table.freeze(ArcServer)