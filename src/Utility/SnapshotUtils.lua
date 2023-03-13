local Entities = require(script.Parent.Parent.Entities)
local Rpc = require(script.Parent.Parent.Rpc)

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

    -- deleted entities
    -- follows the same principle as above
    buffer:writeUInt(16, #snapshot.deletedEntityIds)
    for _, id in ipairs(snapshot.deletedEntityIds) do
        buffer:writeUInt(16, id)
    end

    -- sent client rpcs
    -- guess what? follows the same principle.
    buffer:writeUInt(16, #snapshot.rpcs)
    for _, call in ipairs(snapshot.rpcs) do
        Rpc.serialize(call, buffer)
    end

    return buffer:toString()
end

local function deserialize(str: string): PubTypes.Snapshot
    local buffer = BitBuffer.fromString(str)

    local snapshot = {
        tick = buffer:readUInt(24);
        clientId = buffer:readUInt(24);
        entities = {};
        deletedEntityIds = {};
        rpcs = {};
    }

    local entityCount = buffer:readUInt(16)
    while entityCount > 0 do
        table.insert(snapshot.entities, Entities.deserialize(buffer))
        entityCount -= 1
    end

    local deletedEntityCount = buffer:readUInt(16)
    while deletedEntityCount > 0 do
        table.insert(snapshot.deletedEntityIds, buffer:readUInt(16))
        deletedEntityCount -= 1
    end

    local rpcCount = buffer:readUInt(16)
    while rpcCount > 0 do
        table.insert(snapshot.rpcs, Rpc.deserialize(buffer))
        rpcCount -= 1
    end

    return snapshot
end

return table.freeze {
    serialize = serialize;
    deserialize = deserialize;
}