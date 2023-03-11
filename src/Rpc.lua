local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local IS_SERVER = game:GetService("RunService"):IsServer()
local IS_CLIENT = not IS_SERVER

local PubTypes = require(script.Parent.PubTypes)
local Types = require(script.Parent.Types)

local EVERYONE = table.freeze {}

local rpcs: PubTypes.Map<string, Types.Rpc> = {}
local function ClientRpc(def: PubTypes.RpcDefinition)
    assert(rpcs[def.name] == nil, `Rpc with name {def.name} already exists`)
    
    rpcs[def.name] = {
        isServerRpc = false;
        writer = def.write;
        reader = def.read;
    }
end

local function bindCallback(rpcName: string, callback: PubTypes.RpcCallback)
    local rpc = rpcs[rpcName]
    assert(rpc, `Rpc {rpcName} does not exist`)
    
    if rpc.callback ~= nil then
        warn(`Replacing existing callback for Rpc {rpcName}`)
    end

    rpc.callback = callback
end

local cullPauseStack: PubTypes.List<string> = {}
local function pauseCulling()
    table.insert(cullPauseStack, 1, debug.traceback("Pause traceback", 2))
end

local function resumeCulling()
    table.remove(cullPauseStack, 1)
end

local function isCulling()
    return #cullPauseStack < 1
end

local function forceResumeCulling()
    for i, traceback in ipairs(cullPauseStack) do
        warn(i, traceback)
    end
    table.clear(cullPauseStack)
end

local function makeClientCall(rpcName: string, targets: PubTypes.Set<Player>, ...: any): PubTypes.PendingRpc
    local rpc = rpcs[rpcName]
    assert(rpc, `Rpc {rpcName} does not exist`)
    assert(not rpc.isServerRpc, `Rpc {rpcName} is a ServerRpc`)

    if targets == EVERYONE then
        for _, plr in ipairs(Players:GetPlayers()) do
            targets[plr] = true
        end
    end

    return {
        name = rpcName;
        args = {...};
        targets = targets;
    }
end

local function runCallback(rpcName: string, ...: any)
    local rpc = rpcs[rpcName]
    assert(rpc, `Rpc {rpcName} does not exist`)

    rpc.callback(...)
end

local function callServer(rpcName: string, ...: any)
    error("Server rpcs are not yet implemented")
end

-- should only really be called on the server to replicate the correct rpc to id correlations
local function getRpcIdentifiersAsJson(): string
    local identifiers = {}
    local id = 1
    for rpcName in pairs(rpcs) do
        identifiers[id] = rpcName
        id += 1
    end

    return HttpService:JSONEncode(identifiers)
end

-- read Entities.setKindIdentifiersFromJson
local idToRpcMap: PubTypes.Map<number, string> = {}
local rpcToIdMap: PubTypes.Map<string, number> = {}
local function setRpcIdentifiersFromJson(kindIdents: string)
    idToRpcMap = HttpService:JSONDecode(kindIdents)
    for id, kind in pairs(idToRpcMap) do
        rpcToIdMap[kind] = id
    end
end

local function serialize(call: PubTypes.ClientRpcCall, buffer: PubTypes.BitBuffer)
    local rpc = rpcs[call.name]
    buffer:writeUInt(16, rpcToIdMap[call.name])
    rpc.writer(buffer, table.unpack(call.args))
end

local function deserialize(buffer: PubTypes.BitBuffer): PubTypes.ClientRpcCall
    local rpcName = idToRpcMap[buffer:readUInt(16)]
    print(rpcName)
    local rpc = rpcs[rpcName]

    local args = {rpc.reader(buffer)}
    return {
        name = rpcName;
        args = args;
    }
end

return table.freeze {
    EVERYONE = EVERYONE;

    Client = ClientRpc;
    bindCallback = bindCallback;
    runCallback = runCallback;

    pauseCulling = pauseCulling;
    resumeCulling = resumeCulling;
    isCulling = isCulling;
    forceResumeCulling = forceResumeCulling;

    makeClientCall = makeClientCall;
    callServer = callServer;

    serialize = serialize;
    deserialize = deserialize;

    getRpcIdentifiersAsJson = getRpcIdentifiersAsJson;
    setRpcIdentifiersFromJson = setRpcIdentifiersFromJson;
}