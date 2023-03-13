local HttpService = game:GetService("HttpService")

local IS_CLIENT = game:GetService("RunService"):IsClient()

local BitBuffer = require(script.Parent.Classes.BitBuffer)

local PubTypes = require(script.Parent.PubTypes)
local Types = require(script.Parent.Types)

local entityKinds: PubTypes.Map<string, Types.EntityKind> = {}
local entities: PubTypes.Map<number, PubTypes.Entity> = {}

local function Entity(def: PubTypes.EntityDefinition)
    assert(entityKinds[def.kind] == nil, `Entity kind {def.kind} already exists`)

    -- for serialization / deserialization
    -- lets us represent properties as uints
    local netPropertyIdToName = {}
    local netPropertyNameToId = {}
    local netPropertyId = 0
    for propName in pairs(def.netProperties) do
        netPropertyId += 1

        netPropertyIdToName[netPropertyId] = propName
        netPropertyNameToId[propName] = netPropertyId
    end

    entityKinds[def.kind] = {
        netProperties = def.netProperties;
        netPropertyIdToName = netPropertyIdToName;
        netPropertyNameToId = netPropertyNameToId;

        initializer = def.init;
    }
end

-- this creates and inits an entity
local function createEntity(kind: string): PubTypes.Entity
    local entKind = entityKinds[kind]
    assert(entKind ~= nil, `Entity kind {kind} does not exist`)

    local entity = {
        kind = kind;
        id = 0;
        active = true;
        authority = true;
    }
    
    return entity
end

local lastClientId = 0
local lastServerId = 0
-- this spawns the entity into the world and is exposed via the api
local function spawnEntity(kind: string): PubTypes.Entity
    local entKind = entityKinds[kind]
    assert(entKind ~= nil, `Entity kind {kind} does not exist`)

    local entity = createEntity(kind)
    
    if IS_CLIENT then
        -- using negative ids allows us to distinguish clientside entities
        lastClientId += 1
        entity.id = -lastClientId
    else
        lastServerId += 1
        entity.id = lastServerId
    end

    entKind.initializer(entity)

    entities[entity.id] = entity

    return entity
end

local function deleteEntityInternal(ent: PubTypes.Entity)
    assert(ent, `Tried to deleted nil`)
    assert(ent.active, `Tried to deleted an already deleted entity {ent.id}`)
    
    local entity = entities[ent.id]
    assert(entity ~= nil, `Tried to remove non existent entity {ent.id}`)

    entity.active = false
    entities[ent.id] = nil
end

local function deleteEntity(ent: PubTypes.Entity | number)
    if typeof(ent) == "number" then
        ent = entities[ent]
    end

    deleteEntityInternal(ent :: PubTypes.Entity)
end

local function deleteEntityPublic(ent: PubTypes.Entity)
    assert(ent.authority, `Tried to remove entity {ent.id} we don't have authority to`)
    deleteEntity(ent)
end

-- should only really be called on the server to replicate the correct kind to id correlations
local function getKindIdentifiersAsJson(): string
    local identifiers = {}
    local id = 1
    for kindName in pairs(entityKinds) do
        identifiers[id] = kindName
        id += 1
    end

    return HttpService:JSONEncode(identifiers)
end

-- when serializing entities, their kind is serialized as ids, which are 16 bit UInts
-- the id to kind correlation is specified by the server
local idToKindMap: PubTypes.Map<number, string> = {}
local kindToIdMap: PubTypes.Map<string, number> = {}
local function setKindIdentifiersFromJson(kindIdents: string)
    idToKindMap = HttpService:JSONDecode(kindIdents)
    for id, kind in pairs(idToKindMap) do
        kindToIdMap[kind] = id
    end
end

local function serialize(ent: PubTypes.Entity, buffer: PubTypes.BitBuffer)
    buffer:writeUInt(16, kindToIdMap[ent.kind])
    -- UInt because we will only ever need to serialize server entities, and they are unsigned
    buffer:writeUInt(24, ent.id)

    local kind = entityKinds[ent.kind]

    -- how many net properties this entity has set
    local netPropertyCount = 0
    for propName in pairs(kind.netProperties) do
        -- if its nil, its not replicated
        if ent[propName] == nil then continue end
        netPropertyCount += 1
    end

    -- how many properties we are replicating
    buffer:writeUInt(8, netPropertyCount)

    for propName, netProp in pairs(kind.netProperties) do
        if ent[propName] == nil then continue end

        -- write property identifier to let us distinguish properties when deserializing
        buffer:writeUInt(8, kind.netPropertyNameToId[propName])

        netProp.write(ent[propName], buffer)
    end
end

local function deserialize(buffer: PubTypes.BitBuffer): PubTypes.Entity
    local kindName = idToKindMap[buffer:readUInt(16)]
    local entity = createEntity(kindName)
    entity.id = buffer:readUInt(24)

    local kind = entityKinds[kindName]

    -- how many properties we received
    local propertiesRemaining = buffer:readUInt(8)
    while propertiesRemaining > 0 do
        -- convert id to property name
        local netPropName = kind.netPropertyIdToName[buffer:readUInt(8)]

        entity[netPropName] = kind.netProperties[netPropName].read(buffer)
        propertiesRemaining -= 1
    end

    return entity
end

local function areSimilar(entity1: PubTypes.Entity, entity2: PubTypes.Entity): (boolean, Types.SimilarityMismatch?)
    assert(entity1.kind == entity2.kind, "Tried comparing 2 entities of different kinds")
    local entKind = entityKinds[entity1.kind]
    
    for propName, netProp in pairs(entKind.netProperties) do
        local prop1, prop2 = entity1[propName], entity2[propName]
        if not netProp.areSimilar(prop1, prop2) then
            return false, {propName = propName; value1 = prop1; value2 = prop2; }
        end
    end

    return true
end

-- return an entity with only the net properties that have changed
-- used for delta compression
local function netDeltaIntersection(current: PubTypes.Entity, old: PubTypes.Entity): (PubTypes.Entity, boolean)
    assert(current.kind == current.kind, "Tried getting difference for 2 entities of different kinds")
    local entKind = entityKinds[current.kind]
    
    local diff: PubTypes.Entity = {
        kind = current.kind;
        id = current.id;
        authority = current.authority;
        active = current.active;
    }

    local diffCount = 0
    for propName, netProp in pairs(entKind.netProperties) do
        local prop1 = current[propName]
        local prop2 = old[propName]
        if not netProp.areSimilar(prop1, prop2) then
            diff[propName] = prop1
            diffCount += 1
        end
    end

    -- return the diff, fullySimilar
    return diff, diffCount == 0
end

local function getAll(): PubTypes.List<PubTypes.Entity>
    local entList = {}
    for _, v in pairs(entities) do
        table.insert(entList, v)
    end

    return entList
end

local function getAllMap(): PubTypes.Map<number, PubTypes.Entity>
    return table.clone(entities)
end

local function getAllWhere(predicate: PubTypes.EntityPredicate): PubTypes.List<PubTypes.Entity>
    local entList = {}
    for _, v in pairs(entities) do
        if predicate(v) then
            table.insert(entList, v)
        end
    end

    return entList
end

local function getFirstWhere(predicate: PubTypes.EntityPredicate): PubTypes.Entity?
    for _, ent in pairs(entities) do
        if predicate(ent) then
            return ent
        end
    end

    return nil
end

local function getById(id: number): PubTypes.Entity?
    return entities[id]
end

-- overrides entity with the same id
local function override(entity: PubTypes.Entity)
    local oldEnt = entities[entity.id]
    if oldEnt then
        deleteEntity(oldEnt)
    end

    -- set the entity directly
    entities[entity.id] = entity
end

local function merge(entity: PubTypes.Entity)
    local intoEntity = entities[entity.id]

    -- entity we want to merge into doesnt exist, create from this
    if intoEntity == nil then
        entities[entity.id] = entity
        return entity
    end

    for k, v in pairs(entity) do
        intoEntity[k] = v
    end

    return intoEntity
end

return table.freeze({
    Entity = Entity;
    createEntity = createEntity;

    spawnEntity = spawnEntity;
    deleteEntity = deleteEntity;
    deleteEntityPublic = deleteEntityPublic;
    override = override;
    merge = merge;

    getKindIdentifiersAsJson = getKindIdentifiersAsJson;
    setKindIdentifiersFromJson = setKindIdentifiersFromJson;
    serialize = serialize;
    deserialize = deserialize;
    areSimilar = areSimilar;
    netDeltaIntersection = netDeltaIntersection;

    getAll = getAll;
    getAllMap = getAllMap;

    getAllWhere = getAllWhere;
    getFirstWhere = getFirstWhere;

    getById = getById;
})