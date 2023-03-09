local BitBuffer = require(script.Parent.Parent.Classes.BitBuffer)
local PubTypes = require(script.Parent.Parent.PubTypes)

local function generateSerializedCommand(tick: number, input: PubTypes.Input, writeInput: PubTypes.InputWriter): string
    local buffer = BitBuffer.new()
    buffer:writeUInt(24, tick) -- encode tick as 24 bit integer, which is enough to keep the server running for 176 days at 66 tickrate
    writeInput(input, buffer) -- serialize input

    return buffer:toString()
end

local function deserializeCommand(str: string, readInput: PubTypes.InputReader): PubTypes.Command
    local buffer = BitBuffer.fromString(str)
    
    local tick = buffer:readUInt(24)

    local input = {}
    readInput(input, buffer) -- deserialize input

    return {
        tick = tick;
        input = input;
    }
end

return table.freeze({
    generateSerializedCommand = generateSerializedCommand;
    deserializeCommand = deserializeCommand;
})