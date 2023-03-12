local BitBuffer = require(script.Parent.Parent.Classes.BitBuffer)
local Rpc = require(script.Parent.Parent.Rpc)
local PubTypes = require(script.Parent.Parent.PubTypes)

local function generateSerializedCommand(
    tick: number, requestFullSnapshot: boolean, input: PubTypes.Input, writeInput: PubTypes.InputWriter, serverRpcs: PubTypes.List<PubTypes.RpcCall>
): string
    local buffer = BitBuffer.new()
    buffer:writeUInt(24, tick) -- encode tick as 24 bit integer, which is enough to keep the server running for 176 days at 66 tickrate
    buffer:writeBool(requestFullSnapshot)
    writeInput(input, buffer) -- serialize input

    buffer:writeUInt(16, #serverRpcs)
    for _, call in ipairs(serverRpcs) do
        Rpc.serialize(call, buffer)
    end

    return buffer:toString()
end

local function deserializeCommand(str: string, readInput: PubTypes.InputReader): PubTypes.Command
    local buffer = BitBuffer.fromString(str)
    
    local tick = buffer:readUInt(24)
    local requestFullSnapshot = buffer:readBool()

    local input = {}
    readInput(input, buffer) -- deserialize input

    local serverRpcs = {}
    local rpcCount = buffer:readUInt(16)
    while rpcCount > 0 do
        table.insert(serverRpcs, Rpc.deserialize(buffer))
        rpcCount -= 1
    end

    return {
        tick = tick;
        requestFullSnapshot = requestFullSnapshot;
        input = input;
        serverRpcs = serverRpcs;
    }
end

return table.freeze({
    generateSerializedCommand = generateSerializedCommand;
    deserializeCommand = deserializeCommand;
})