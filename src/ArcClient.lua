local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local requireFolder = require(script.Parent.Utility.requireFolder)
local deepCopy = require(script.Parent.Utility.deepCopy)
local getTime = require(script.Parent.Utility.getTime)
local CommandUtils = require(script.Parent.Utility.CommandUtils)
local SnapshotUtils = require(script.Parent.Utility.SnapshotUtils)
local Similar = require(script.Parent.Similar)

local PositionalBuffer = require(script.Parent.Classes.PositionalBuffer)

local Controllers = require(script.Parent.Controllers)
local Entities = require(script.Parent.Entities)
local Input = require(script.Parent.Input)
local Rpc = require(script.Parent.Rpc)
local PubTypes = require(script.Parent.PubTypes)

local TICK_RATE: number
local START_TIME: number

local networkRemote: RemoteEvent

local currentTick: number
local inputBuffer
local predictedBuffer

local function getTickRate(): number
    return TICK_RATE
end


local playerEntity: PubTypes.Entity
local isPredicting = false

local function predict(tick: number)
    isPredicting = true

    local input: PubTypes.Input = inputBuffer:get(tick)

    Controllers.simulate(playerEntity, input)

    predictedBuffer:set(tick, deepCopy(playerEntity))

    isPredicting = false
end

local recentPredictionErrors = 0 -- used to request for full snapshot if things go south
local function reconcile(serverEntity: PubTypes.Entity, serverTick: number)
    local predictedEntity = predictedBuffer:get(serverTick)

    -- 1. we lagged out past the buffer 2. we dont have the player entity at all yet
    if predictedEntity == nil then
        -- deep copy here because serverEntity is an actual entity in the world
        -- so we dont want to reference it
        serverEntity = deepCopy(serverEntity)

        predictedEntity = serverEntity
        playerEntity = serverEntity
        warn(`Received unpredicted state for tick {serverTick}`)
    end

    local areSimilar, mismatchReason = Entities.areSimilar(predictedEntity, serverEntity)
    if areSimilar then return end

    recentPredictionErrors += 1
    warn(`Prediction error on tick {serverTick}, reconciling`)
    warn(`  ->{predictedEntity.kind}[{predictedEntity.id}].{mismatchReason.propName}`)
    warn(`  ->predicted {mismatchReason.value1}`)
    warn(`  ->received {mismatchReason.value2}`)
    -- would be neat if we could tell what exactly caused the misprediction

    -- Initial reconciliation. Correct initial state
    predictedBuffer:set(serverTick, deepCopy(serverEntity))
    playerEntity = serverEntity

    -- Re-predict everything that was mispredicted as a result of the faulty tick
    local tickToReconcile = serverTick + 1 -- serverTick is initial, we already have the state for it.
    while tickToReconcile < currentTick do
        predict(tickToReconcile)
        tickToReconcile += 1
    end
end

local pendingSnapshots = {}
local function processSnapshots()
    for _ = #pendingSnapshots, 1, -1 do
        local serializedSnapshot = table.remove(pendingSnapshots, #pendingSnapshots)
        local snapshot = SnapshotUtils.deserialize(serializedSnapshot)
        
        local clientEntity: PubTypes.Entity

        for _, entityData in ipairs(snapshot.entities) do
            local entity, existed = Entities.merge(entityData)
            entity.authority = false

            -- this is the first time the server sent us this entity
            if not existed then
                Entities.getKind(entity.kind).clientSpawn(entity)
            end

            -- this is our pawn
            -- even though its set above, the server could still have changed it
            if entity.id == snapshot.clientId then
                clientEntity = entity
            end
        end

        -- delete entities the server deleted
        for _, id in ipairs(snapshot.deletedEntityIds) do
            local ent = Entities.getById(id)
            if ent == nil then continue end

            Entities.getKind(ent.kind).clientDelete(ent)
            Entities.deleteEntity(ent)
        end

        -- run rpcs the server sent
        for _, rpcCall in ipairs(snapshot.rpcs) do
            Rpc.runCallback(rpcCall.name, table.unpack(rpcCall.args))
        end

        -- we didnt receive data about our entity, therefore we dont need to reconcile
        -- this means that it didnt change since the last tick
        if clientEntity ~= nil then
            reconcile(clientEntity, snapshot.tick)
        end
    end
end

local pendingServerRpcs = {}
local function callServerRpc(rpcName: string, ...: any)
    table.insert(pendingServerRpcs, Rpc.makeServerCall(rpcName, ...))
end

-- we just joined, we want to ask for full snapshot
local requestedFirstSnapshot = false

local function processTick()
    recentPredictionErrors = math.max(0, recentPredictionErrors - 0.5)

    processSnapshots()
    
    local input = Input.buildInput()
    inputBuffer:set(currentTick, input)

    if playerEntity ~= nil then
        predict(currentTick)
    end

    local command = CommandUtils.generateSerializedCommand(
        currentTick,
        recentPredictionErrors > 30 or not requestedFirstSnapshot, -- request full snapshot
        input,
        Input.getInputWriter(),
        pendingServerRpcs
    )
    networkRemote:FireServer(command)

    requestedFirstSnapshot = true

    table.clear(pendingServerRpcs)
end

local function onNetworkReceive(snapshot)
    table.insert(pendingSnapshots, 1, snapshot)
end

local function onHeartbeat()
    local nextTick = math.ceil((getTime() - START_TIME) * TICK_RATE)

    while currentTick < nextTick do
        processTick()
        currentTick += 1
    end
end

local function onPreRender()
    if playerEntity == nil then return end
    Controllers.frameSimulate(playerEntity, Input.buildInput())
end

local function start()
    Input.checkSetup()

    networkRemote = script.Parent:WaitForChild("Network")
    
    -- Tickrate and Start time are dictated by the server
    TICK_RATE = networkRemote:GetAttribute("TickRate")
    START_TIME = networkRemote:GetAttribute("StartTime")

    Entities.setKindIdentifiersFromJson(networkRemote:GetAttribute("KindIdentifiers"))
    Rpc.setRpcIdentifiersFromJson(networkRemote:GetAttribute("RpcIdentifiers"))

    currentTick = math.ceil((getTime() - START_TIME) * TICK_RATE)
    inputBuffer = PositionalBuffer.new(330) -- Arbitrary number, stores 5 seconds which is good enough
    predictedBuffer = PositionalBuffer.new(330)

    Controllers.start()

    networkRemote.OnClientEvent:Connect(onNetworkReceive)
    RunService.Heartbeat:Connect(onHeartbeat)
    RunService.PreRender:Connect(onPreRender)
end

local function callClientRpc(rpcName: string, targets: PubTypes.Set<Player>, ...: any)
    assert(isPredicting, `Can't call client Rpc on client outside of simulate`)
    
    if (not targets[Players.LocalPlayer] and targets ~= Rpc.EVERYONE) or not Rpc.isCulling() then
        return
    end

    Rpc.runCallback(rpcName, ...)
end
-- i DO NOT like this
Controllers.setClientRpcCallFunction(callClientRpc)

local ArcClient: PubTypes.ArcClient = {
    IS_SERVER = RunService:IsServer();
    IS_CLIENT = RunService:IsClient();

    getTickRate = getTickRate;
    getTime = getTime;

    setInputBuilder = Input.setInputBuilder;
    setInputWriter = Input.setInputWriter;
    setInputReader = Input.setInputReader;

    getController = Controllers.getController;
    Controller = Controllers.Controller;

    Entity = Entities.Entity;
    spawnEntity = Entities.spawnEntity;
    deleteEntity = Entities.deleteEntityPublic;

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

return table.freeze(ArcClient)