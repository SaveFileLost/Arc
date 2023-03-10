local PubTypes = require(script.Parent.PubTypes)
local Types = require(script.Parent.Types)

local entityKinds: PubTypes.Map<string, Types.EntityKind> = {}

local function Entity(def: PubTypes.EntityDefinition)
    assert(entityKinds[def.kind] == nil, `Entity kind {def.kind} already exists`)

    entityKinds[def.kind] = {
        initializer = def.init;
        writer = def.write;
        reader = def.read;
        comparer = def.compare;
    }
end

-- this creates and inits an entity
local function createEntity(kind: string): PubTypes.Entity
    local entKind = entityKinds[kind]
    assert(entKind ~= nil, `Entity kind {kind} does not exist`)

    local entity = {
        kind = kind;
        id = 0;
    }

    entKind.initializer(entity)

    return entity
end

-- this spawns the entity into the world and is exposed via the api
local function spawnEntity(kind: string): PubTypes.Entity
    return createEntity(kind)
end

return table.freeze({
    Entity = Entity;
    createEntity = createEntity;
    spawnEntity = spawnEntity;
})