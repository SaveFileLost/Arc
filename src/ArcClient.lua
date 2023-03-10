local RunService = game:GetService("RunService")

local requireFolder = require(script.Parent.Utility.requireFolder)
local deepCopy = require(script.Parent.Utility.deepCopy)
local getTime = require(script.Parent.Utility.getTime)
local CommandUtils = require(script.Parent.Utility.CommandUtils)
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
local predictedStateBuffer

local playerState = {}

local function getTickRate(): number
    return TICK_RATE
end

local function predict(tick: number)
    local input: PubTypes.Input = inputBuffer:get(tick)

    Controllers.simulate(playerState, input)

    predictedStateBuffer:set(tick, deepCopy(playerState))
end

local function reconcile(serverPlayerState, serverTick)
    local predictedState = predictedStateBuffer:get(serverTick)

    if predictedState == nil then
        predictedState = serverPlayerState
        warn(`Received unpredicted state for tick {serverTick}`)
    end

    if deepIsEqual(predictedState, serverPlayerState) then return end

    warn(`Prediction error on tick {serverTick}, reconciling`)
    warn("Predicted", predictedState, "Server", serverPlayerState)
    -- would be neat if we could tell what exactly caused the misprediction

    -- Initial reconciliation. Correct initial state
    predictedStateBuffer:set(serverTick, serverPlayerState)
    playerState = serverPlayerState

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
        local snapshot = table.remove(pendingSnapshots, #pendingSnapshots)
        reconcile(snapshot.state, snapshot.tick)
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
    local latestState = predictedStateBuffer:latest()
    if latestState == nil then return end

    Controllers.frameSimulate(latestState, Input.buildInput())
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
    predictedStateBuffer = PositionalBuffer.new(330)

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
        delete = Entities.deleteEntity;

        setParent = Entities.setParent;
        getParent = Entities.getParent;
        getChildren = Entities.getChildren;

        Entity = Entities.Entity;
    };

    Comparison = Comparison;

    addFolder = requireFolder;
    start = start;
})