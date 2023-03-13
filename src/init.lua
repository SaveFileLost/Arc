local PubTypes = require(script.PubTypes)

export type List<T> = PubTypes.List<T>
export type Map<K,V> = PubTypes.Map<K,V>
export type Set<T> = PubTypes.Set<T>

export type NetProperty = PubTypes.NetProperty

return require(
    if game:GetService("RunService"):IsServer() then script.ArcServer else script.ArcClient
) :: PubTypes.ArcServer & PubTypes.ArcCommon & PubTypes.ArcClient -- this sucks, but theres no way around it for now