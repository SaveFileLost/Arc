local Entities = require(script.Parent.Parent.Entities)

local BitBuffer = require(script.Parent.Parent.Classes.BitBuffer)

local PubTypes = require(script.Parent.Parent.PubTypes)

local function serialize(snapshot: PubTypes.Snapshot): string
    local buffer = BitBuffer.new()

    buffer:writeUInt(24, snapshot.tick)
    buffer:writeUInt(24, snapshot.clientId)
    
    -- 16 bit uint max value is 65535, no way anybody is going to have more entities at once than that
    -- this value represents the amount of entities
    buffer:writeUInt(16, #snapshot.entities)
    for _, ent in ipairs(snapshot.entities) do
        Entities.serialize(ent, buffer)
    end

    return buffer:toString()
end

local function deserialize(str: string): PubTypes.Snapshot
    local buffer = BitBuffer.fromString(str)

    local snapshot = {
        tick = buffer:readUInt(24);
        clientId = buffer:readUInt(24);
        entities = {};
    }

    local entityCount = buffer:readUInt(16)
    while entityCount > 0 do
        table.insert(snapshot.entities, Entities.deserialize(buffer))
        entityCount -= 1
    end

    return snapshot
end

return table.freeze {
    serialize = serialize;
    deserialize = deserialize;
}