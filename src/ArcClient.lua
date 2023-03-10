local RunService = game:GetService("RunService")

local requireFolder = require(script.Parent.Utility.requireFolder)
local deepCopy = require(script.Parent.Utility.deepCopy)
local getTime = require(script.Parent.Utility.getTime)
local CommandUtils = require(script.Parent.Utility.CommandUtils)
local SnapshotUtils = require(script.Parent.Utility.SnapshotUtils)
local Comparison = require(script.Parent.Utility.Comparison)

local PositionalBuffer = require(script.Parent.Classes.PositionalBuffer)

local Controllers = require(script.Parent.Controllers)
local Entities = require(script.Parent.Entities)
local Input = require(script.Parent.Input)
local PubTypes = require(script.Parent.PubTypes)

local TICK_RATE: number
local START_TIME: number

local networkRemote: RemoteEvent

local currentTick: number
local inputBuffer
local predictedBuffer
local clientEntityId: number

local playerEntity: PubTypes.Entity

local function getTickRate(): number
    return TICK_RATE
end

local function predict(tick: number)
    local input: PubTypes.Input = inputBuffer:get(tick)

    Controllers.simulate(playerEntity, input)

    predictedBuffer:set(tick, deepCopy(playerEntity))
end

local function reconcile(serverEntity: PubTypes.Entity, serverTick: number)
    local predictedEntity = predictedBuffer:get(serverTick)
    
    -- 1. we lagged out past the buffer 2. we dont have the player entity at all yet
    if predictedEntity == nil then
        predictedEntity = serverEntity
        playerEntity = serverEntity
        warn(`Received unpredicted state for tick {serverTick}`)
    end

    if Entities.compare(predictedEntity, serverEntity) then return end

    warn(`Prediction error on tick {serverTick}, reconciling`)
    warn("Predicted", predictedEntity, "Server", serverEntity)
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

        for _, entity in ipairs(snapshot.entities) do
            if entity.id == snapshot.clientId then
                clientEntity = entity
                continue
            end

            Entities.override(entity)
            entity.authority = false
        end

        reconcile(clientEntity, snapshot.tick)
    end
end

local function processTick()
    processSnapshots()
    
    local input = Input.buildInput()
    inputBuffer:set(currentTick, input)

    local command = CommandUtils.generateSerializedCommand(
        currentTick,
        input,
        Input.getInputWriter()
    )
    networkRemote:FireServer(command)

    if playerEntity == nil then return end

    predict(currentTick)
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

    currentTick = math.ceil((getTime() - START_TIME) * TICK_RATE)
    inputBuffer = PositionalBuffer.new(330) -- Arbitrary number, stores 5 seconds which is good enough
    predictedBuffer = PositionalBuffer.new(330)

    Controllers.start()

    networkRemote.OnClientEvent:Connect(onNetworkReceive)
    RunService.Heartbeat:Connect(onHeartbeat)
    RunService.PreRender:Connect(onPreRender)
end

return table.freeze({
    IS_SERVER = RunService:IsServer();
    IS_CLIENT = RunService:IsClient();

    getTickRate = getTickRate;
    getTime = getTime;

    setInputBuilder = Input.setInputBuilder;
    setInputWriter = Input.setInputWriter;
    setInputReader = Input.setInputReader;

    getController = Controllers.getController;
    Controller = Controllers.Controller;

    Entities = table.freeze {
        spawn = Entities.spawnEntity;
        delete = Entities.deleteEntityPublic;

        Entity = Entities.Entity;
    };

    Comparison = Comparison;

    addFolder = requireFolder;
    start = start;
})