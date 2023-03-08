local PubTypes = require(script.PubTypes)

return require(
    if game:GetService("RunService"):IsServer() then script.ArcServer else script.ArcClient
) :: PubTypes.ArcServer & PubTypes.ArcCommon & PubTypes.ArcClient -- this sucks, but theres no way around it for now