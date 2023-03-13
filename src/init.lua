local PubTypes = require(script.PubTypes)

local IS_SERVER = game:GetService("RunService"):IsServer()

export type List<T> = PubTypes.List<T>
export type Map<K,V> = PubTypes.Map<K,V>
export type Set<T> = PubTypes.Set<T>

export type NetProperty = PubTypes.NetProperty

local function server(): PubTypes.ArcServer
    assert(IS_SERVER, "ArcServer required clientside")
    return require(script.ArcServer) :: PubTypes.ArcServer
end

local function common(): PubTypes.ArcCommon
    return require(if game:GetService("RunService"):IsServer() then script.ArcServer else script.ArcClient)
end

local function client(): PubTypes.ArcClient
    assert(not IS_SERVER, "ArcClient required clientside")
    return require(script.ArcClient) :: PubTypes.ArcClient
end

return table.freeze {
    server = server;
    common = common;
    client = client;
}