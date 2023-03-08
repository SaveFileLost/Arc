local RunService = game:GetService("RunService")

local requireFolder = require(script.Parent.Utility.requireFolder)
local deepCopy = require(script.Parent.Utility.deepCopy)
local deepIsEqual = require(script.Parent.Utility.deepIsEqual)
local getTime = require(script.Parent.Utility.getTime)

local PositionalBuffer = require(script.Parent.Classes.PositionalBuffer)

local Controllers = require(script.Parent.Controllers)
local PubTypes = require(script.Parent.PubTypes)

local TICK_RATE: number
local START_TIME: number

local networkRemote: RemoteEvent
local buildInput: () -> PubTypes.Input

local currentTick: number
local inputBuffer
local predictedStateBuffer

local playerState = {}

local function getTickRate(): number
    return TICK_RATE
end

local function setInputBuilder(inputBuilder: PubTypes.InputBuilder)
    buildInput = function()
        local input = {}
        inputBuilder(input)
        return input
    end
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
    -- would be neat if we could tell what exactly caused the misprediction

    -- Initial reconciliation. Correct initial state
    predictedStateBuffer:set(serverTick, serverPlayerState)
    playerState = serverPlayerState

    -- Re-predict everything that was mispredicted as a result of the faulty tick
    local tickToReconcile = serverTick + 1 -- serverTick is initial, we already have the state for it.
    while tickToReconcile <= currentTick do
        predict(tickToReconcile)
        tickToReconcile += 1
    end
end

local function processTick()
    local input = buildInput()
    inputBuffer:set(currentTick, input)

    local command = {
        tick = currentTick;
        input = input;
    }
    networkRemote:FireServer(command)

    predict(currentTick)
end

local function onNetworkReceive(snapshot)
    reconcile(snapshot.state, snapshot.tick)
end

local function onHeartbeat()
    local nextTick = math.ceil((getTime() - START_TIME) * TICK_RATE)

    while currentTick < nextTick do
        processTick()
        currentTick += 1
    end
end

local function start()
    assert(buildInput ~= nil, "Input builder is not set")

    networkRemote = script.Parent:WaitForChild("Network")
    
    -- Tickrate and Start time are dictated by the server
    TICK_RATE = networkRemote:GetAttribute("TickRate")
    START_TIME = networkRemote:GetAttribute("StartTime")

    currentTick = math.ceil((getTime() - START_TIME) * TICK_RATE)
    inputBuffer = PositionalBuffer.new(330) -- Arbitrary number, stores 5 seconds which is good enough
    predictedStateBuffer = PositionalBuffer.new(330)

    Controllers.start()

    networkRemote.OnClientEvent:Connect(onNetworkReceive)
    RunService.Heartbeat:Connect(onHeartbeat)
end

return table.freeze({
    IS_SERVER = RunService:IsServer();
    IS_CLIENT = RunService:IsClient();

    getTickRate = getTickRate;
    setInputBuilder = setInputBuilder;

    getTime = getTime;

    getController = Controllers.getController;
    Controller = Controllers.Controller;

    addFolder = requireFolder;
    start = start;
})