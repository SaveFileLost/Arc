local IS_CLIENT = game:GetService("RunService"):IsClient()

local PubTypes = require(script.Parent.PubTypes)
local Types = require(script.Parent.Types)

local entityKinds: PubTypes.Map<string, Types.EntityKind> = {}
local entities: PubTypes.Map<number, Types.Entity> = {}

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

return table.freeze({
    Entity = Entity;
    createEntity = createEntity;

    spawnEntity = spawnEntity;
    deleteEntity = deleteEntity;

    getParent = getParent;
    setParent = setParent;
    getChildren = getChildren;
})