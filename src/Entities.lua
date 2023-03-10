local HttpService = game:GetService("HttpService")

local IS_CLIENT = game:GetService("RunService"):IsClient()

local BitBuffer = require(script.Parent.Classes.BitBuffer)

local PubTypes = require(script.Parent.PubTypes)
local Types = require(script.Parent.Types)

local entityKinds: PubTypes.Map<string, Types.EntityKind> = {}
local entities: PubTypes.Map<number, Types.Entity> = {}

local lastKindIdentifier = 0
local function Entity(def: PubTypes.EntityDefinition)
    assert(entityKinds[def.kind] == nil, `Entity kind {def.kind} already exists`)

    lastKindIdentifier += 1

    entityKinds[def.kind] = {
        initializer = def.init;
        writer = def.write;
        reader = def.read;
        comparer = def.compare;
    }
end

-- this creates and inits an entity
local function createEntity(kind: string): Types.Entity
    local entKind = entityKinds[kind]
    assert(entKind ~= nil, `Entity kind {kind} does not exist`)

    local entity = {
        kind = kind;
        id = 0;
        active = true;
        authority = true;

        parent = nil;
        childIds = {};
    }

    entKind.initializer(entity)

    return entity
end

local lastClientId = 0
local lastServerId = 0
-- this spawns the entity into the world and is exposed via the api
local function spawnEntity(kind: string): Types.Entity
    local entity = createEntity(kind)
    
    if IS_CLIENT then
        -- using negative ids allows us to distinguish clientside entities
        lastClientId += 1
        entity.id = -lastClientId
    else
        lastServerId += 1
        entity.id = lastServerId
    end

    entities[entity.id] = entity

    return entity
end

local function setParent(child: Types.Entity, parent: Types.Entity?)
    assert(child.authority, `Can't change parent of {child.id}, we are not authority`)
    assert(child.active, `Can't change parent of deleted entity {child.id}`)

    -- if parent is the same we dont need to change anything
    if (child.parentId == nil and parent == nil) or child.parentId == parent.id then return end

    -- clear current parent
    if child.parentId then
        local parentEntity = entities[child.parentId]
        local ourIndex = parentEntity and table.find(parentEntity.childIds, child.id)
        if ourIndex then
            table.remove(parentEntity.childIds, ourIndex)
        end

        child.parentId = nil
    end

    if parent == nil then return end
    assert(parent, "") -- for typechecker
    assert(parent.active, `Can't parent entity {child.id} to deleted entity {parent.id}`)

    child.parentId = parent.id
    table.insert(parent.childIds, child.id)
end

local function getParent(ent: Types.Entity): PubTypes.Entity?
    return entities[ent.parentId]
end

local function getChildren(ent: Types.Entity): PubTypes.List<PubTypes.Entity>
    local children = table.create(#ent.childIds)
    for i, id: number in ipairs(ent.childIds) do
        local child = entities[id]
        assert(child ~= nil, `One of child ids in entity {ent.id} was nil, how did this happen??`)
        children[i] = child
    end

    return children
end

local function deleteEntity(ent: PubTypes.Entity)
    assert(ent.active, `Tried to deleted an already deleted entity {ent.id}`)
    assert(ent.authority, `Tried to remove entity {ent.id} we don't have authority to`)
    
    local entity = entities[ent.id]
    assert(entity ~= nil, `Tried to remove non existent entity {ent.id}`)

    -- break link with parent
    setParent(entity, nil)

    entity.active = false
    entities[ent.id] = nil
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

local function serialize(ent: Types.Entity, buffer: PubTypes.BitBuffer): string
    buffer:writeUInt(16, kindToIdMap[ent.kind])
    -- UInt because we will only ever need to serialize server entities, and they are unsigned
    buffer:writeUInt(24, ent.id)

    entityKinds[ent.kind].writer(ent, buffer)

    return buffer:toString()
end

local function deserialize(buffer: PubTypes.BitBuffer): PubTypes.Entity
    local kind = idToKindMap[buffer:readUInt(16)]
    local entity = createEntity(kind)

    entity.id = buffer:readUInt(24)

    entityKinds[kind].reader(entity, buffer)

    return entity
end

local function getAll(): PubTypes.List<PubTypes.Entity>
    local entList = {}
    for _, v in pairs(entities) do
        table.insert(entList, v)
    end

    return entList
end

return table.freeze({
    Entity = Entity;
    createEntity = createEntity;

    spawnEntity = spawnEntity;
    deleteEntity = deleteEntity;

    getParent = getParent;
    setParent = setParent;
    getChildren = getChildren;

    getKindIdentifiersAsJson = getKindIdentifiersAsJson;
    setKindIdentifiersFromJson = setKindIdentifiersFromJson;
    serialize = serialize;
    deserialize = deserialize;

    getAll = getAll;
})